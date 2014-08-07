package vdrones;

import org.lwjgl.opengl.Display;

import com.google.inject.AbstractModule;
import com.google.inject.Guice;
import com.google.inject.Injector;
import com.google.inject.Provides;
import com.google.inject.Singleton;
import com.jme3.app.Application;
import com.jme3.app.DebugKeysAppState;
import com.jme3.app.FlyCamAppState;
import com.jme3.app.SimpleApplication;
import com.jme3.app.StatsAppState;
import com.jme3.app.state.AppStateManager;
import com.jme3.asset.AssetManager;
import com.jme3.bullet.BulletAppState;
import com.jme3.input.InputManager;
import com.jme3.system.AppSettings;
import com.jme3x.jfx.GuiManager;
import com.jme3x.jfx.cursor.ICursorDisplayProvider;
import com.jme3x.jfx.cursor.proton.ProtonCursorProvider;
import com.simsilica.es.EntityData;
import com.simsilica.es.base.DefaultEntityData;

public class Injectors {
	static final private Injector instance0 = Guice.createInjector(new JmeModule(), new JfxModule(), new GameModule());

	public static Injector find() {
		return instance0;
	}
}

class JmeModule extends AbstractModule {
	@Override
	protected void configure() {
	}

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

class JfxModule extends AbstractModule {

	@Override
	protected void configure() {
	}

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

class GameModule extends AbstractModule {

	@Override
	protected void configure() {
		//bind(LevelLoader.class).asEagerSingleton();
	}

	@Provides @Singleton
	public EntityData entityData() {
		return new DefaultEntityData();
	}

	@Provides @Singleton
	public AppSettings appSettings() {
		AppSettings settings = new AppSettings(true);
		//settings.setResolution(640,480);
		//	settings.setRenderer("JOGL");
		//	settings.setRenderer(AppSettings.LWJGL_OPENGL3);
		return settings;
	}

	@Provides @Singleton
	public SimpleApplication simpleApplication(AppSettings settings) {
		SimpleApplication app = new SimpleApplication(){
			@Override
			public void simpleInitApp() {
				stateManager.detach(stateManager.getState(FlyCamAppState.class));
				stateManager.attach(new StatsAppState());
				stateManager.attach(new DebugKeysAppState());
				//stateManager.attach(new ScreenshotAppState("", System.currentTimeMillis()));
				stateManager.attach(new BulletAppState());
				//stateManager.attach(new AppStatePostProcessing());
				stateManager.attach(new AppStateLights());
				stateManager.attach(new AppStateCamera());
				stateManager.attach(new AppStateGameLogic());
				stateManager.attach(new PhysicsCollisionListenerAll());
				stateManager.attach(new AppStateHudInGame());
			}

			@Override
			public void simpleUpdate(float tpf) {
				if (Display.wasResized()) {
					this.settings.setWidth(Display.getWidth());
					this.settings.setHeight(Display.getHeight());
					this.reshape(this.settings.getWidth(), this.settings.getHeight());
				}
			}

		};
		app.setSettings(settings);
		app.setShowSettings(true);
		app.setDisplayStatView(true);
		app.setDisplayFps(true);
		app.start();
		return app;
	}

	@Provides
	public AppStateCamera appStateCamera(AppStateManager mgr) {
		return mgr.getState(AppStateCamera.class);
	}

}