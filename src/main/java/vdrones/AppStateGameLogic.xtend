package vdrones

import com.jme3.bullet.control.RigidBodyControl
import javax.inject.Inject
import javax.inject.Provider
import jme3_ext.AppState0
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.slf4j.LoggerFactory
import rx.Observable
import rx.Subscription
import rx.subjects.BehaviorSubject
import rx.subscriptions.Subscriptions
import rx_ext.ObserverPrint

class Channels {
	new() {
	}

	final package BehaviorSubject<InfoDrone> drones = BehaviorSubject.create()
	final package BehaviorSubject<InfoCube> cubes = BehaviorSubject.create()
	final package BehaviorSubject<InfoArea> areaInfo2s = BehaviorSubject.create()
	final package BehaviorSubject<CfgArea> areaCfgs = BehaviorSubject.create()

	def completed() {
		drones.onCompleted();
		cubes.onCompleted();
		areaInfo2s.onCompleted();
		areaCfgs.onCompleted();
	}
}

class AppStateGameLogic extends AppState0 {
	val log = LoggerFactory.getLogger(AppStateGameLogic)
	val BehaviorSubject<Float> dt = BehaviorSubject.create(0f)
	var Subscription subscription
	final package GenDrone droneGenerator
	final package GenCube cubeGenerator
	final package EntityFactory entityFactory
	final package Provider<ObserverDroneState> observerDroneStateProvider
	final package Provider<ObserverCubeState> observerCubeStateProvider
	final package GeometryAndPhysic geometryAndPhysic

	def package InfoDrone setup(Observable<Float> dt, InfoDrone drone) {
		log.info("setup InfoDrone")
		observerDroneStateProvider.get().bind(drone)
		dt.subscribe(drone.dt)
		drone.state.subscribe(new ObserverPrint("droneState"))
		drone.score.subscribe(new ObserverPrint("droneScore"))
		drone.scoreReq.subscribe(new ObserverPrint("droneScoreReq"))
		drone.collisions.map[v|v.other.getControl(RigidBodyControl).getCollisionGroup()].subscribe(
			new ObserverPrint("droneCollisions"))
		drone
	}

	def package InfoCube setup(Observable<Float> dt, InfoCube cube) {
		observerCubeStateProvider.get().bind(cube)
		dt.subscribe(cube.dt)
		cube.state.subscribe(new ObserverPrint("cubeState"))
		return cube
	}

	def package InfoArea newAreaInfo(CfgArea cfg, Observable<Float> dt) {
		/*FIXME Cannot add Annotation to Variable declaration. Java code: @^val */
		val InfoArea area = new InfoArea()
		area.cfg = cfg
//        area.clock = dt.scan(0f, [acc, dt0 | acc + dt0])
		area.clock = dt.scan(cfg.area.time, [acc, dt0|Math.max(0, acc - dt0)]).distinctUntilChanged()
		return area
	}

	def package Subscription pipeAll() {
		val channels = app.getStateManager().getState(AppStateRun).channels
		return Subscriptions.from(
			droneGenerator.drones.map[v|setup(dt, v)].subscribe(channels.drones),
			cubeGenerator.cubes.map[v|setup(dt, v)].subscribe(channels.cubes),
			channels.areaCfgs.map [v|newAreaInfo(v, dt)].subscribe(channels.areaInfo2s),
			channels.areaCfgs.map[v|v.spawnPoints.get(0)].subscribe(droneGenerator),
			channels.areaCfgs.map[v|v.cubeZones].subscribe(cubeGenerator), channels.areaCfgs.flatMap [v|
				Observable.from(v.scene)
			].subscribe[v|geometryAndPhysic.add(v)],
			// Pipes.pipeA(channels.areaCfgs, geometryAndPhysic, entityFactory),
			// Pipes.pipe(channels.areaCfgs, app.getStateManager().getState(AppStateLights.class))
			Pipes.pipe(channels.drones, app.getInputManager()), // channels.droneInfo2s.subscribe(v -> spawnDrone(v))
			channels.areaCfgs.subscribe(new ObserverPrint<CfgArea>("channels.areaCfgs")),
			channels.drones.subscribe(new ObserverPrint<InfoDrone>("channels.drones")),
			channels.cubes.subscribe(new ObserverPrint<InfoCube>("channels.cubes")))
	}

//    def package void spawnLevel(String name) {
//        channels.areaCfgs.onNext(entityFactory.newLevel("area00"))
//    }
	override protected void doInitialize() {
		/*
		 *         subscription = Subscriptions.from(channels.areaCfgs.map[v| newAreaInfo(v, dt)].subscribe(channels.areaInfo2s),
		 *             channels.areaCfgs.map[v| v.spawnPoints.get(0)].subscribe(droneGenerator),
		 *             channels.areaCfgs.map[v| v.cubeZones].subscribe(cubeGenerator),
		 *             droneGenerator.drones.map[v| setup(dt, v)].subscribe(channels.drones),
		 *             cubeGenerator.cubes.map[v| setup(dt, v)].subscribe(channels.cubes),
		 *             pipeAll()
		 *         )
		 *         app.enqueue[
		 *             spawnLevel("area0")
		 *             true
		 *         ]
		 */
		log.debug("doInitialize")
		geometryAndPhysic.removeAll()
		subscription = pipeAll()
	}

	override protected void doUpdate(float tpf) {
		dt.onNext(tpf)
	}

	override protected void doDispose() {
		if (subscription != null) {
			subscription.unsubscribe()
			subscription = null
		}
		geometryAndPhysic.removeAll()
	}

	@Inject
	@FinalFieldsConstructor
	new() {
	}
}
