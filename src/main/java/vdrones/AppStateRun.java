package vdrones;

import javax.inject.Inject;

import jme3_ext.AppState0;
import lombok.RequiredArgsConstructor;

import com.jme3.app.FlyCamAppState;
import com.jme3.app.state.AppStateManager;
import com.jme3.bullet.BulletAppState;

@RequiredArgsConstructor(onConstructor=@__(@Inject))
public class AppStateRun extends AppState0{
	final AppStateCamera appStateCamera;
	final AppStateLights appStateLights;
	final AppStatePostProcessing appStatePostProcessing;
	final PhysicsCollisionListenerAll physicsCollisionListenerAll;
	final AppStateDroneCube appStateDroneCube;
	final AppStateGameLogic appStateGameLogic;
	final AppStateDroneExit appStateDroneExit;
	final AppStateDeferredRendering appStateDeferredRendering;

	@Override
	protected void doInitialize() {
		AppStateManager stateManager = app.getStateManager();
		stateManager.detach(stateManager.getState(FlyCamAppState.class));
		//stateManager.attach(new ScreenshotAppState("", System.currentTimeMillis()));
		stateManager.attach(new BulletAppState());
		stateManager.attach(appStateDeferredRendering);
		stateManager.attach(appStatePostProcessing);
		//stateManager.attach(appStateLights);
		stateManager.attach(appStateCamera);
		stateManager.attach(appStateGameLogic);
		stateManager.attach(physicsCollisionListenerAll);
		stateManager.attach(appStateDroneCube);
		stateManager.attach(appStateDroneExit);
	}

	protected void doDispose() {
		AppStateManager stateManager = app.getStateManager();
		//stateManager.attach(new ScreenshotAppState("", System.currentTimeMillis()));
		stateManager.detach(stateManager.getState(BulletAppState.class));
		stateManager.detach(appStateDeferredRendering);
		stateManager.detach(appStatePostProcessing);
		//stateManager.detach(appStateLights);
		stateManager.detach(appStateCamera);
		stateManager.detach(appStateGameLogic);
		stateManager.detach(physicsCollisionListenerAll);
		stateManager.detach(appStateDroneCube);
		stateManager.detach(appStateDroneExit);
	}
}
