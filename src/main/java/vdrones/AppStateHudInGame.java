package vdrones;

import javax.inject.Inject;

import jme3_ext.AppState0;
import lombok.RequiredArgsConstructor;
import rx.Subscriber;
import rx.Subscription;
import rx.subscriptions.Subscriptions;

import com.jme3x.jfx.FXMLHud;
import com.jme3x.jfx.GuiManager;

import fxml.InGame;

@RequiredArgsConstructor(onConstructor=@__(@Inject))
public class AppStateHudInGame extends AppState0 {
	final GuiManager guiManager;
	final Channels channels;
	private FXMLHud<InGame> hud;
	private Subscription subscription;

	@Override
	public void doInitialize() {
		hud = new FXMLHud<>("Interface/ingame.fxml");
		hud.precache();
		guiManager.attachHudAsync(hud);
	}

	protected void doEnable() {
		//Observable.switchOnNext(channels.droneInfo2s)
		Subscription s1 = channels.drones.subscribe(new Subscriber<InfoDrone>(){
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
			public void onNext(InfoDrone t) {
				terminate();
				hud.getController().setEnergyMax(t.cfg.energyStoreMax);
				hud.getController().setHealthMax(t.cfg.healthMax);
				subscription = Subscriptions.from(
					t.energy.subscribe((v) -> hud.getController().setEnergy(v))
					, t.health.subscribe((v) -> hud.getController().setHealth(v))
					, t.score.subscribe((v) -> hud.getController().setScore(v))
				);
			}
		});
		//Observable.switchOnNext(
		Subscription s2 = channels.areaInfo2s.subscribe(new Subscriber<InfoArea>(){
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
			public void onNext(InfoArea area) {

				terminate();
				subscription = area.clock
					.map(v -> v.intValue())
					.distinctUntilChanged()
					.subscribe((v) -> hud.getController().setClock(v))
					;
			}
		});
		subscription = Subscriptions.from(s1, s2);
	}

	@Override
	protected void doDisable() {
		if (subscription != null) {
			subscription.unsubscribe();
			subscription = null;
		}
	}

	@Override
	public void doDispose() {
		guiManager.detachHudAsync(hud);
	}
}
