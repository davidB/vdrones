package vdrones;

import javax.inject.Singleton;

import com.jme3.app.Application;
import com.jme3.app.SimpleApplication;
import com.jme3.app.state.AppStateManager;
import com.jme3.asset.AssetManager;
import com.jme3.input.InputManager;
import com.jme3.system.AppSettings;
import com.jme3x.jfx.GuiManager;
import com.jme3x.jfx.cursor.ICursorDisplayProvider;
import com.jme3x.jfx.cursor.proton.ProtonCursorProvider;

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

@Module(library=true, complete=false)
class JmeModule{
	@Provides
	public Application application(SimpleApplication app) {
		return app;
	}

	@Provides
	public AssetManager assetManager(SimpleApplication app) {
		return app.getAssetManager();
	}

	@Provides
	public AppStateManager stateManager(SimpleApplication app) {
		return app.getStateManager();
	}

	@Provides
	public InputManager inputManager(SimpleApplication app) {
		return app.getInputManager();
	}
}

@Module(library=true, complete=false)
class JfxModule {

	@Provides @Singleton
	public ICursorDisplayProvider cursorDisplayProvider(SimpleApplication app) {
		return new ProtonCursorProvider(app, app.getAssetManager(), app.getInputManager());
	}

	@Provides @Singleton
	public GuiManager guiManager(SimpleApplication app, ICursorDisplayProvider c) {
		GuiManager guiManager = new GuiManager(app.getGuiNode(), app.getAssetManager(), app, false, c);
		app.getInputManager().addRawInputListener(guiManager.getInputRedirector());
		return guiManager;
	}
}

/**
 * Modules definition use by Main (player/live version)
 *
 * @author David Bernard
 */
@Module(
	injects = {
		SimpleApplication.class,
		AppStateInGame.class,
	},
	includes = {
		JmeModule.class,
		JfxModule.class
	}
)
class GameModule {
	@Singleton
	@Provides
	public SimpleApplication simpleApplication(AppSettings appSettings) {
		SimpleApplication app = new SimpleApplication(){
			@Override
			public void simpleInitApp() {
			}
		};
		app.setSettings(appSettings());
		app.setShowSettings(true);
		app.setDisplayStatView(false);
		app.setDisplayFps(false);
		app.start();
		return app;
	}

	@Singleton
	@Provides
	public AppSettings appSettings() {
		AppSettings settings = new AppSettings(false);
		settings.setTitle("VDrones");
		//settings.setResolution(640,480);
		//	settings.setRenderer("JOGL");
		//	settings.setRenderer(AppSettings.LWJGL_OPENGL3);
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
	injects = {
		SimpleApplication.class,
		AppStateInGame.class,
	},
	includes = {
		JmeModule.class,
		JfxModule.class
	}
)
class Game0Module {
	@Singleton
	@Provides
	public SimpleApplication simpleApplication(AppSettings appSettings) {
		SimpleApplication app = new SimpleApplication(){
			@Override
			public void simpleInitApp() {
			}
		};
		app.setSettings(appSettings());
		app.setShowSettings(false);
		app.setDisplayStatView(true);
		app.setDisplayFps(true);
		app.start();
		return app;
	}

	@Singleton
	@Provides
	public AppSettings appSettings() {
		AppSettings settings = new AppSettings(true);
		settings.setResolution(1280, 720);
		settings.setVSync(false);
		settings.setFullscreen(false);
		settings.setDepthBits(24);
		//settings.setCustomRenderer(LwjglDisplayCustom.class);
		settings.setTitle("VDrones Dev");
		return settings;
	}

}