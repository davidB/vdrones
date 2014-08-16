package vdrones;

import com.jme3.app.SimpleApplication;
import com.jme3.bullet.BulletAppState;
import com.jme3.math.ColorRGBA;
import com.jme3.renderer.Camera;

public class Main {
	private static boolean assertionsEnabled;
	private static boolean enabled() {
		Main.assertionsEnabled = true;
		return true;
	}

	//@SuppressWarnings("AssertWithSideEffects")
	public static void main(final String[] args) {
		assert Main.enabled();
		if (!Main.assertionsEnabled) {
			throw new RuntimeException("Assertions must be enabled (vm args -ea");
		}
		SimpleApplication app = Injectors.find().getInstance(SimpleApplication.class);
		setAspectRatio(app, 16, 9);
		setDebug(app, true);
	}

	static public void setDebug(SimpleApplication app, boolean v) {
		app.enqueue(() -> {
			app.getStateManager().getState(BulletAppState.class).setDebugEnabled(v);
			app.getInputManager().setCursorVisible(v);
			app.getViewPort().setBackgroundColor(v? ColorRGBA.Pink : ColorRGBA.White);
			//Display.setResizable(v);
			return true;
		});
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

	static void cp(Camera src, Camera dest) {
		if (src != dest) {
			dest.setViewPort(src.getViewPortLeft(), src.getViewPortRight(), src.getViewPortBottom(), src.getViewPortTop());
			dest.setFrustum(src.getFrustumNear(), src.getFrustumFar(), src.getFrustumLeft(), src.getFrustumRight(), src.getFrustumTop(), src.getFrustumBottom());
		}
	}
}
