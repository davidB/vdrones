package vdrones;

import java.util.concurrent.TimeUnit;

import org.lwjgl.opengl.Display;

import rx.Observable;
import rx.Subscription;
import rx.subjects.BehaviorSubject;
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
import com.jme3.scene.Node;
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

	private boolean postInit;

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
		stateManager.attach(new PhysicsCollisionListenerAll());
		stateManager.attach(new AppStateHudInGame());

		pipeAll();
		setDebug(true);
		postInit = false;
	}

	@Override
	public void simpleUpdate(float tpf) {
		if (Display.wasResized()) {
			this.settings.setWidth(Display.getWidth());
			this.settings.setHeight(Display.getHeight());
			this.reshape(this.settings.getWidth(), this.settings.getHeight());
		}
		if (!postInit) {
			postInit = true;
			spawnLevel("area0");
		}
	}

	public Subscription pipeAll(){
		Injector injector = Injectors.find(this);
		//LevelLoader ll = injector.getInstance(LevelLoader.class);
		Channels channels = injector.getInstance(Channels.class);

		return Subscriptions.from(
			Pipes.pipeA(channels.areaCfgs, injector.getInstance(Application.class).getStateManager().getState(AppStateGeoPhy.class), injector)
			, Pipes.pipe(channels.areaCfgs, injector.getInstance(Application.class).getStateManager().getState(AppStateLights.class))
			, Pipes.pipe(channels.drones.map(DroneInfo2::from), injector.getInstance(Application.class).getInputManager())
			, Pipes.pipeD(channels.drones, injector.getInstance(Application.class).getStateManager().getState(AppStateGeoPhy.class), injector)
			//, channels.droneInfo2s.subscribe(v -> spawnDrone(v))
			,channels.areaCfgs.subscribe(new ObserverPrint<AreaCfg>("channels.areaCfgs"))
			,channels.drones.subscribe(new ObserverPrint<Node>("channels.drones"))
		);
	}

	//FIXME remove delay to display, the delay is caused by missing callback when application is initialized
	public void spawnLevel(String name) {
		Injector injector = Injectors.find(this);
		EntityFactory efactory = injector.getInstance(EntityFactory.class);
		Channels channels = injector.getInstance(Channels.class);
		//Observable.just(efactory.newLevel(name)).delay(500, TimeUnit.MILLISECONDS).subscribe(channels.areaCfgs);
		channels.areaCfgs.onNext(efactory.newLevel("area0"));
	}
//
//	public Spatial spawnDrone(DroneInfo2 d) {
//		Injector injector = Injectors.find(this);
//		EntityFactory efactory = injector.getInstance(EntityFactory.class);
//		Spatial vd = efactory.newDrone();
//		Pipes.pipe(d, vd.getControl(ControlDronePhy.class));
//		stateManager.getState(AppStateCamera.class).setCameraFollower(new CameraFollower(CameraFollower.Mode.TPS, vd));
//		stateManager.getState(AppStateGeoPhy.class).toAdd.offer(vd);
//		return vd;
//	}

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
