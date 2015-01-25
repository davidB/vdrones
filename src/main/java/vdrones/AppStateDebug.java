package vdrones;

import javax.inject.Inject;

import jme3_ext_deferred.AppState4ViewDeferredTexture;
import jme3_ext_spatial_explorer.AppStateSpatialExplorer;
import jme3_ext_spatial_explorer.Helper;
import jme3_ext_spatial_explorer.SpatialExplorer;
import lombok.RequiredArgsConstructor;

import org.controlsfx.control.action.Action;

import com.jme3.app.SimpleApplication;
import com.jme3.app.state.AppStateManager;

@RequiredArgsConstructor(onConstructor=@__(@Inject))
public class AppStateDebug extends AppState0 {

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
		app.enqueue(() -> {
			AppStateSpatialExplorer se = app.getStateManager().getState(AppStateSpatialExplorer.class);
			registerBarAction_ShowDeferredTexture(se.spatialExplorer, app);
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
}
