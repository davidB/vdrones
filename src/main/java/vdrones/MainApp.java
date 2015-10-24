package vdrones;

import javax.inject.Inject;

import com.jme3.app.SimpleApplication;
import com.jme3.audio.AudioNode;
import com.jme3x.jfx.FxPlatformExecutor;
import com.jme3x.jfx.GuiManager;

import javafx.scene.Scene;
import javafx.scene.text.Font;
import jme3_ext.AudioManager;
import jme3_ext.PageManager;
import jme3_ext.SetupHelpers;

public class MainApp {
	//HACK to receive service without need to explicitly list them and to initialize them
	@Inject
	MainApp(SimpleApplication app, GuiManager guiManager, PageManager<Pages> pageManager, AudioManager audioMgr) {
		//		setAspectRatio(app, 16, 9);
		SetupHelpers.disableDefaults(app);
		SetupHelpers.setDebug(app, false);
		SetupHelpers.logJoystickInfo(app.getInputManager());
		initGui(guiManager);
		initPages(pageManager, app, false);
		initAudio(app, audioMgr);
	}



	static void initPages(PageManager<Pages> pageManager, SimpleApplication app, boolean debug) {
		app.enqueue(() -> {
			pageManager.goTo(Pages.Welcome);
			//pageManager.goTo(Pages.Garage.ordinal());
			return true;
		});
	}

	static void initGui(GuiManager guiManager) {
		//see http://blog.idrsolutions.com/2014/04/use-external-css-files-javafx/
		Scene scene = guiManager.getjmeFXContainer().getScene();
		FxPlatformExecutor.runOnFxApplication(() -> {
			Font.loadFont(MainApp.class.getResource("/Fonts/scifly-sans-webfont.ttf").toExternalForm(), 10);
			String css = MainApp.class.getResource("/Interface/main.css").toExternalForm();
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