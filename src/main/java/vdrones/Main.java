package vdrones;

import com.jme3.app.DebugKeysAppState;
import com.jme3.app.FlyCamAppState;
import com.jme3.app.SimpleApplication;
import com.jme3.app.StatsAppState;
import com.jme3.app.state.AppStateManager;
import com.jme3.renderer.Camera;

import dagger.ObjectGraph;

public class Main {
	//@SuppressWarnings("AssertWithSideEffects")
	public static void main(final String[] args) {
		ObjectGraph injector = ObjectGraph.create(new GameModule());
		SimpleApplication app = injector.get(SimpleApplication.class);

		app.enqueue(()-> {
			clearSimpleApplication(app);
			app.getStateManager().attach(injector.get(AppStateInGame.class));
			return true;
		});
		setAspectRatio(app, 16, 9);
	}

	static public void setAspectRatio(SimpleApplication app, float w, float h) {
		app.enqueue(() -> {
			Camera cam = app.getCamera();
			//cam.resize(w, h, true);
			float ratio = (h * cam.getWidth()) / (w * cam.getHeight());
			if (ratio < 1.0) {
				float margin = (1f - ratio) * 0.5f;
				float frustumW = cam.getFrustumRight();
				float frustumH = cam.getFrustumTop() / ratio;
				//cam.resize(cam.getWidth(), (int)(cam.getHeight() * 0.5), true);
				cam.setViewPort(0f, 1f, margin,  1 - margin);
				cam.setFrustum(cam.getFrustumNear(), cam.getFrustumFar(), -frustumW, frustumW, frustumH, -frustumH);
			}
//			app.getRenderManager().getPreViews().forEach((vp) -> {;
//				cp(cam, vp.getCamera());
//			});
//			app.getRenderManager().getPostViews().forEach((vp) -> {;
//				cp(cam, vp.getCamera());
//			});
//			app.getRenderManager().getMainViews().forEach((vp) -> {;
//				cp(cam, vp.getCamera());
//			});
			cp(cam, app.getGuiViewPort().getCamera());
			return true;
		});
	}

	public static void cp(Camera src, Camera dest) {
		if (src != dest) {
			dest.setViewPort(src.getViewPortLeft(), src.getViewPortRight(), src.getViewPortBottom(), src.getViewPortTop());
			dest.setFrustum(src.getFrustumNear(), src.getFrustumFar(), src.getFrustumLeft(), src.getFrustumRight(), src.getFrustumTop(), src.getFrustumBottom());
		}
	}

	public static void clearSimpleApplication(SimpleApplication app) {
		AppStateManager stateManager = app.getStateManager();
		stateManager.detach(stateManager.getState(FlyCamAppState.class));
		stateManager.detach(stateManager.getState(StatsAppState.class));
		stateManager.detach(stateManager.getState(DebugKeysAppState.class));
	}

}
