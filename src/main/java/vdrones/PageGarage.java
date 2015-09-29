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
class PageGarage extends AppState0 {
	private final HudTools hudTools;
	private final PublishSubject<Pages> pm;
	private final InputMapper inputMapper;
	private final Commands commands;
	private final AppStateGarage appGarage;

	private boolean prevCursorVisible;
	private Hud<HudGarage> hud;
	private Subscription inputSub;

	@Override
	public void doInitialize() {
		hud = hudTools.newHud("Interface/HudGarage.fxml", new HudGarage());
		//hudTools.scaleToFit(hud, app.getGuiViewPort());
	}
	@Override
	protected void doEnable() {

		prevCursorVisible = app.getInputManager().isCursorVisible();
		app.getInputManager().setCursorVisible(true);
		app.getInputManager().addRawInputListener(inputMapper.rawInputListener);
		hudTools.show(hud);

		FxPlatformExecutor.runOnFxApplication(() -> {
			HudGarage p = hud.controller;
			p.back.onActionProperty().set((e) -> {
				app.enqueue(()-> {
					pm.onNext(Pages.Welcome);
					return true;
				});
			});
		});

		inputSub = Subscriptions.from(
			commands.exit.value.subscribe((v) -> {
				//if (!v) hud.controller.quit.fire();
			})
		);
		app.getStateManager().attach(appGarage);
	}

	@Override
	protected void doDisable() {
		app.getStateManager().detach(appGarage);
		hudTools.hide(hud);
		app.getInputManager().setCursorVisible(prevCursorVisible);
		app.getInputManager().removeRawInputListener(inputMapper.rawInputListener);
		if (inputSub != null){
			inputSub.unsubscribe();
			inputSub = null;
		}
	}
}
