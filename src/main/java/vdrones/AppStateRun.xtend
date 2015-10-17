package vdrones

import com.jme3.app.FlyCamAppState
import com.jme3.app.state.AppStateManager
import com.jme3.bullet.BulletAppState
import javax.inject.Inject
import jme3_ext.AppState0
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

class AppStateRun extends AppState0 {
    final PageLevelSelection pls
    final EntityFactory entityFactory
    final package AppStateCamera appStateCamera
    final package AppStateLights appStateLights
    final package AppStatePostProcessing appStatePostProcessing
    final package PhysicsCollisionListenerAll physicsCollisionListenerAll
    final package AppStateDroneCube appStateDroneCube
    final package AppStateGameLogic appStateGameLogic
    final package AppStateDroneExit appStateDroneExit
    final package AppStateDeferredRendering appStateDeferredRendering
    public val channels = new Channels()

    override protected void doInitialize() {
        channels.areaCfgs.onNext(entityFactory.newLevel(pls.areaSelected))
        var AppStateManager stateManager = app.getStateManager()
        stateManager.detach(stateManager.getState(FlyCamAppState)) // stateManager.attach(new ScreenshotAppState("", System.currentTimeMillis()));
        stateManager.attach(new BulletAppState())
        stateManager.attach(appStateDeferredRendering)
        stateManager.attach(appStatePostProcessing) // stateManager.attach(appStateLights);
        stateManager.attach(appStateCamera)
        stateManager.attach(appStateGameLogic)
        stateManager.attach(physicsCollisionListenerAll)
        stateManager.attach(appStateDroneCube)
        stateManager.attach(appStateDroneExit)
    }

    override protected void doDispose() {
        channels.completed()
        var AppStateManager stateManager = app.getStateManager()
        // stateManager.attach(new ScreenshotAppState("", System.currentTimeMillis()));
        stateManager.detach(stateManager.getState(BulletAppState))
        stateManager.detach(appStateDeferredRendering)
        stateManager.detach(appStatePostProcessing) // stateManager.detach(appStateLights);
        stateManager.detach(appStateCamera)
        stateManager.detach(appStateGameLogic)
        stateManager.detach(physicsCollisionListenerAll)
        stateManager.detach(appStateDroneCube)
        stateManager.detach(appStateDroneExit)
    }

    @Inject
    @FinalFieldsConstructor
    new(){}

}
