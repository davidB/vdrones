package vdrones;

import com.jme3.app.SimpleApplication;
import com.jme3.bullet.BulletAppState;
import com.jme3.math.ColorRGBA;

import dagger.ObjectGraph;

public class Main0 extends Main{
	private static boolean assertionsEnabled;
	private static boolean enabled() {
		Main0.assertionsEnabled = true;
		return true;
	}

	//@SuppressWarnings("AssertWithSideEffects")
	public static void main(final String[] args) {
		assert Main0.enabled();
		if (!Main0.assertionsEnabled) {
			throw new RuntimeException("Assertions must be enabled (vm args -ea");
		}
		ObjectGraph injector = ObjectGraph.create(new Game0Module());
		SimpleApplication app = injector.get(SimpleApplication.class);

		app.enqueue(()-> {
			app.getStateManager().attach(injector.get(AppStateInGame.class));
			return true;
		});
		setAspectRatio(app, 16, 9);
		setDebug(app, true);
	}


	static public void setDebug(SimpleApplication app, boolean v) {
		app.enqueue(() -> {
			BulletAppState s = app.getStateManager().getState(BulletAppState.class);
			if (s != null) s.setDebugEnabled(v);
			app.getInputManager().setCursorVisible(v);
			app.getViewPort().setBackgroundColor(v? ColorRGBA.Pink : ColorRGBA.White);
			//Display.setResizable(v);
			return true;
		});
	}

}
