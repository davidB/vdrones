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

	public static Subscription pipeA(Observable<CfgArea> l, GeometryAndPhysic gp, EntityFactory efactory) {
		Observable<Spatial> bg = l.flatMap(v -> Observable.from(v.bg));
		Observable<Spatial> spawners = l.flatMap(v-> Observable.from(v.spawnPoints)).map(v -> efactory.newSpawner(v));
		//TODO manage remove of spatial
		return Subscriptions.from(
			bg.subscribe((v) -> gp.add(v))
			, spawners.subscribe((v) -> gp.add(v))
		);
	}

	public static Subscription pipe(Observable<CfgArea> l, AppStateLights lights) {
		// TODO manage remove of light
		return Subscriptions.from(
				l.flatMap(v -> Observable.from(v.lights)).subscribe((v) -> lights.addLight(v))
			//, l.removeLight.subscribe((v) -> lights.removeLight(v))
		);
	}

	static Subscription pipe(Observable<InfoDrone> drone, InputManager inputManager) {
		inputManager.addMapping(DroneInput.LEFT, new KeyTrigger(KeyInput.KEY_A), new KeyTrigger(KeyInput.KEY_Q));
		inputManager.addMapping(DroneInput.RIGHT, new KeyTrigger(KeyInput.KEY_D));
		inputManager.addMapping(DroneInput.FORWARD, new KeyTrigger(KeyInput.KEY_W), new KeyTrigger(KeyInput.KEY_Z));
		//inputManager.addMapping(DroneInput.TOGGLE_CAMERA, new KeyTrigger(KeyInput.KEY_M));
		//inputManager.addMapping(RESET, new KeyTrigger(KeyInput.KEY_RETURN));

		//FIXME use a temporary variable m to avoid type inference issue.
		Observable<T2<DroneInput, InfoDrone.State>> m = drone.flatMap((v) -> {
			DroneInput ctrl = new DroneInput(v);
			return v.state.map(v0 -> new T2<DroneInput, InfoDrone.State>(ctrl, v0));
		});
		return m.subscribe((T2<DroneInput, InfoDrone.State> v) -> {
			if (v._2 == InfoDrone.State.driving) {
				inputManager.addListener(v._1, DroneInput.LEFT, DroneInput.RIGHT, DroneInput.FORWARD, DroneInput.BACKWARD);
			} else {
				inputManager.removeListener(v._1);
			}
		});
	}
}

@RequiredArgsConstructor
class T2<A1,A2> {
	final public A1 _1;
	final public A2 _2;
}
