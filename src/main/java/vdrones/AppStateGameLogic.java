package vdrones;

import javax.inject.Inject;
import javax.inject.Provider;
import javax.inject.Singleton;

import lombok.RequiredArgsConstructor;
import lombok.val;
import rx.Observable;
import rx.Subscription;
import rx.subjects.BehaviorSubject;
import rx.subscriptions.Subscriptions;
import rx_ext.ObserverPrint;

import com.jme3.bullet.control.RigidBodyControl;

@Singleton
@RequiredArgsConstructor(onConstructor=@__(@Inject))
class Channels{
	final BehaviorSubject<InfoDrone> drones = BehaviorSubject.create();
	final BehaviorSubject<InfoCube> cubes = BehaviorSubject.create();
	final BehaviorSubject<InfoArea> areaInfo2s = BehaviorSubject.create();
	final BehaviorSubject<CfgArea> areaCfgs = BehaviorSubject.create();
}

@RequiredArgsConstructor(onConstructor=@__(@Inject))
public class AppStateGameLogic extends AppState0 {
	BehaviorSubject<Float> dt = BehaviorSubject.create(0f);
	Subscription subscription;
	final Channels channels;
	final GenDrone droneGenerator;
	final GenCube cubeGenerator;
	final EntityFactory entityFactory;
	final Provider<ObserverDroneState> observerDroneStateProvider;
	final Provider<ObserverCubeState> observerCubeStateProvider;
	final GeometryAndPhysic geometryAndPhysic;


	InfoDrone setup(Observable<Float> dt, InfoDrone drone) {
		observerDroneStateProvider.get().bind(drone);
		dt.subscribe(drone.dt);
		drone.state.subscribe(new ObserverPrint<>("droneState"));
		drone.score.subscribe(new ObserverPrint<>("droneScore"));
		drone.scoreReq.subscribe(new ObserverPrint<>("droneScoreReq"));
		drone.collisions.map(v -> v.other.getControl(RigidBodyControl.class).getCollisionGroup()).subscribe(new ObserverPrint<>("droneCollisions"));
		return drone;
	}

	InfoCube setup(Observable<Float> dt, InfoCube cube) {
		observerCubeStateProvider.get().bind(cube);
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

	Subscription pipeAll(){
		return Subscriptions.from(
			Pipes.pipeA(channels.areaCfgs, geometryAndPhysic, entityFactory)
			//, Pipes.pipe(channels.areaCfgs, app.getStateManager().getState(AppStateLights.class))
			, Pipes.pipe(channels.drones, app.getInputManager())
			//, channels.droneInfo2s.subscribe(v -> spawnDrone(v))
			,channels.areaCfgs.subscribe(new ObserverPrint<CfgArea>("channels.areaCfgs"))
			,channels.drones.subscribe(new ObserverPrint<InfoDrone>("channels.drones"))
			,channels.cubes.subscribe(new ObserverPrint<InfoCube>("channels.cubes"))
		);
	}

	void spawnLevel(String name) {
		channels.areaCfgs.onNext(entityFactory.newLevel("area00"));
	}

	@Override
	protected void doInitialize() {
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

