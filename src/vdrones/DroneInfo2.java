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
import vdrones.DroneInfo2.State;

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

@RequiredArgsConstructor
class DroneInfo2 implements com.jme3.export.Savable { //HACK FQN of Savable to avoid a compilation error via gradle
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
	public static DroneInfo2 from(Spatial s) {
		return (DroneInfo2) s.getUserData(UD);
	}

	static Node makeNode(DroneInfo2 v) {
		Node n = new Node("drone");
		n.setUserData(UD, v);
		return n;
	}

	//- INSTANCE --------------------------------------------------------------------------
	final DroneCfg cfg;
	final Node node = makeNode(this);
	private final BehaviorSubject<State> stateReq = BehaviorSubject.create(State.hidden);
	final BehaviorSubject<Float> forwardReq = BehaviorSubject.create(0f);
	final BehaviorSubject<Float> turnReq = BehaviorSubject.create(0f);
	final BehaviorSubject<Float> shieldReq = BehaviorSubject.create(0f);
	final BehaviorSubject<Float> healthReq = BehaviorSubject.create(0f);
	final BehaviorSubject<DroneCollisionEvent> wallCollisions = BehaviorSubject.create();
	final BehaviorSubject<Float> energyRegen = BehaviorSubject.create(0f);
	//BehaviorSubject<Vector3f> position = BehaviorSubject.create(new Vector3f());
	//HACK delay to async state change (eg: post-pone update after all subscriber receive previous value)
	Observable<State> state = stateReq.distinctUntilChanged().delay(1,TimeUnit.MILLISECONDS);
	Observable<Float> health;
	Observable<Float> energy;
	Observable<Float> forward;
	Observable<Float> turn;
	Observable<Float> shield;
	Location spawnLoc;

	void go(State v) {
		//Schedulers.trampoline().createWorker().schedule(() -> stateReq.onNext(v));
		stateReq.onNext(v);
	}

	@Override
	public void write(JmeExporter ex) throws IOException {
	}
	@Override
	public void read(JmeImporter im) throws IOException {
	}
}

class DroneCfg {
	public float turn = 2.0f;
	public float forward = 150f;
	public float linearDamping = 0.5f;
	public float energyRegenSpeed = 2;
	public float energyForwardSpeed = 4;
	public float energyShieldSpeed = 2;
	public float energyStoreInit = 50f;
	public float energyStoreMax = 100f;
	public float healthMax = 100f;
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


class DroneGenerator extends Subscriber<Location> {
	private final PublishSubject<Observable<DroneInfo2>> drones0 = PublishSubject.create();
	Observable<Observable<DroneInfo2>> drones = drones0;

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
		DroneInfo2 drone = new DroneInfo2(new DroneCfg());
		drone.spawnLoc = t;
		drones0.onNext(BehaviorSubject.create(drone));
	}
}

@RequiredArgsConstructor(onConstructor=@__(@Inject))
@Slf4j
class ObserverDroneState implements Observer<DroneInfo2.State> {
	private Action1<State> onExit;
	private DroneInfo2 drone;
	private SubscriptionsMap subs = new SubscriptionsMap();
	private AnimEventListener animListener;
	final EntityFactory efactory;
	final SimpleApplication jme;
	final GeometryAndPhysic gp;
	final Animator animator;
	final AppStateCamera ascam;

	public void bind(DroneInfo2 v) {
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
					drone.go(DroneInfo2.State.driving);
					break;
				case "crashing":
					drone.go(DroneInfo2.State.hidden);
					break;
				case "exiting":
					drone.go(DroneInfo2.State.hidden);
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
			drone.go(DroneInfo2.State.generating);
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

	static Subscription pipe(DroneInfo2 drone, ControlDronePhy phy) {
		return Subscriptions.from(
				drone.forward.subscribe((v) -> {
					phy.forwardLg = v * drone.cfg.forward;
					phy.linearDamping = drone.cfg.linearDamping;
				})
				, drone.turn.subscribe((v) -> phy.turnLg = v * drone.cfg.turn)
				);
	}

}
