package vdrones;

import lombok.RequiredArgsConstructor;
import rx.Observable;
import rx.Subscription;
import rx.subscriptions.Subscriptions;
import rx_ext.SubscriberL2;

import com.jme3.input.InputManager;
import com.jme3.input.KeyInput;
import com.jme3.input.controls.KeyTrigger;
import com.jme3.scene.Spatial;

public class Pipes {

	public static Subscription pipeA(Observable<AreaCfg> l, GeometryAndPhysic gp, EntityFactory efactory) {
		Observable<Spatial> bg = l.flatMap(v -> Observable.from(v.bg));
		Observable<Spatial> spawners = l.flatMap(v-> Observable.from(v.spawnPoints)).map(v -> efactory.newSpawner(v));
		//TODO manage remove of spatial
		return Subscriptions.from(
			bg.subscribe((v) -> gp.add(v))
			, spawners.subscribe((v) -> gp.add(v))
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
		Observable<T2<DroneInput, DroneInfo2.State>> m = drone.flatMap((v) -> {
			DroneInput ctrl = new DroneInput(v);
			return v.state.map(v0 -> new T2<DroneInput, DroneInfo2.State>(ctrl, v0));
		});
		return m.subscribe((T2<DroneInput, DroneInfo2.State> v) -> {
			System.err.println(">>>>>>>>>>> inputmanager : " + v._2);
			if (v._2 == DroneInfo2.State.driving) {
				inputManager.addListener(v._1, DroneInput.LEFT, DroneInput.RIGHT, DroneInput.FORWARD, DroneInput.BACKWARD, DroneInput.TOGGLE_CAMERA);
			} else {
				inputManager.removeListener(v._1);
			}
		});
	}

	static Subscription pipe(DroneInfo2 drone, ControlDronePhy phy) {
		return drone.state.subscribe(new SubscriberL2<DroneInfo2.State>() {
			public Subscription onNext2(DroneInfo2.State b) {
				return (b == DroneInfo2.State.driving)? null :
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
}

@RequiredArgsConstructor
class T2<A1,A2> {
	final public A1 _1;
	final public A2 _2;
}
