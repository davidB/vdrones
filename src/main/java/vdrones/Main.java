package vdrones;

import javafx.scene.Scene;
import javafx.scene.text.Font;

import javax.inject.Inject;
import javax.inject.Singleton;

import jme3_ext.AudioManager;
import jme3_ext.PageManager;
import jme3_ext.SetupHelpers;

import com.jme3.app.SimpleApplication;
import com.jme3.audio.AudioNode;
import com.jme3x.jfx.FxPlatformExecutor;
import com.jme3x.jfx.GuiManager;

import dagger.Component;

@Singleton
@Component(modules = GameModule.class)
interface MainAppMaker {
  MainApp make();
}

public class Main {

	private static boolean assertionsEnabled;
	private static boolean enabled() {
		Main.assertionsEnabled = true;
		return true;
	}

	public static void main(final String[] args) {
		//-Djava.util.logging.config.file=logging.properties
		SetupHelpers.installSLF4JBridge();

//		assert Main.enabled();
//		if (!Main.assertionsEnabled) {
//			throw new RuntimeException("Assertions must be enabled (vm args -ea");
//		}
		//ObjectGraph injector = ObjectGraph.create(new GameModule());
		//injector.get(Main.class); // Main constructor used to initialize service
		//DaggerMainXMaker.builder().build()
		DaggerMainAppMaker.create().make();
	}

//	//HACK to receive service without need to explicitly list them and to initialize them
//	@Inject
//	Main(SimpleApplication app, GuiManager guiManager, PageManager pageManager, AudioManager audioMgr) {
//		//		setAspectRatio(app, 16, 9);
//		SetupHelpers.disableDefaults(app);
//		SetupHelpers.setDebug(app, false);
//		SetupHelpers.logJoystickInfo(app.getInputManager());
//		initGui(guiManager);
//		initPages(pageManager, app, false);
//		initAudio(app, audioMgr);
//	}
}