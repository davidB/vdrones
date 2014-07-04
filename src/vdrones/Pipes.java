package vdrones;

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

	static Subscription pipe(InputManager inputManager, DroneInfo drone) {
		final DroneInput ctrl = new DroneInput(drone);
		inputManager.addMapping(DroneInput.LEFT, new KeyTrigger(KeyInput.KEY_H));
		inputManager.addMapping(DroneInput.RIGHT, new KeyTrigger(KeyInput.KEY_K));
		inputManager.addMapping(DroneInput.FORWARD, new KeyTrigger(KeyInput.KEY_U));
		inputManager.addMapping(DroneInput.BACKWARD, new KeyTrigger(KeyInput.KEY_J));
		inputManager.addMapping(DroneInput.TOGGLE_CAMERA, new KeyTrigger(KeyInput.KEY_M));
		//inputManager.addMapping(RESET, new KeyTrigger(KeyInput.KEY_RETURN));
		inputManager.addListener(ctrl, DroneInput.LEFT, DroneInput.RIGHT, DroneInput.FORWARD, DroneInput.BACKWARD, DroneInput.TOGGLE_CAMERA);
		return new Subscription() {
			private boolean subcribed = true;

			@Override
			public void unsubscribe() {
				inputManager.removeListener(ctrl);
				subcribed = false;
			}

			@Override
			public boolean isUnsubscribed() {
				return !subcribed;
			}

		};
	}

	static Subscription pipe(AreaInfo area, FXMLHud<InGame> hud) {
		return area.clock.subscribe((v) -> hud.getController().setClock(v.intValue()));
	}

	static Subscription pipe(DroneInfo drone, FXMLHud<InGame> hud) {
		return drone.energy.subscribe((v) -> hud.getController().setEnergy(v, drone.cfg.energyStoreMax));
	}

	static Subscription pipe(DroneInfo drone, ControlDronePhy phy) {
		return Subscriptions.from(
				drone.forward.subscribe((v) -> {
					phy.forwardLg = v * drone.cfg.forward;
					phy.linearDamping = drone.cfg.linearDamping;
				})
				, drone.turn.subscribe((v) -> phy.turnLg = v * drone.cfg.turn)
		);
	}

}
