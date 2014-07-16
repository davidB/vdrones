package vdrones;

import lombok.RequiredArgsConstructor;
import rx.Observable;
import rx.Observer;
import rx.Subscriber;
import rx.Subscription;
import rx.subjects.BehaviorSubject;
import rx.subscriptions.Subscriptions;

import com.google.inject.Injector;
import com.jme3.app.Application;
import com.jme3.input.InputManager;
import com.jme3.input.KeyInput;
import com.jme3.input.controls.KeyTrigger;
import com.jme3.scene.Spatial;
import com.jme3x.jfx.FXMLHud;

import fxml.InGame;

public class Pipes {

	public static Subscription pipeA(Observable<AreaCfg> l, AppStateGeoPhy gp, Injector injector) {
		EntityFactory efactory = injector.getInstance(EntityFactory.class);
		Observable<Spatial> bg = l.flatMap(v -> Observable.from(v.bg));
		Observable<Spatial> spawners = l.flatMap(v-> Observable.from(v.spawnPoints)).map(v -> efactory.newSpawner(v));
		//TODO manage remove of spatial
		return Subscriptions.from(
			bg.subscribe((v) -> gp.toAdd.offer(v))
			, spawners.subscribe((v) -> gp.toAdd.offer(v))
			//, l.removeSpatial.subscribe((v) -> gp.toRemove.offer(v))
		);
	}

	public static Subscription pipe(Observable<AreaCfg> l, AppStateLights lights) {
		// TODO manage remove of light
		return Subscriptions.from(
				l.flatMap(v -> Observable.from(v.lights)).subscribe((v) -> lights.addLight(v))
			//, l.removeLight.subscribe((v) -> lights.removeLight(v))
		);
	}

	static Subscription pipe(Observable<DroneInfo2> drone, InputManager inputManager) {
		inputManager.addMapping(DroneInput.LEFT, new KeyTrigger(KeyInput.KEY_H));
		inputManager.addMapping(DroneInput.RIGHT, new KeyTrigger(KeyInput.KEY_K));
		inputManager.addMapping(DroneInput.FORWARD, new KeyTrigger(KeyInput.KEY_U));
		inputManager.addMapping(DroneInput.BACKWARD, new KeyTrigger(KeyInput.KEY_J));
		inputManager.addMapping(DroneInput.TOGGLE_CAMERA, new KeyTrigger(KeyInput.KEY_M));
		//inputManager.addMapping(RESET, new KeyTrigger(KeyInput.KEY_RETURN));

		//FIXME use a temporary variable m to avoid type inference issue.
		Observable<T2<DroneInput, Boolean>> m = drone.flatMap((v) -> {
			DroneInput ctrl = new DroneInput(v);
			return v.drivable.map(v0 -> new T2<DroneInput, Boolean>(ctrl, v0));
		});
		return m.subscribe((T2<DroneInput, Boolean> v) -> {
			if (v._2) {
				inputManager.addListener(v._1, DroneInput.LEFT, DroneInput.RIGHT, DroneInput.FORWARD, DroneInput.BACKWARD, DroneInput.TOGGLE_CAMERA);
			} else {
				inputManager.removeListener(v._1);
			}
		});
	}

	static Subscription pipe(DroneInfo2 drone, ControlDronePhy phy, Application app) {
		return drone.drivable.subscribe(new SubscriberL2<Boolean>() {
			Subscription onNext2(Boolean b) {
				return (!b)? null :
					Subscriptions.from(
						drone.forward.subscribe((v) -> {
							//app.enqueue(() -> {
							System.out.println(phy + " foward change : " + v);
							phy.forwardLg = v * drone.cfg.forward;
							phy.linearDamping = drone.cfg.linearDamping;
							System.out.println("forwardLg : " + phy.forwardLg);
							//return null;
							//});
						})
						, drone.turn.subscribe((v) -> phy.turnLg = v * drone.cfg.turn)
					);
			}
		});
	}

	public static Subscription pipe(Observable<AreaCfg> l, DroneGenerator dg) {
		return l.map(v -> v.spawnPoints.get(0)).subscribe(dg);
	}

	public static Subscription pipeD(Observable<DroneInfo2> drones,	AppStateGeoPhy gp, Injector injector) {
		EntityFactory efactory = injector.getInstance(EntityFactory.class);
		BehaviorSubject<T2<Spatial, DroneInfo2>> spawn = BehaviorSubject.create();
		drones.map(v -> {
			System.out.println("bind " + v);
			Spatial d = efactory.newDrone();
			d.setUserData(DroneInfo2.UD, v);
			//d.addControl(new ControlDronePhy());
			return new T2<Spatial, DroneInfo2>(d, v) ;
		}).subscribe(spawn);
		//TODO manage remove of spatial
		Application app = injector.getInstance(Application.class);
		return Subscriptions.from(
				spawn.subscribe((v) -> gp.toAdd.offer(v._1))
				,spawn.subscribe(new SubscriberL2<T2<Spatial, DroneInfo2>>() {
					@Override
					Subscription onNext2(T2<Spatial, DroneInfo2> v) {
						return Pipes.pipe(v._2, v._1.getControl(ControlDronePhy.class), app);
					}

				})
				,spawn.subscribe(v -> app.getStateManager().getState(AppStateCamera.class).setCameraFollower(new CameraFollower(CameraFollower.Mode.TPS, v._1)))
			//, l.removeSpatial.subscribe((v) -> gp.toRemove.offer(v))
		);
	}
}

@RequiredArgsConstructor
class T2<A1,A2> {
	final public A1 _1;
	final public A2 _2;
}

abstract class SubscriberL2<T> extends Subscriber<T> {
	Subscription subscription = null;

	void terminate() {
		if (subscription != null) subscription.unsubscribe();
	}
	@Override
	public void onCompleted() {
		terminate();
	}

	@Override
	public void onError(Throwable e) {
		terminate();
	}

	@Override
	public void onNext(T v) {
		terminate();
		subscription = onNext2(v);
	}

	abstract Subscription onNext2(T v);
}

@RequiredArgsConstructor
class ObserverPrint<T> implements Observer<T> {
	 private final String name;

	@Override
	public void onCompleted() {
		System.out.printf("%s completed\n", name);
	}

	@Override
	public void onError(Throwable e) {
		System.out.printf("%s error : %s\n", name, e);
	}

	@Override
	public void onNext(T t) {
		System.out.printf("%s value : %s\n", name, t);
	}

}