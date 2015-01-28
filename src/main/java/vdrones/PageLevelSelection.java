package vdrones;

import javax.inject.Inject;
import javax.inject.Provider;

import jme3_ext.AppState0;
import jme3_ext.Hud;
import jme3_ext.HudTools;
import jme3_ext.InputMapper;
import jme3_ext.PageManager;
import lombok.RequiredArgsConstructor;
import rx.Subscription;
import rx.subscriptions.Subscriptions;

import com.jme3x.jfx.FxPlatformExecutor;

/**
 *
 * @author David Bernard
 */
@RequiredArgsConstructor(onConstructor=@__(@Inject))
class PageLevelSelection extends AppState0 {
	private final HudTools hudTools;
	private final Provider<PageManager> pm; // use Provider as Hack to break the dependency cycle PageManager -> Page -> PageManager
	private final InputMapper inputMapper;
	private final Commands commands;
	private final Channels channels;
	private final EntityFactory entityFactory;

	private boolean prevCursorVisible;
	private Hud<HudLevelSelection> hud;
	private Subscription inputSub;

	@Override
	public void doInitialize() {
		HudLevelSelection ctrl = new HudLevelSelection();
		ctrl.areas.addAll(Area.values());
		hud = hudTools.newHud("Interface/HudLevelSelection.fxml", ctrl);
		hudTools.scaleToFit(hud, app.getGuiViewPort());
	}
	@Override
	protected void doEnable() {

		prevCursorVisible = app.getInputManager().isCursorVisible();
		app.getInputManager().setCursorVisible(true);
		app.getInputManager().addRawInputListener(inputMapper.rawInputListener);
		hudTools.show(hud);

		FxPlatformExecutor.runOnFxApplication(() -> {
			HudLevelSelection p = hud.controller;
			p.areaSelected.addListener((pr, ov, nv) -> {
				app.enqueue(()-> {
					channels.areaCfgs.onNext(entityFactory.newLevel(nv));
					pm.get().goTo(Pages.Run.ordinal());
					return true;
				});
			});
			p.back.onActionProperty().set((e) -> {
				app.enqueue(()-> {
					pm.get().goTo(Pages.Welcome.ordinal());
					return true;
				});
			});
		});

		inputSub = Subscriptions.from(
			commands.exit.value.subscribe((v) -> {
				//if (!v) hud.controller.quit.fire();
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
