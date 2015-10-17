package vdrones

import com.jme3.bullet.BulletAppState
import com.jme3.bullet.collision.PhysicsCollisionEvent
import com.jme3.bullet.collision.PhysicsCollisionListener
import com.jme3.math.Vector3f
import com.jme3.scene.Spatial
import javax.inject.Inject
import jme3_ext.AppState0

class PhysicsCollisionListenerAll extends AppState0 implements PhysicsCollisionListener {
    var tpf = 0f

    override void collision(PhysicsCollisionEvent event) {
        var InfoDrone drone = null
        var float lt = event.getLifeTime() * tpf
        if ((drone = findDrone(event.getNodeA())) !== null) {
            drone.collisions.onNext(
                new DroneCollisionEvent(new Vector3f(event.getPositionWorldOnA()), lt, event.getNodeB()))
        } else if ((drone = findDrone(event.getNodeB())) !== null) {
            drone.collisions.onNext(
                new DroneCollisionEvent(new Vector3f(event.getPositionWorldOnB()), lt, event.getNodeA()))
        }

    }

    def package InfoDrone findDrone(Spatial n) {
        if(n === null) return null // can be null if getNodeA no longer exists or is no longer a Spatial
        var Object o = n.getUserData(InfoDrone.UD)
        if (o === null && (n.getParent() !== null)) {
            o = n.getParent().getUserData(InfoDrone.UD)
        }
        return o as InfoDrone
    }

    override protected void doInitialize() {
        var BulletAppState bulletAppState = app.getStateManager().getState(BulletAppState)
        if (bulletAppState !== null) {
            bulletAppState.getPhysicsSpace().addCollisionListener(this)
        }

    }

    override protected void doUpdate(float tpf) {
        this.tpf = tpf
    }

    override protected void doDispose() {
        var BulletAppState bulletAppState = app.getStateManager().getState(BulletAppState)
        if (bulletAppState !== null) {
            bulletAppState.getPhysicsSpace().removeCollisionListener(this)
        }

    }

    @Inject
    new(){}
}
