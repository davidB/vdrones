package vdrones;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.concurrent.TimeUnit;

import lombok.EqualsAndHashCode;
import lombok.RequiredArgsConstructor;
import lombok.val;
import lombok.extern.slf4j.Slf4j;
import rx.Observable;
import rx.Observer;
import rx.Subscriber;
import rx.Subscription;
import rx.functions.Action0;
import rx.functions.Action1;
import rx.schedulers.Schedulers;
import rx.subjects.BehaviorSubject;
import rx.subjects.PublishSubject;
import rx.subscriptions.Subscriptions;
import rx_ext.ObserverPrint;
import rx_ext.SubscriptionsMap;
import vdrones.DroneInfo2.State;

import com.google.inject.Inject;
import com.google.inject.Injector;
import com.google.inject.Singleton;
import com.jme3.app.Application;
import com.jme3.app.SimpleApplication;
import com.jme3.app.state.AppStateManager;
import com.jme3.export.JmeExporter;
import com.jme3.export.JmeImporter;
import com.jme3.export.Savable;
import com.jme3.input.InputManager;
import com.jme3.light.Light;
import com.jme3.math.Quaternion;
import com.jme3.math.Rectangle;
import com.jme3.math.Vector3f;
import com.jme3.scene.Node;
import com.jme3.scene.Spatial;

@Singleton
class Channels{
	final BehaviorSubject<DroneInfo2> drones = BehaviorSubject.create();
	final BehaviorSubject<AreaInfo2> areaInfo2s = BehaviorSubject.create();
	final BehaviorSubject<AreaCfg> areaCfgs = BehaviorSubject.create();
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

class DroneGen {
	enum Kind {
		first,
		restore,
	}
	Location loc;
	Kind kind;
}

@RequiredArgsConstructor
class DroneInfo2 implements Savable {
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
	Observable<State> state = stateReq.delay(1,TimeUnit.MILLISECONDS);
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

@RequiredArgsConstructor
class Cube {
	final Vector3f position;
	final int zone;
	final int subzone;
}

@Singleton
class AreaInfo2 {
	AreaCfg cfg;
	Observable<Float> clock;
}


class AreaCfg {
	String name;
	float timeout;

	final List<Light> lights = new ArrayList<>();
	final List<Spatial> bg = new ArrayList<>();
	final List<List<Rectangle>> cubeZones = new ArrayList<>();
	final List<Location> spawnPoints = new ArrayList<>();
}

class Location {
	final Vector3f position = new Vector3f();
	final Quaternion orientation = new Quaternion(Quaternion.IDENTITY);
}

class CubeGenerator extends Subscriber<List<List<Rectangle>>> {
	private final PublishSubject<Observable<Cube>> cubes0 = PublishSubject.create();
	Observable<Observable<Cube>> cubes = cubes0;
	private Subscription subscription;

	private List<List<Rectangle>> cubeZones;

	void generateNext(Cube c) {
		generateIn(c.zone, c.subzone + 1 % cubeZones.get(c.zone).size());
	}

	void generateIn(int zone, int subzone) {
		Rectangle zoneR = cubeZones.get(zone).get(subzone);
		//nextZone = (nextZone + 1) % cubeZones.get(zone).size();
		Cube c = new Cube(zoneR.random(), zone, subzone);
		cubes0.onNext(BehaviorSubject.create(c));
	}

	void stop() {
		if (subscription != null && !subscription.isUnsubscribed()) {
			subscription.unsubscribe();
		}
		subscription = null;
	}

	@Override
	public void onCompleted() {
		cubes0.onCompleted();
		stop();
	}

	@Override
	public void onError(Throwable e) {
		cubes0.onError(e);
		stop();
	}

	@Override
	public void onNext(List<List<Rectangle>> t) {
		stop();
		cubeZones = t;
		if (cubeZones.size() > 0) {
			subscription = cubes.flatMap(v -> v).last().subscribe(this::generateNext);
			for(int i = cubeZones.size() - 1; i > -1; i--) {
				generateIn(i, 0);
			}
		}
	}
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
		drone.go(DroneInfo2.State.generating);
	}
}



public class AppStateGameLogic extends AppState0 {
	BehaviorSubject<Float> dt = BehaviorSubject.create(0f);
	Subscription subscription;
	public static float wallCollisionHealthSpeed = -100.0f / 5.0f; //-100 points in 5 seconds,

	DroneInfo2 setup(Observable<Float> dt, DroneInfo2 drone) {
		DroneCfg cfg = drone.cfg;
		injector.getInstance(ObserverDroneState.class).bind(drone);

		BehaviorSubject<Float> energyVelocity = BehaviorSubject.create(0f);
		Observable<Float> energydt = dt.flatMap((dt0) -> energyVelocity.firstOrDefault(0f).map((v) -> dt0 * v));
		drone.energy = energydt.scan(cfg.energyStoreInit, (acc, d) -> Math.max(0, Math.min(cfg.energyStoreMax, acc + d)));
		drone.forward = Observable.combineLatest(drone.energy, drone.forwardReq, (o1, o2) -> (o1 > cfg.energyForwardSpeed) ? o2 : 0f).distinctUntilChanged();
		drone.turn = drone.turnReq.distinctUntilChanged();
		drone.health = drone.healthReq.scan(cfg.healthMax, (acc, d) -> Math.max(0, Math.min(cfg.healthMax, acc + d))).distinctUntilChanged();
		drone.shield = Observable.combineLatest(drone.energy, drone.shieldReq, (o1, o2) -> (o1 > cfg.energyShieldSpeed) ? o2 : 0f).distinctUntilChanged();
		Observable.combineLatest(drone.energyRegen, drone.forward, drone.shield, (o0, o1, o2) -> (o0 - Math.abs(o1 * cfg.energyForwardSpeed) /*- Math.abs(o2 * energyShieldSpeed)*/)).subscribe(energyVelocity);
		//TODO use a throttleFirst based on game time vs real time
		drone.wallCollisions.throttleFirst(250, java.util.concurrent.TimeUnit.MILLISECONDS).subscribe(v -> drone.healthReq.onNext(wallCollisionHealthSpeed * 0.25f));
		drone.health.filter(v -> v <= 0).subscribe((v) -> drone.go(DroneInfo2.State.crashing));
		energyVelocity.subscribe(new ObserverPrint<Float>("energyVelocity"));
		drone.state.subscribe(new ObserverPrint<DroneInfo2.State>("droneState"));


		return drone;
	}

	//
//	public Spatial spawnDrone(DroneInfo2 d) {
//		Injector injector = Injectors.find(this);
//		EntityFactory efactory = injector.getInstance(EntityFactory.class);
//		Spatial vd = efactory.newDrone();
//		Pipes.pipe(d, vd.getControl(ControlDronePhy.class));
//		stateManager.getState(AppStateCamera.class).setCameraFollower(new CameraFollower(CameraFollower.Mode.TPS, vd));
//		stateManager.getState(AppStateGeoPhy.class).toAdd.offer(vd);
//		return vd;
//	}

	AreaInfo2 newAreaInfo(AreaCfg cfg, Observable<Float> dt) {
		val area = new AreaInfo2();
		area.cfg = cfg;
		area.clock = dt.scan(0f, (acc, dt0) -> acc + dt0);
		return area;
	}

	static public Subscription pipeAll(){
		Injector injector = Injectors.find();
		//LevelLoader ll = injector.getInstance(LevelLoader.class);
		Channels channels = injector.getInstance(Channels.class);

		return Subscriptions.from(
			Pipes.pipeA(channels.areaCfgs, injector.getInstance(GeometryAndPhysic.class), injector.getInstance(EntityFactory.class))
			, Pipes.pipe(channels.areaCfgs, injector.getInstance(AppStateManager.class).getState(AppStateLights.class))
			, Pipes.pipe(channels.drones, injector.getInstance(InputManager.class))
			//, channels.droneInfo2s.subscribe(v -> spawnDrone(v))
			,channels.areaCfgs.subscribe(new ObserverPrint<AreaCfg>("channels.areaCfgs"))
			,channels.drones.subscribe(new ObserverPrint<DroneInfo2>("channels.drones"))
		);
	}

	static public void spawnLevel(String name) {
		Injector injector = Injectors.find();
		EntityFactory efactory = injector.getInstance(EntityFactory.class);
		Channels channels = injector.getInstance(Channels.class);
		channels.areaCfgs.onNext(efactory.newLevel("area0"));
	}

	@Override
	protected void doInitialize() {
		Channels channels = injector.getInstance(Channels.class);
		DroneGenerator droneGenerator = injector.getInstance(DroneGenerator.class);

		subscription =  Subscriptions.from(
			channels.areaCfgs.map(v -> newAreaInfo(v, dt)).subscribe(channels.areaInfo2s)
			, Pipes.pipe(channels.areaCfgs, droneGenerator)
			, droneGenerator.drones.flatMap(v -> v).map(v -> setup(dt, v)).subscribe(channels.drones)
			,pipeAll()
		);

		app.enqueue(() -> {
			spawnLevel("area0");
			return true;
		});
	}

	@Override
	protected void doUpdate(float tpf) {
		dt.onNext(tpf);
	}

	protected void doDispose() {
		subscription.unsubscribe();
	}
}

@RequiredArgsConstructor(onConstructor=@__(@Inject))
@Slf4j
class ObserverDroneState implements Observer<DroneInfo2.State> {
	private Action1<State> onExit;
	private DroneInfo2 drone;
	private boolean generatedOnce = false;
	private SubscriptionsMap subs = new SubscriptionsMap();

	final EntityFactory efactory;
	final SimpleApplication jme;
	final GeometryAndPhysic gp;
	final AppStateCamera ascam;

	public void bind(DroneInfo2 v) {
		if (drone != null && drone != v) {
			throw new IllegalStateException("already binded");
		}
		drone = v;
		subs.add("0", drone.state.subscribe(this));
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
				efactory.unasDrone(drone.node);
				gp.remove(drone.node);
				return true;
			});
			if (generatedOnce) {
				drone.go(DroneInfo2.State.generating);
			}
			break;
		case generating : {
			generatedOnce = true;
			drone.energyRegen.onNext(drone.cfg.energyRegenSpeed * 4);
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
				return true;
			});
			onExit = (n) -> {
				log.info("Exit from {} to {}", v, n);
				drone.energyRegen.onNext(0f);
			};
			//TODO switch on end of animation
			Schedulers.computation().createWorker().schedule((() ->drone.go(DroneInfo2.State.driving)), 1, TimeUnit.SECONDS);
			break;
		}
		case driving :
			drone.energyRegen.onNext(drone.cfg.energyRegenSpeed);
			//TODO remove physics
			onExit = (n) -> {
				log.info("Exit from {} to {}", v, n);
				drone.energyRegen.onNext(0f);
				drone.forwardReq.onNext(0f);
				drone.turnReq.onNext(0f);
				jme.enqueue(() -> {
					subs.unsubscribe("ControlDronePhy");
					drone.node.removeControl(ControlDronePhy.class);
					log.info("jme unsubscribe, remove ControlDronePhy");
					return true;
				});
			};
			break;
		case crashing :
			drone.go(DroneInfo2.State.hidden);
			break;
		case exiting :
			drone.go(DroneInfo2.State.hidden);
			break;
		case disconnecting:
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
