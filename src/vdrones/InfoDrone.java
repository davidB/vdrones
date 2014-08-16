package vdrones;

import java.io.IOException;
import java.util.concurrent.TimeUnit;

import lombok.EqualsAndHashCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import rx.Observable;
import rx.Observer;
import rx.Subscriber;
import rx.Subscription;
import rx.functions.Action1;
import rx.subjects.BehaviorSubject;
import rx.subjects.PublishSubject;
import rx.subscriptions.Subscriptions;
import rx_ext.SubscriptionsMap;
import vdrones.InfoDrone.State;

import com.google.inject.Inject;
import com.jme3.animation.AnimChannel;
import com.jme3.animation.AnimControl;
import com.jme3.animation.AnimEventListener;
import com.jme3.app.SimpleApplication;
import com.jme3.export.JmeExporter;
import com.jme3.export.JmeImporter;
import com.jme3.math.Quaternion;
import com.jme3.math.Vector3f;
import com.jme3.scene.Node;
import com.jme3.scene.Spatial;

class InfoDrone implements com.jme3.export.Savable { //HACK FQN of Savable to avoid a compilation error via gradle
	//- CLASS -----------------------------------------------------------------------------
	public static enum State {
		hidden
		, generating
		, driving
		, crashing
		, disconnecting
		, exiting
	}

	public static final String UD = "DroneInfoUserData";
	public static InfoDrone from(Spatial s) {
		return (InfoDrone) s.getUserData(UD);
	}

	static Node makeNode(InfoDrone v) {
		Node n = new Node("drone");
		n.setUserData(UD, v);
		return n;
	}

	//- INSTANCE --------------------------------------------------------------------------
	final CfgDrone cfg;
	final Node node = makeNode(this);
	final BehaviorSubject<Float> dt = BehaviorSubject.create(0f);
	final BehaviorSubject<State> stateReq = BehaviorSubject.create(State.hidden);
	final Observable<State> state = stateReq.distinctUntilChanged().delay(1,TimeUnit.MILLISECONDS);
	final BehaviorSubject<Float> forwardReq = BehaviorSubject.create(0f);
	final Observable<Float> forward;
	final BehaviorSubject<Float> turnReq = BehaviorSubject.create(0f);
	final Observable<Float> turn;
	final BehaviorSubject<Float> shieldReq = BehaviorSubject.create(0f);
	final Observable<Float> shield;
	final BehaviorSubject<Float> healthReq = BehaviorSubject.create(0f);
	final Observable<Float> health;
	final BehaviorSubject<DroneCollisionEvent> wallCollisions = BehaviorSubject.create();
	final BehaviorSubject<Float> energyRegen = BehaviorSubject.create(0f);
	final Observable<Float> energy;
	//BehaviorSubject<Vector3f> position = BehaviorSubject.create(new Vector3f());
	//HACK delay to async state change (eg: post-pone update after all subscriber receive previous value)
	Location spawnLoc;

	public InfoDrone(CfgDrone cfg) {
		this.cfg = cfg;

		BehaviorSubject<Float> energyVelocity = BehaviorSubject.create(0f);
		Observable<Float> energydt = this.dt.flatMap((dt0) -> energyVelocity.firstOrDefault(0f).map((v) -> dt0 * v));
		this.energy = energydt.scan(cfg.energyStoreInit, (acc, d) -> Math.max(0, Math.min(cfg.energyStoreMax, acc + d)));
		this.forward = Observable.combineLatest(this.energy, this.forwardReq, (o1, o2) -> (o1 > cfg.energyForwardSpeed) ? o2 : 0f).distinctUntilChanged();
		this.turn = this.turnReq.distinctUntilChanged();
		this.health = this.healthReq.scan(cfg.healthMax, (acc, d) -> Math.max(0, Math.min(cfg.healthMax, acc + d))).distinctUntilChanged();
		this.shield = Observable.combineLatest(this.energy, this.shieldReq, (o1, o2) -> (o1 > cfg.energyShieldSpeed) ? o2 : 0f).distinctUntilChanged();
		Observable.combineLatest(this.energyRegen, this.forward, this.shield, (o0, o1, o2) -> (o0 - Math.abs(o1 * cfg.energyForwardSpeed) /*- Math.abs(o2 * energyShieldSpeed)*/)).subscribe(energyVelocity);
		//TODO use a throttleFirst based on game time vs real time
		this.wallCollisions.throttleFirst(250, java.util.concurrent.TimeUnit.MILLISECONDS).subscribe(v -> this.healthReq.onNext(cfg.wallCollisionHealthSpeed * 0.25f));
		this.health.filter(v -> v <= 0).subscribe((v) -> this.stateReq.onNext(InfoDrone.State.crashing));
	}

	@Override
	public void write(JmeExporter ex) throws IOException {
	}
	@Override
	public void read(JmeImporter im) throws IOException {
	}
}

class CfgDrone {
	public float turn = 2.0f;
	public float forward = 150f;
	public float linearDamping = 0.5f;
	public float energyRegenSpeed = 2;
	public float energyForwardSpeed = 4;
	public float energyShieldSpeed = 2;
	public float energyStoreInit = 50f;
	public float energyStoreMax = 100f;
	public float healthMax = 100f;
	public float wallCollisionHealthSpeed = -100.0f / 5.0f; //-100 points in 5 seconds,
}

@RequiredArgsConstructor
@EqualsAndHashCode
class DroneCollisionEvent {
	final Vector3f position;
	final float lifetime;

	DroneCollisionEvent lifetime(float v) {
		return new DroneCollisionEvent(position, v);
	}
}

class Location {
	final Vector3f position = new Vector3f();
	final Quaternion orientation = new Quaternion(Quaternion.IDENTITY);
}


class GenDrone extends Subscriber<Location> {
	private final PublishSubject<Observable<InfoDrone>> drones0 = PublishSubject.create();
	Observable<Observable<InfoDrone>> drones = drones0;

	@Override
	public void onCompleted() {
		drones0.onCompleted();
	}

	@Override
	public void onError(Throwable e) {
		drones0.onError(e);
	}

	@Override
	public void onNext(Location t) {
		InfoDrone drone = new InfoDrone(new CfgDrone());
		drone.spawnLoc = t;
		drones0.onNext(BehaviorSubject.create(drone));
	}
}

@RequiredArgsConstructor(onConstructor=@__(@Inject))
@Slf4j
class ObserverDroneState implements Observer<InfoDrone.State> {
	private Action1<State> onExit;
	private InfoDrone drone;
	private SubscriptionsMap subs = new SubscriptionsMap();
	private AnimEventListener animListener;
	final EntityFactory efactory;
	final SimpleApplication jme;
	final GeometryAndPhysic gp;
	final Animator animator;
	final AppStateCamera ascam;

	public void bind(InfoDrone v) {
		if (drone != null && drone != v) {
			throw new IllegalStateException("already binded");
		}
		drone = v;
		subs.add("0", drone.state.subscribe(this));
		animListener = new AnimEventListener(){
			@Override
			public void onAnimCycleDone(AnimControl control, AnimChannel channel, String animName) {
				log.info("onAnimCycleDone : {} {}", animName, channel.getTime());
				assert(channel.getTime() >= control.getAnimationLength(animName));
				switch(animName) {
				case "generation":
					drone.stateReq.onNext(InfoDrone.State.driving);
					break;
				case "crashing":
					drone.stateReq.onNext(InfoDrone.State.hidden);
					break;
				case "exiting":
					drone.stateReq.onNext(InfoDrone.State.hidden);
					break;
				}
			}

			@Override
			public void onAnimChange(AnimControl control, AnimChannel channel, String animName) {
			}
		};
	}

	private void dispose() {
		log.debug("dispose {}", drone);
		drone = null;
		subs.unsubscribeAll();
	}

	@Override
	public void onCompleted() {
		log.debug("onCompleted {}", drone);
		dispose();
	}

	@Override
	public void onError(Throwable e) {
		log.warn("onError", e);
		dispose();
	}

	@Override
	public void onNext(State v) {
		if (onExit != null) {
			try {
				onExit.call(v);
			} catch (Exception e) {
				log.warn("onExit", e);
			}
			onExit = null;
		}
		log.info("Enter in {}", v);
		switch(v) {
		case hidden :
			jme.enqueue(() -> {
				efactory.unas(drone.node);
				gp.remove(drone.node);
				return true;
			});
			drone.stateReq.onNext(InfoDrone.State.generating);
			break;
		case generating : {
			drone.energyRegen.onNext(drone.cfg.energyStoreMax /*energyRegenSpeed * 4*/);
			drone.healthReq.onNext(drone.cfg.healthMax);
			jme.enqueue(() -> {
				drone.node.setLocalRotation(drone.spawnLoc.orientation);
				drone.node.setLocalTranslation(drone.spawnLoc.position);
				efactory.asDrone(drone.node);
				drone.node.addControl(new ControlDronePhy());
				subs.add("ControlDronePhy", pipe(drone, drone.node.getControl(ControlDronePhy.class)));
				gp.add(drone.node);
				ascam.setCameraFollower(new CameraFollower(CameraFollower.Mode.TPS, drone.node));
				//TODO start animation
				AnimControl ac = Spatials.findAnimControl(drone.node);
				ac.addListener(animListener);
				animator.play(drone.node, "generation");
				return true;
			});
			onExit = (n) -> {
				log.info("Exit from {} to {}", v, n);
				drone.energyRegen.onNext(drone.cfg.energyRegenSpeed);
			};
			//TODO switch on end of animation
			//Schedulers.computation().createWorker().schedule((() ->drone.go(DroneInfo2.State.driving)), 1, TimeUnit.SECONDS);
			break;
		}
		case driving :
			onExit = (n) -> {
				log.info("Exit from {} to {}", v, n);
				drone.energyRegen.onNext(0f);
				drone.forwardReq.onNext(0f);
				drone.turnReq.onNext(0f);
				jme.enqueue(() -> {
					subs.unsubscribe("ControlDronePhy");
					drone.node.removeControl(ControlDronePhy.class);
					return true;
				});
			};
			break;
		case crashing :
			jme.enqueue(() -> {
				animator.play(drone.node, "crashing");
				return true;
			});
			break;
		case exiting :
			jme.enqueue(() -> {
				animator.play(drone.node, "exiting");
				return true;
			});
			break;
		case disconnecting:
			jme.enqueue(() -> {
				animator.play(drone.node, "disconnecting");
				return true;
			});
			break;
		}
	}

	static Subscription pipe(InfoDrone drone, ControlDronePhy phy) {
		return Subscriptions.from(
				drone.forward.subscribe((v) -> {
					phy.forwardLg = v * drone.cfg.forward;
					phy.linearDamping = drone.cfg.linearDamping;
				})
				, drone.turn.subscribe((v) -> phy.turnLg = v * drone.cfg.turn)
				);
	}

}
