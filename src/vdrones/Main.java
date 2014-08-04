package vdrones;

import org.lwjgl.opengl.Display;

import com.jme3.app.DebugKeysAppState;
import com.jme3.app.FlyCamAppState;
import com.jme3.app.SimpleApplication;
import com.jme3.app.StatsAppState;
import com.jme3.bullet.BulletAppState;
import com.jme3.math.ColorRGBA;
import com.jme3.system.AppSettings;

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
		AppSettings settings = new AppSettings(true);
		//settings.setResolution(640,480);
//		settings.setRenderer("JOGL");
//		settings.setRenderer(AppSettings.LWJGL_OPENGL3);
		SimpleApplication app = new SimpleApplication(){
			@Override
			public void simpleInitApp() {
				System.err.println("****** simpleInitApp ** ...");
				stateManager.detach(stateManager.getState(FlyCamAppState.class));
				stateManager.attach(new StatsAppState());
				stateManager.attach(new DebugKeysAppState());
				//stateManager.attach(new ScreenshotAppState("", System.currentTimeMillis()));
				stateManager.attach(new BulletAppState());
				//stateManager.attach(new AppStatePostProcessing());
				stateManager.attach(new AppStateLights());
				stateManager.attach(new AppStateCamera());
				stateManager.attach(new AppStateGameLogic());
				stateManager.attach(new AppStateGeoPhy());
				stateManager.attach(new PhysicsCollisionListenerAll());
				stateManager.attach(new AppStateHudInGame());
				System.err.println("****** simpleInitApp ** DONE");
			}

			@Override
			public void simpleUpdate(float tpf) {
				if (Display.wasResized()) {
					this.settings.setWidth(Display.getWidth());
					this.settings.setHeight(Display.getHeight());
					this.reshape(this.settings.getWidth(), this.settings.getHeight());
				}
			}

		};
		app.setSettings(settings);
		app.setShowSettings(true);
		app.setDisplayStatView(true);
		app.setDisplayFps(true);
		app.start();
		setDebug(app, true);
	}

	static public void setDebug(SimpleApplication app, boolean v) {
		app.enqueue(() -> {
			app.getStateManager().getState(BulletAppState.class).setDebugEnabled(v);
			app.getInputManager().setCursorVisible(v);
			app.getViewPort().setBackgroundColor(v? ColorRGBA.Pink : ColorRGBA.White);
			Display.setResizable(v);
			return true;
		});
	}
}
