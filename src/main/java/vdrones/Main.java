package vdrones;

import javafx.scene.Scene;
import javafx.scene.text.Font;

import javax.inject.Inject;

import jme3_ext.AudioManager;
import jme3_ext.PageManager;
import jme3_ext.SetupHelpers;

import com.jme3.app.SimpleApplication;
import com.jme3.audio.AudioNode;
import com.jme3x.jfx.FxPlatformExecutor;
import com.jme3x.jfx.GuiManager;

import dagger.ObjectGraph;

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
		ObjectGraph injector = ObjectGraph.create(new GameModule());
		injector.get(Main.class); // Main constructor used to initialize service
	}

	//HACK to receive service without need to explicitly list them and to initialize them
	@Inject
	Main(SimpleApplication app, GuiManager guiManager, PageManager pageManager, AudioManager audioMgr) {
		//		setAspectRatio(app, 16, 9);
		SetupHelpers.disableDefaults(app);
		SetupHelpers.setDebug(app, false);
		SetupHelpers.logJoystickInfo(app.getInputManager());
		initGui(guiManager);
		initPages(pageManager, app, false);
		initAudio(app, audioMgr);
	}



	static void initPages(PageManager pageManager, SimpleApplication app, boolean debug) {
		app.enqueue(() -> {
			pageManager.goTo(Pages.Welcome.ordinal());
			//pageManager.goTo(Pages.Garage.ordinal());
			return true;
		});
	}

	static void initGui(GuiManager guiManager) {
		//see http://blog.idrsolutions.com/2014/04/use-external-css-files-javafx/
		Scene scene = guiManager.getjmeFXContainer().getScene();
		FxPlatformExecutor.runOnFxApplication(() -> {
			Font.loadFont(Main.class.getResource("/Fonts/scifly-sans-webfont.ttf").toExternalForm(), 10);
			String css = Main.class.getResource("/Interface/main.css").toExternalForm();
			scene.getStylesheets().clear();
			scene.getStylesheets().add(css);
		});
	}

	static void initAudio(SimpleApplication app, AudioManager audioMgr) {
		app.enqueue(() -> {
			audioMgr.loadFromAppSettings();

			AudioNode audioBg = new AudioNode(app.getAssetManager(), "Musics/Hypnothis.ogg", false);
			audioBg.setName("audioBg");
			audioBg.setLooping(true);
			audioBg.setPositional(false);
			audioMgr.musics.add(audioBg);
			app.getRootNode().attachChild(audioBg);
			audioBg.play();
			return true;
		});
	}


}