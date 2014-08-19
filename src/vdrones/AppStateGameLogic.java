package vdrones;

import lombok.val;
import rx.Observable;
import rx.Subscription;
import rx.subjects.BehaviorSubject;
import rx.subscriptions.Subscriptions;
import rx_ext.ObserverPrint;

import com.google.inject.Injector;
import com.google.inject.Singleton;
import com.jme3.app.state.AppStateManager;
import com.jme3.bullet.control.RigidBodyControl;
import com.jme3.input.InputManager;

@Singleton
class Channels{
	final BehaviorSubject<InfoDrone> drones = BehaviorSubject.create();
	final BehaviorSubject<InfoCube> cubes = BehaviorSubject.create();
	final BehaviorSubject<InfoArea> areaInfo2s = BehaviorSubject.create();
	final BehaviorSubject<CfgArea> areaCfgs = BehaviorSubject.create();
}

public class AppStateGameLogic extends AppState0 {
	BehaviorSubject<Float> dt = BehaviorSubject.create(0f);
	Subscription subscription;

	InfoDrone setup(Observable<Float> dt, InfoDrone drone) {
		injector.getInstance(ObserverDroneState.class).bind(drone);
		dt.subscribe(drone.dt);
		drone.state.subscribe(new ObserverPrint<>("droneState"));
		drone.score.subscribe(new ObserverPrint<>("droneScore"));
		drone.scoreReq.subscribe(new ObserverPrint<>("droneScoreReq"));
		drone.collisions.map(v -> v.other.getControl(RigidBodyControl.class).getCollisionGroup()).subscribe(new ObserverPrint<>("droneCollisions"));
		return drone;
	}

	InfoCube setup(Observable<Float> dt, InfoCube cube) {
		injector.getInstance(ObserverCubeState.class).bind(cube);
		dt.subscribe(cube.dt);
		cube.state.subscribe(new ObserverPrint<>("cubeState"));
		return cube;
	}

	InfoArea newAreaInfo(CfgArea cfg, Observable<Float> dt) {
		val area = new InfoArea();
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
				,channels.areaCfgs.subscribe(new ObserverPrint<CfgArea>("channels.areaCfgs"))
				,channels.drones.subscribe(new ObserverPrint<InfoDrone>("channels.drones"))
				,channels.cubes.subscribe(new ObserverPrint<InfoCube>("channels.cubes"))
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
		GenDrone droneGenerator = injector.getInstance(GenDrone.class);
		GenCube cubeGenerator = injector.getInstance(GenCube.class);

		subscription =  Subscriptions.from(
				channels.areaCfgs.map(v -> newAreaInfo(v, dt)).subscribe(channels.areaInfo2s)
				, channels.areaCfgs.map(v -> v.spawnPoints.get(0)).subscribe(droneGenerator)
				, channels.areaCfgs.map(v -> v.cubeZones).subscribe(cubeGenerator)
				, droneGenerator.drones.map(v -> setup(dt, v)).subscribe(channels.drones)
				, cubeGenerator.cubes.map(v -> setup(dt, v)).subscribe(channels.cubes)
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

