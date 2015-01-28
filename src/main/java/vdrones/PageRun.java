package vdrones;

import javax.inject.Inject;

import com.jme3x.jfx.FxPlatformExecutor;

import jme3_ext.AppState0;
import jme3_ext.Hud;
import jme3_ext.HudTools;
import lombok.RequiredArgsConstructor;
import rx.Subscriber;
import rx.Subscription;
import rx.subscriptions.Subscriptions;

@RequiredArgsConstructor(onConstructor=@__(@Inject))
public class PageRun extends AppState0 {
	private final HudTools hudTools;
	final Channels channels;
	final AppStateRun asRun;

	private boolean prevCursorVisible;
	private Hud<HudRun> hud;
	private Subscription subscription;

	@Override
	public void doInitialize() {
		hud = hudTools.newHud("Interface/HudRun.fxml", new HudRun());
		hudTools.scaleToFit(hud, app.getGuiViewPort());
	}

	protected void doEnable() {
		prevCursorVisible = app.getInputManager().isCursorVisible();
		app.getInputManager().setCursorVisible(false);
		hudTools.show(hud);

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
				hud.controller.setEnergyMax(t.cfg.energyStoreMax);
				hud.controller.setHealthMax(t.cfg.healthMax);
				subscription = Subscriptions.from(
					t.energy.subscribe((v) -> hud.controller.setEnergy(v))
					, t.health.subscribe((v) -> hud.controller.setHealth(v))
					, t.score.subscribe((v) -> hud.controller.setScore(v))
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
					.subscribe((v) -> hud.controller.setClock(v))
					;
			}
		});
		subscription = Subscriptions.from(s1, s2);
		app.getStateManager().attach(asRun);
		hack_letFocusOn3d();
	}

	@Override
	protected void doDisable() {
		hudTools.hide(hud);
		app.getInputManager().setCursorVisible(prevCursorVisible);
		app.getStateManager().detach(asRun);

		if (subscription != null) {
			subscription.unsubscribe();
			subscription = null;
		}
	}

	void hack_letFocusOn3d() {
		FxPlatformExecutor.runOnFxApplication(() -> {
			//HACK TO force focus (keyboard) on play area
			//hud.region.focusedProperty().addListener((v) -> System.out.println("focus change : " + v));
			//hud.region.requestFocus();
			//Scene scene = hud.region.getScene();
			//scene.getWindow().requestFocus();
			//Event.fireEvent(scene.getWindow(), new MouseEvent(MouseEvent.MOUSE_CLICKED, 10, 10, (int)scene.getWindow().getX() + 10, (int)scene.getWindow().getY() + 10, MouseButton.PRIMARY, 1, true, true, true, true, true, true, true, true, true, true, null));
			try {
				java.awt.Robot r = new java.awt.Robot();
//				r.mouseMove((int)scene.getWindow().getX() + 10, (int)scene.getWindow().getY() + 10);
				r.mousePress(java.awt.event.InputEvent.BUTTON1_DOWN_MASK);
				r.mouseRelease(java.awt.event.InputEvent.BUTTON1_DOWN_MASK);
			} catch (Exception e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}

		});
	}
}
