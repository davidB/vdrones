package vdrones;

import com.jme3.app.SimpleApplication;
import com.jme3.bullet.BulletAppState;
import com.jme3.math.ColorRGBA;

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
}
