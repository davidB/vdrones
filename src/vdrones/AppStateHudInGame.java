package vdrones;

import rx.Subscriber;
import rx.Subscription;
import rx.subscriptions.Subscriptions;

import com.jme3x.jfx.FXMLHud;
import com.jme3x.jfx.GuiManager;

import fxml.InGame;

public class AppStateHudInGame extends AppState0 {
	private GuiManager guiManager;
	private FXMLHud<InGame> hud;
	private Subscription subscription;

	@Override
	public void doInitialize() {
		guiManager = injector.getInstance(GuiManager.class);

		hud = new FXMLHud<>("Interface/ingame.fxml");
		hud.precache();
		guiManager.attachHudAsync(hud);
	}

	protected void doEnable() {
		Channels channels = injector.getInstance(Channels.class);
		//Observable.switchOnNext(channels.droneInfo2s)
		Subscription s1 = channels.droneInfo2s.subscribe(new Subscriber<DroneInfo2>(){
			private Subscription subscription = null;
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
			public void onNext(DroneInfo2 t) {
				terminate();
				hud.getController().setEnergyMax(t.cfg.energyStoreMax);
				subscription = t.energy.subscribe((v) -> hud.getController().setEnergy(v));
			}
		});
		//Observable.switchOnNext(
		Subscription s2 = channels.areaInfo2s.subscribe(new Subscriber<AreaInfo2>(){
			private Subscription subscription = null;
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
			public void onNext(AreaInfo2 area) {
				terminate();
				subscription = area.clock.subscribe((v) -> hud.getController().setClock(v.intValue()));
			}
		});
		subscription = Subscriptions.from(s1, s2);
	}

	@Override
	protected void doDisable() {
		subscription.unsubscribe();
	}

	@Override
	public void doDispose() {
		guiManager.detachHudAsync(hud);
	}
}
