package vdrones;

import lombok.RequiredArgsConstructor;
import rx.Observable;
import rx.Subscriber;
import rx.Subscription;
import rx.subscriptions.Subscriptions;

import com.jme3.input.InputManager;
import com.jme3.input.KeyInput;
import com.jme3.input.controls.KeyTrigger;
import com.jme3x.jfx.FXMLHud;

import fxml.InGame;

public class Pipes {

	public static Subscription pipe(LevelLoader l, AppStateGeoPhy gp) {
		return Subscriptions.from(
			l.addSpatial.subscribe((v) ->{
				System.out.println("add spatial");
				gp.toAdd.offer(v);
			})
			, l.removeSpatial.subscribe((v) -> gp.toRemove.offer(v))
		);
	}

	public static Subscription pipe(LevelLoader l, AppStateLights lights) {
		return Subscriptions.from(
			l.addLight.subscribe((v) -> lights.addLight(v))
			, l.removeLight.subscribe((v) -> lights.removeLight(v))
		);
	}

	static Subscription pipe(InputManager inputManager, Observable<DroneInfo2> drone) {
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

	static Subscription pipe(DroneInfo2 drone, ControlDronePhy phy) {
		return drone.drivable.subscribe(new SubscriberL2<Boolean>() {
			Subscription onNext2(Boolean b) {
				return (!b)? null :
					Subscriptions.from(
						drone.forward.subscribe((v) -> {
							phy.forwardLg = v * drone.cfg.forward;
							phy.linearDamping = drone.cfg.linearDamping;
						})
						, drone.turn.subscribe((v) -> phy.turnLg = v * drone.cfg.turn)
					);
			}
		});
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