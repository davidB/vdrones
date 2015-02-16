package vdrones;

import java.util.Locale;
import java.util.ResourceBundle;
import java.util.concurrent.CountDownLatch;

import javafx.application.Platform;
import javafx.fxml.FXMLLoader;
import javafx.fxml.JavaFXBuilderFactory;

import javax.inject.Singleton;

import jme3_ext.AppSettingsLoader;
import jme3_ext.InputMapper;
import jme3_ext.InputMapperHelpers;
import jme3_ext.JmeModule;
import jme3_ext.PageManager;
import jme3_ext_deferred.MatIdManager;
import jme3_ext_deferred.MaterialConverter;
import jme3_ext_deferred.SceneProcessor4Deferred;

import com.jme3.app.SimpleApplication;
import com.jme3.app.state.AppState;
import com.jme3.asset.AssetManager;
import com.jme3.input.KeyInput;
import com.jme3.renderer.lwjgl.LwjglDisplayCustom;
import com.jme3.system.AppSettings;
import com.jme3x.jfx.FxPlatformExecutor;

import dagger.Module;
import dagger.Provides;

@Module(library=true, complete=false)
class DeferredModule {

	@Singleton
	@Provides
	public MatIdManager matIdManager() {
		return new MatIdManager();
	}

	@Singleton
	@Provides
	public SceneProcessor4Deferred sceneProcessor4Deferred(AssetManager a, MatIdManager m) {
		return new SceneProcessor4Deferred(a, m);
	}

	@Singleton
	@Provides
	public MaterialConverter mc(AssetManager a, MatIdManager m) {
		return new MaterialConverter(a,m);
	}
}
@Module(
		library=true,
		complete=false,
		includes = {
			JmeModule.class,
			DeferredModule.class,
		}
	)
class GameSharedModule{
	@Provides
	public AppSettingsLoader appSettingsLoader() {
		final String prefKey = GameSharedModule.class.getCanonicalName();
		return new AppSettingsLoader() {
			@Override
			public AppSettings loadInto(AppSettings settings) throws Exception{
				settings.load(prefKey);
				return settings;
			}

			@Override
			public AppSettings save(AppSettings settings) throws Exception{
				settings.save(prefKey);
				return settings;
			}
		};
	}

	@Singleton
	@Provides
	public SimpleApplication simpleApplication(AppSettings appSettings) {
		//HACK
		final CountDownLatch initializedSignal = new CountDownLatch(1);
		SimpleApplication app = new SimpleApplication(){
			@Override
			public void simpleInitApp() {
				initializedSignal.countDown();
			}

			@Override
			public void destroy() {
				super.destroy();
				FxPlatformExecutor.runOnFxApplication(() -> {
					Platform.exit();
				});
			}
		};
		app.setSettings(appSettings);
		app.setShowSettings(false);
		app.setDisplayStatView(false);
		app.setDisplayFps(false);
		app.start();
		try {
			initializedSignal.await();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		return app;
	}

	@Singleton
	@Provides
	public PageManager pageManager(SimpleApplication app,
			PageWelcome pageWelcome, PageSettings pageSettings, PageGarage pageGarage,
			PageLevelSelection pageLevelSelection, PageRun pageRun, PageRunEnd pageRunEnd
			) {
		AppState[] pages = new AppState[Pages.values().length];
		pages[Pages.Welcome.ordinal()] = pageWelcome;
		pages[Pages.LevelSelection.ordinal()] = pageLevelSelection;
		pages[Pages.Run.ordinal()] = pageRun;
		pages[Pages.RunEnd.ordinal()] = pageRunEnd;
		pages[Pages.Settings.ordinal()] = pageSettings;
		pages[Pages.Garage.ordinal()] = pageGarage;
		PageManager pageManager = new PageManager(app.getStateManager(), pages);
		return pageManager;
	}

	@Singleton
	@Provides
	public Locale locale() {
		return Locale.getDefault();
	}

	//TODO use http://hub.jmonkeyengine.org/t/i18n-from-csv-calc/31492/2
	@Provides
	public ResourceBundle resources(Locale locale) {
		//I18NUtility.getBundle(new File("./translationstest.csv"), Locale.GERMANY);
		return ResourceBundle.getBundle("Interface.labels", locale);
	}

	@Provides
	public FXMLLoader fxmlLoader(ResourceBundle resources) {
		FXMLLoader fxmlLoader = new FXMLLoader();
		fxmlLoader.setResources(resources);
		fxmlLoader.setBuilderFactory(new JavaFXBuilderFactory());
		return fxmlLoader;
	}

	@Provides
	@Singleton
	public InputMapper inputMapper(Commands controls) {
		//TODO save / restore mapper, until then harcoded mapping
		InputMapper m = new InputMapper();
		InputMapperHelpers.mapKey(m, KeyInput.KEY_ESCAPE, controls.exit.value);
		// arrow
		InputMapperHelpers.mapKey(m, KeyInput.KEY_UP, controls.moveZ.value, true);
		InputMapperHelpers.mapKey(m, KeyInput.KEY_DOWN, controls.moveZ.value, false);
		InputMapperHelpers.mapKey(m, KeyInput.KEY_RIGHT, controls.moveX.value, true);
		InputMapperHelpers.mapKey(m, KeyInput.KEY_LEFT, controls.moveX.value, false);
		// WASD / ZQSD
		if (InputMapperHelpers.isKeyboardAzerty()) {
			InputMapperHelpers.mapKey(m, KeyInput.KEY_Z, controls.moveZ.value, true);
			InputMapperHelpers.mapKey(m, KeyInput.KEY_S, controls.moveZ.value, false);
			InputMapperHelpers.mapKey(m, KeyInput.KEY_Q, controls.moveX.value, false);
			InputMapperHelpers.mapKey(m, KeyInput.KEY_D, controls.moveX.value, true);
		} else {
			InputMapperHelpers.mapKey(m, KeyInput.KEY_W, controls.moveZ.value, true);
			InputMapperHelpers.mapKey(m, KeyInput.KEY_S, controls.moveZ.value, false);
			InputMapperHelpers.mapKey(m, KeyInput.KEY_A, controls.moveX.value, false);
			InputMapperHelpers.mapKey(m, KeyInput.KEY_D, controls.moveX.value, true);
		}
		// actions
		InputMapperHelpers.mapKey(m, KeyInput.KEY_1, controls.action1.value);
		InputMapperHelpers.mapKey(m, KeyInput.KEY_NUMPAD1, controls.action1.value);
		InputMapperHelpers.mapKey(m, KeyInput.KEY_2, controls.action2.value);
		InputMapperHelpers.mapKey(m, KeyInput.KEY_NUMPAD2, controls.action2.value);
		InputMapperHelpers.mapKey(m, KeyInput.KEY_3, controls.action3.value);
		InputMapperHelpers.mapKey(m, KeyInput.KEY_NUMPAD3, controls.action3.value);
		InputMapperHelpers.mapKey(m, KeyInput.KEY_4, controls.action4.value);
		InputMapperHelpers.mapKey(m, KeyInput.KEY_NUMPAD4, controls.action4.value);
		return m;
	}
}
/**
 * Modules definition use by Main (player/live version)
 *
 * @author David Bernard
 */
@Module(
	injects = {
		Main.class,
	},
	includes = {
		GameSharedModule.class,
	}
)
class GameModule {
	@Singleton
	@Provides
	public AppSettings appSettings(AppSettingsLoader appSettingsLoader, ResourceBundle resources) {
		AppSettings settings = new AppSettings(true);
		try {
			settings = appSettingsLoader.loadInto(settings);
		} catch (Exception e) {
			e.printStackTrace();
		}
		settings.setTitle(resources.getString("title"));
		settings.setUseJoysticks(true);
		settings.setResolution(1280, 720);
		settings.setVSync(true);
		settings.setFullscreen(false);
		settings.setDepthBits(24);
		settings.setCustomRenderer(LwjglDisplayCustom.class);
		return settings;
	}
}

/**
 * Module definition use by Main (dev0 version)
 *
 * @author David Bernard
 */
@Module(
	injects = {
		Main0.class,
	},
	includes = {
		GameSharedModule.class,
	}
)
class Game0Module {
	@Singleton
	@Provides
	public AppSettings appSettings() {
		AppSettings settings = new AppSettings(true);
		settings.setResolution(1280, 720);
		settings.setVSync(false);
		settings.setFullscreen(false);
		settings.setDepthBits(24);
		settings.setCustomRenderer(LwjglDisplayCustom.class);
		settings.setTitle("VDrones Dev");
		return settings;
	}
}