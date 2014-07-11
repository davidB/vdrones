package vdrones;

import org.lwjgl.opengl.Display;

import rx.Subscription;
import rx.subscriptions.Subscriptions;

import com.google.inject.Injector;
import com.jme3.app.Application;
import com.jme3.app.DebugKeysAppState;
import com.jme3.app.FlyCamAppState;
import com.jme3.app.SimpleApplication;
import com.jme3.app.StatsAppState;
import com.jme3.bullet.BulletAppState;
import com.jme3.math.ColorRGBA;
import com.jme3.renderer.RenderManager;
import com.jme3.scene.Spatial;

/**
 * test
 */
public class Main extends SimpleApplication {
	private static boolean assertionsEnabled;
	private static boolean enabled() {
		Main.assertionsEnabled = true;
		return true;
	}

	//@SuppressWarnings("AssertWithSideEffects")
	public static void main(final String[] args) {
		assert Main.enabled();
		if (!Main.assertionsEnabled) {
			throw new RuntimeException("Assertions must be enabled (vm args -ea");
		}
		Main app = new Main();
		app.start();
	}

	private boolean postinit = false;

	public Main() {
	}

	@Override
	public void simpleInitApp() {
		//setDisplayStatView(true);
		//setDisplayFps(true);
		//flyCam.setEnabled(false);

		stateManager.detach(stateManager.getState(FlyCamAppState.class));
		stateManager.attach(new StatsAppState());
		stateManager.attach(new DebugKeysAppState());
		//stateManager.attach(new ScreenshotAppState("", System.currentTimeMillis()));
		stateManager.attach(new BulletAppState());
		//stateManager.attach(new AppStatePostProcessing());
		stateManager.attach(new AppStateLights());
		stateManager.attach(new AppStateCamera());
		stateManager.attach(new AppStateGameLogic());
		stateManager.attach(new AppStateGeoPhy());
		stateManager.attach(new AppStateHudInGame());

		setDebug(false);
	}

	@Override
	public void simpleUpdate(float tpf) {
		if (Display.wasResized()) {
			this.settings.setWidth(Display.getWidth());
			this.settings.setHeight(Display.getHeight());
			this.reshape(this.settings.getWidth(), this.settings.getHeight());
		}
		if (!postinit ) {
			postinit = true;
			pipeAll();
			//inputManager.setCursorVisible(true);
			//spawnLevel("area0");
		}
	}

	public Subscription pipeAll(){
		Injector injector = Injectors.find(this);
		LevelLoader ll = injector.getInstance(LevelLoader.class);
		Channels channels = injector.getInstance(Channels.class);
		;
		return Subscriptions.from(
			Pipes.pipe(ll, injector.getInstance(Application.class).getStateManager().getState(AppStateGeoPhy.class))
			, Pipes.pipe(ll, injector.getInstance(Application.class).getStateManager().getState(AppStateLights.class))
			, channels.droneInfo2s.subscribe(v -> Pipes.pipe(injector.getInstance(Application.class).getInputManager(), v))
			//, channels.droneInfo2s.subscribe(v -> spawnDrone(v))
		);
	}

	public void spawnLevel(String name) {
		Injector injector = Injectors.find(this);
		EntityFactory efactory = injector.getInstance(EntityFactory.class);
		LevelLoader ll = injector.getInstance(LevelLoader.class);
		ll.loadLevel(efactory.newLevel(name), true);
	}

	public Spatial spawnDrone(DroneInfo2 d) {
		Injector injector = Injectors.find(this);
		EntityFactory efactory = injector.getInstance(EntityFactory.class);
		Spatial vd = efactory.newDrone();
		Pipes.pipe(d, vd.getControl(ControlDronePhy.class));
		stateManager.getState(AppStateCamera.class).target = vd;
		stateManager.getState(AppStateCamera.class).follower = new CameraFollower(CameraFollower.Mode.TPS);
		stateManager.getState(AppStateGeoPhy.class).toAdd.offer(vd);
		return vd;
	}

	@Override
	public void simpleRender(RenderManager rm) {
	}

	void setDebug(boolean v) {
		stateManager.getState(BulletAppState.class).setDebugEnabled(v);
		inputManager.setCursorVisible(v);
		viewPort.setBackgroundColor(v? ColorRGBA.Pink : ColorRGBA.White);
		Display.setResizable(v);
	}
}
