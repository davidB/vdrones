package vdrones;

import jme3_ext.SetupHelpers;

import com.jme3.app.SimpleApplication;

import dagger.ObjectGraph;

public class Main0 extends Main1{
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
		//SetupHelpers.disableDefaults(app);
		app.enqueue(()-> {
			app.getStateManager().attach(injector.get(AppStateRun.class));
			setDebug(app, true, injector);
			return true;
		});
		//setAspectRatio(app, 16, 9);
	}


	static public void setDebug(SimpleApplication app, boolean v, ObjectGraph injector) {
		SetupHelpers.setDebug(app, v);
		app.enqueue(() -> {
			if (v) {
				app.getStateManager().attach(injector.get(AppStateDebug.class));
			} else {
				app.getStateManager().detach(app.getStateManager().getState(AppStateDebug.class));
			}
			return true;
		});
	}
}
