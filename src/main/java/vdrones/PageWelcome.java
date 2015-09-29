package vdrones;

import javax.inject.Inject;

import jme3_ext.AppState0;
import jme3_ext.Hud;
import jme3_ext.HudTools;
import jme3_ext.InputMapper;
import lombok.RequiredArgsConstructor;
import rx.Subscription;
import rx.subjects.PublishSubject;
import rx.subscriptions.Subscriptions;

import com.jme3x.jfx.FxPlatformExecutor;

/**
 *
 * @author David Bernard
 */
@RequiredArgsConstructor(onConstructor=@__(@Inject))
class PageWelcome extends AppState0 {
	private final HudTools hudTools;
	private final PublishSubject<Pages> pm;
	private final InputMapper inputMapper;
	private final Commands commands;

	private boolean prevCursorVisible;
	private Hud<HudWelcome> hud;
	private Subscription inputSub;

	@Override
	public void doInitialize() {
		hud = hudTools.newHud("Interface/HudWelcome.fxml", new HudWelcome());
		//hudTools.scaleToFit(hud, app.getGuiViewPort());
	}
	@Override
	protected void doEnable() {
		prevCursorVisible = app.getInputManager().isCursorVisible();
		app.getInputManager().setCursorVisible(true);
		app.getInputManager().addRawInputListener(inputMapper.rawInputListener);
		hudTools.show(hud);

		FxPlatformExecutor.runOnFxApplication(() -> {
			HudWelcome p = hud.controller;
			p.play.onActionProperty().set((v) -> {
				app.enqueue(()-> {
					pm.onNext(Pages.Run);
					return true;
				});
			});
			p.garage.onActionProperty().set((v) -> {
				app.enqueue(()-> {
					pm.onNext(Pages.Garage);
					return true;
				});
			});
			p.settings.onActionProperty().set((v) -> {
				app.enqueue(()-> {
					pm.onNext(Pages.Settings);
					return true;
				});
			});
			p.quit.onActionProperty().set((v) -> {
				app.enqueue(()->{
					app.stop();
					return true;
				});
			});
		});

		inputSub = Subscriptions.from(
			commands.exit.value.subscribe((v) -> {
				if (!v) hud.controller.quit.fire();
			})
		);
	}

	@Override
	protected void doDisable() {
		hudTools.hide(hud);
		app.getInputManager().setCursorVisible(prevCursorVisible);
		app.getInputManager().removeRawInputListener(inputMapper.rawInputListener);
		if (inputSub != null){
			inputSub.unsubscribe();
			inputSub = null;
		}
	}
}
