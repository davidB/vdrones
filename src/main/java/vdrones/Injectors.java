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
import rx.subjects.PublishSubject;
import vdrones.garage.PageGarage;
import vdrones.settings.Commands;
import vdrones.settings.PageSettings;

import com.jme3.app.SimpleApplication;
import com.jme3.asset.AssetManager;
import com.jme3.input.KeyInput;
import com.jme3.system.AppSettings;
import com.jme3x.jfx.FxPlatformExecutor;

import dagger.Module;
import dagger.Provides;

//public class Injectors {
//	//static final private Injector instance0 = Guice.createInjector(new JmeModule(), new JfxModule(), new GameModule());
//	static final private ObjectGraph instance0 = ObjectGraph.create(new GameModule());
//
////	public static ObjectGraph find() {
////		return instance0;
////	}
//}

//@Module(library=true, complete=false)
//class JmeModule{
//	@Provides
//	public Application application(SimpleApplication app) {
//		return app;
//	}
//
//	@Provides
//	public AssetManager assetManager(SimpleApplication app) {
//		return app.getAssetManager();
//	}
//
//	@Provides
//	public AppStateManager stateManager(SimpleApplication app) {
//		return app.getStateManager();
//	}
//
//	@Provides
//	public InputManager inputManager(SimpleApplication app) {
//		return app.getInputManager();
//	}
//}

@Module()
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
//	@Singleton
//	@Provides
//	public PageManager pageManager(SimpleApplication app) {
//		AppState[] pages = new AppState[Pages.values().length];
//		//pages[Pages.Welcome.ordinal()] = pageWelcome;
//		//pages[Pages.Run.ordinal()] = pageRun;
//		//pages[Pages.Settings.ordinal()] = pageSettings;
//		//pages[Pages.Garage.ordinal()] = pageGarage;
//		PageManager pageManager = new PageManager(app.getStateManager(), pages);
//		return pageManager;
//	}
	@Singleton
	@Provides
	//@Named("pageRequests")
	public PublishSubject<Pages> pageRequests() {
		return PublishSubject.create();
	}

	
	@Singleton
	@Provides
	public PageManager<Pages> pageManager(SimpleApplication app, PublishSubject<Pages> pageRequests, PageWelcome pageWelcome, PageSettings pageSettings, PageGarage pageGarage, PageRun pageRun) {
		PageManager<Pages> pageManager = new PageManager<>(app.getStateManager());
		pageManager.pages.put(Pages.Welcome, pageWelcome);
		pageManager.pages.put(Pages.Run, pageRun);
		pageManager.pages.put(Pages.Settings, pageSettings);
		pageManager.pages.put(Pages.Garage, pageGarage);
		pageRequests.subscribe((p) -> pageManager.goTo(p));
		return pageManager;
	}

	@Singleton
	@Provides
	public Locale locale() {
		return Locale.getDefault();
	}

	@Provides
	public ResourceBundle resources(Locale locale) {
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
		settings.setGammaCorrection(true);
		settings.setRenderer(AppSettings.LWJGL_OPENGL3); // settings.setCustomRenderer(LwjglDisplayCustom.class);
		return settings;
	}
//
//	@Provides
//	public AppStateCamera appStateCamera(AppStateManager mgr) {
//		return mgr.getState(AppStateCamera.class);
//	}

}

/**
 * Module definition use by Main (dev0 version)
 *
 * @author David Bernard
 */
@Module(
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
		settings.setGammaCorrection(true);
		settings.setRenderer(AppSettings.LWJGL_OPENGL3); // settings.setCustomRenderer(LwjglDisplayCustom.class);
		settings.setTitle("VDrones Dev");
		return settings;
	}
}