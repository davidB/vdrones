package vdrones;

import javax.inject.Inject;

import lombok.RequiredArgsConstructor;

import com.jme3.app.DebugKeysAppState;
import com.jme3.app.FlyCamAppState;
import com.jme3.app.StatsAppState;
import com.jme3.app.state.AppStateManager;
import com.jme3.bullet.BulletAppState;

@RequiredArgsConstructor(onConstructor=@__(@Inject))
public class AppStateInGame extends AppState0{
	final AppStateCamera appStateCamera;
	final AppStateLights appStateLights;
	final AppStatePostProcessing appStatePostProcessing;
	final PhysicsCollisionListenerAll physicsCollisionListenerAll;
	final AppStateDroneCube appStateDroneCube;
	final AppStateHudInGame appStateHudInGame;
	final AppStateGameLogic appStateGameLogic;

	@Override
	protected void doInitialize() {
		AppStateManager stateManager = app.getStateManager();
		stateManager.detach(stateManager.getState(FlyCamAppState.class));
		stateManager.attach(new StatsAppState());
		stateManager.attach(new DebugKeysAppState());
		//stateManager.attach(new ScreenshotAppState("", System.currentTimeMillis()));
		stateManager.attach(new BulletAppState());
		stateManager.attach(appStatePostProcessing);
		stateManager.attach(appStateLights);
		stateManager.attach(appStateCamera);
		stateManager.attach(appStateGameLogic);
		stateManager.attach(physicsCollisionListenerAll);
		stateManager.attach(appStateDroneCube);
		stateManager.attach(appStateHudInGame);
	}

	protected void doDispose() {
		AppStateManager stateManager = app.getStateManager();
		stateManager.detach(stateManager.getState(StatsAppState.class));
		stateManager.detach(stateManager.getState(DebugKeysAppState.class));
		//stateManager.attach(new ScreenshotAppState("", System.currentTimeMillis()));
		stateManager.detach(stateManager.getState(BulletAppState.class));
		stateManager.detach(appStatePostProcessing);
		stateManager.detach(appStateLights);
		stateManager.detach(appStateCamera);
		stateManager.detach(appStateGameLogic);
		stateManager.detach(physicsCollisionListenerAll);
		stateManager.detach(appStateDroneCube);
		stateManager.detach(appStateHudInGame);
	}
}
