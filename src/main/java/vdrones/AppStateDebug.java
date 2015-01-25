package vdrones;

import javax.inject.Inject;

import jme3_ext.AppState0;
import jme3_ext.PageManager;
import jme3_ext_deferred.AppState4ViewDeferredTexture;
import jme3_ext_spatial_explorer.AppStateSpatialExplorer;
import jme3_ext_spatial_explorer.Helper;
import jme3_ext_spatial_explorer.SpatialExplorer;
import lombok.RequiredArgsConstructor;

import org.controlsfx.control.action.Action;

import com.jme3.app.SimpleApplication;
import com.jme3.app.state.AppStateManager;
import com.jme3.input.InputManager;
import com.jme3.input.KeyInput;
import com.jme3.input.controls.ActionListener;
import com.jme3.input.controls.KeyTrigger;

@RequiredArgsConstructor(onConstructor=@__(@Inject))
public class AppStateDebug extends AppState0 {

	@Inject PageManager pageManager;

	@Override
	protected void doEnable() {
		System.out.println("DEBUG ENABLE");
		AppStateManager stateManager = app.getStateManager();

		app.getInputManager().setCursorVisible(true);
		//app.getViewPort().setBackgroundColor(v? ColorRGBA.Pink : ColorRGBA.White);
		AppStateDeferredRendering r = stateManager.getState(AppStateDeferredRendering.class);
		if (r != null) {
			stateManager.attach(new AppState4ViewDeferredTexture(r.processor, AppState4ViewDeferredTexture.ViewKey.values()));
		}
		Helper.setupSpatialExplorerWithAll(app);
		app.setPauseOnLostFocus(false);
		app.enqueue(() -> {
			AppStateSpatialExplorer se = app.getStateManager().getState(AppStateSpatialExplorer.class);
			registerBarAction_ShowDeferredTexture(se.spatialExplorer, app);
			registerShortcut_GotoPage(pageManager, app);
			return null;
		});
	}

	protected void doDispose() {
		AppStateManager stateManager = app.getStateManager();
		stateManager.detach(stateManager.getState(AppStateSpatialExplorer.class));
		System.out.println("DEBUG DISABLE");
	}

	public static void registerBarAction_ShowDeferredTexture(SpatialExplorer se, SimpleApplication app) {
		se.barActions.add(new Action("Show Deferred Texture", (evt) -> {
			app.enqueue(() -> {
				AppStateManager stateManager = app.getStateManager();
				AppStateDeferredRendering r = stateManager.getState(AppStateDeferredRendering.class);
				if (r != null) {
					AppState4ViewDeferredTexture s = stateManager.getState(AppState4ViewDeferredTexture.class);
					if (s == null) {
						stateManager.attach(new AppState4ViewDeferredTexture(r.processor, AppState4ViewDeferredTexture.ViewKey.values()));
					} else {
						stateManager.detach(s);
					}
				}
				return null;
			});
		}));
	}

	public static void registerShortcut_GotoPage(PageManager pageManager, SimpleApplication app) {
		final String prefixGoto = "GOTOPAGE_";
		ActionListener a = new ActionListener() {
			public void onAction(String name, boolean isPressed, float tpf) {
				if (isPressed && name.startsWith(prefixGoto)) {
					int page = Integer.parseInt(name.substring(prefixGoto.length()));
					pageManager.goTo(page);
				};
			}
		};
		InputManager inputManager = app.getInputManager();
		for (int i = 0; i < Pages.values().length; i++) {
			inputManager.addListener(a, prefixGoto + i);
		}
		inputManager.addMapping(prefixGoto + Pages.Welcome.ordinal(), new KeyTrigger(KeyInput.KEY_NUMPAD0));
		//inputManager.addMapping(PageManager.prefixGoto + Page.LevelSelection.ordinal(), new KeyTrigger(KeyInput.KEY_NUMPAD1));
		//inputManager.addMapping(PageManager.prefixGoto + Page.Loading.ordinal(), new KeyTrigger(KeyInput.KEY_NUMPAD2));
		//inputManager.addMapping(PageManager.prefixGoto + Page.InGame.ordinal(), new KeyTrigger(KeyInput.KEY_NUMPAD3));
		//inputManager.addMapping(PageManager.prefixGoto + Page.Result.ordinal(), new KeyTrigger(KeyInput.KEY_NUMPAD4));
		inputManager.addMapping(prefixGoto + Pages.Settings.ordinal(), new KeyTrigger(KeyInput.KEY_NUMPAD5));
		//inputManager.addMapping(PageManager.prefixGoto + Page.Scores.ordinal(), new KeyTrigger(KeyInput.KEY_NUMPAD6));
		//inputManager.addMapping(PageManager.prefixGoto + Page.About.ordinal(), new KeyTrigger(KeyInput.KEY_NUMPAD7));
	}
}
