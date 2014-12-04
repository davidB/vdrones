package vdrones;

import javax.inject.Inject;

import jme3_ext_deferred.AppState4ViewDeferredTexture;
import lombok.RequiredArgsConstructor;

import com.jme3.app.DebugKeysAppState;
import com.jme3.app.FlyCamAppState;
import com.jme3.app.StatsAppState;
import com.jme3.app.state.AppStateManager;
import com.jme3.bullet.BulletAppState;

@RequiredArgsConstructor(onConstructor=@__(@Inject))
public class AppStateDebug extends AppState0 {

	@Override
	protected void doEnable() {
		System.out.println("DEBUG ENABLE");
		AppStateManager stateManager = app.getStateManager();
		stateManager.detach(stateManager.getState(FlyCamAppState.class));
		stateManager.attach(new StatsAppState());
		stateManager.attach(new DebugKeysAppState());

		BulletAppState s = app.getStateManager().getState(BulletAppState.class);
		if (s != null) s.setDebugEnabled(true);
		app.getInputManager().setCursorVisible(true);
		//app.getViewPort().setBackgroundColor(v? ColorRGBA.Pink : ColorRGBA.White);
		AppStateDeferredRendering r = app.getStateManager().getState(AppStateDeferredRendering.class);
		if (r != null) {
			app.getStateManager().attach(new AppState4ViewDeferredTexture(r.processor, AppState4ViewDeferredTexture.ViewKey.values()));
		}
		//Display.setResizable(v);
	}

	protected void doDispose() {
		AppStateManager stateManager = app.getStateManager();
		stateManager.detach(stateManager.getState(StatsAppState.class));
		stateManager.detach(stateManager.getState(DebugKeysAppState.class));

		BulletAppState s = app.getStateManager().getState(BulletAppState.class);
		if (s != null) s.setDebugEnabled(false);
		System.out.println("DEBUG DISABLE");
	}
}
