package vdrones;

import java.lang.ref.WeakReference;
import java.util.WeakHashMap;

import com.google.inject.AbstractModule;
import com.google.inject.Guice;
import com.google.inject.Injector;
import com.google.inject.Provides;
import com.google.inject.Singleton;
import com.jme3.app.Application;
import com.jme3.app.SimpleApplication;
import com.jme3.asset.AssetManager;
import com.jme3x.jfx.GuiManager;
import com.jme3x.jfx.cursor.ICursorDisplayProvider;
import com.jme3x.jfx.cursor.proton.ProtonCursorProvider;
import com.simsilica.es.EntityData;
import com.simsilica.es.base.DefaultEntityData;

public class Injectors {
	private static final WeakHashMap<Application, Injector> injectors = new WeakHashMap<>();

	public static Injector find(Application app) {
		Injector b = injectors.get(app);
		if (b == null) {
			b = Guice.createInjector(new JmeModule((SimpleApplication) app), new JfxModule(), new GameModule());
			injectors.put(app, b);
		}
		return b;
	}
}

class JmeModule extends AbstractModule {
	private final WeakReference<SimpleApplication> appRef;

	JmeModule(SimpleApplication app) {
		appRef = new WeakReference<SimpleApplication>(app);
	}

	@Override
	protected void configure() {
	}

	@Provides
	public Application application() {
		return appRef.get();
	}

        @Provides
	public SimpleApplication simpleApplication() {
		return appRef.get();
	}

	@Provides
	public AssetManager assetManager(SimpleApplication app) {
		return app.getAssetManager();
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

}