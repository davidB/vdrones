package vdrones;

import javax.inject.Inject;

import jme3_ext.AudioManager;
import jme3_ext.PageManager;
import jme3_ext.SetupHelpers;

import com.jme3.app.SimpleApplication;
import com.jme3x.jfx.GuiManager;

import dagger.ObjectGraph;

public class Main0 extends Main1{
	private static boolean assertionsEnabled;
	private static boolean enabled() {
		Main0.assertionsEnabled = true;
		return true;
	}

	//@SuppressWarnings("AssertWithSideEffects")
	public static void main(final String[] args) {
		//-Djava.util.logging.config.file=logging.properties
		SetupHelpers.installSLF4JBridge();

		assert Main0.enabled();
		if (!Main0.assertionsEnabled) {
			throw new RuntimeException("Assertions must be enabled (vm args -ea");
		}
		ObjectGraph injector = ObjectGraph.create(new Game0Module());
		injector.get(Main0.class); // Main constructor used to initialize service
	}

	//HACK to receive service without need to explicitly list them and to initialize them
	@Inject
	Main0(SimpleApplication app, GuiManager guiManager, PageManager pageManager, AudioManager audioMgr, AppStateDebug appDebug, Channels channels, EntityFactory entityFactory) {
		//		setAspectRatio(app, 16, 9);
		SetupHelpers.disableDefaults(app);
		SetupHelpers.setDebug(app, false);
		SetupHelpers.logJoystickInfo(app.getInputManager());
		Main.initGui(guiManager);
		Main.initPages(pageManager, app, false);
		audioMgr.loadFromAppSettings();
		app.enqueue(()-> {
			channels.areaCfgs.onNext(entityFactory.newLevel(Area.B00));
			pageManager.goTo(Pages.Run.ordinal());
			setDebug(app, true, appDebug);
			return true;
		});
	}

	static public void setDebug(SimpleApplication app, boolean v, AppStateDebug appDebug) {
		SetupHelpers.setDebug(app, v);
		app.enqueue(() -> {
			if (v) {
				app.getStateManager().attach(appDebug);
			} else {
				app.getStateManager().detach(app.getStateManager().getState(AppStateDebug.class));
			}
			return true;
		});
	}
}
