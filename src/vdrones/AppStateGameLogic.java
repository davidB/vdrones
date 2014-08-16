package vdrones;

import java.util.ArrayList;
import java.util.List;

import lombok.val;
import rx.Observable;
import rx.Subscription;
import rx.subjects.BehaviorSubject;
import rx.subscriptions.Subscriptions;
import rx_ext.ObserverPrint;

import com.google.inject.Injector;
import com.google.inject.Singleton;
import com.jme3.app.state.AppStateManager;
import com.jme3.bounding.BoundingBox;
import com.jme3.input.InputManager;
import com.jme3.light.Light;
import com.jme3.scene.Spatial;

@Singleton
class Channels{
	final BehaviorSubject<DroneInfo2> drones = BehaviorSubject.create();
	final BehaviorSubject<Cube> cubes = BehaviorSubject.create();
	final BehaviorSubject<AreaInfo2> areaInfo2s = BehaviorSubject.create();
	final BehaviorSubject<AreaCfg> areaCfgs = BehaviorSubject.create();
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
	final List<List<BoundingBox>> cubeZones = new ArrayList<>();
	final List<Location> spawnPoints = new ArrayList<>();
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

	Cube setup(Observable<Float> dt, Cube cube) {
		injector.getInstance(ObserverCubeState.class).bind(cube);
		cube.state.subscribe(new ObserverPrint<Cube.State>("cubeState"));
		return cube;
	}

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
				,channels.cubes.subscribe(new ObserverPrint<Cube>("channels.cubes"))
				);
	}

	static public void spawnLevel(String name) {
		Injector injector = Injectors.find();
		EntityFactory efactory = injector.getInstance(EntityFactory.class);
		Channels channels = injector.getInstance(Channels.class);
		channels.areaCfgs.onNext(efactory.newLevel("area00"));
	}

	@Override
	protected void doInitialize() {
		Channels channels = injector.getInstance(Channels.class);
		DroneGenerator droneGenerator = injector.getInstance(DroneGenerator.class);
		CubeGenerator cubeGenerator = injector.getInstance(CubeGenerator.class);

		subscription =  Subscriptions.from(
				channels.areaCfgs.map(v -> newAreaInfo(v, dt)).subscribe(channels.areaInfo2s)
				, channels.areaCfgs.map(v -> v.spawnPoints.get(0)).subscribe(droneGenerator)
				, channels.areaCfgs.map(v -> v.cubeZones).subscribe(cubeGenerator)
				, droneGenerator.drones.flatMap(v -> v).map(v -> setup(dt, v)).subscribe(channels.drones)
				, cubeGenerator.cubes.flatMap(v -> v).map(v -> setup(dt, v)).subscribe(channels.cubes)
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

