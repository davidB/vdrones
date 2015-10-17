/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package vdrones

import com.jme3.app.SimpleApplication
import com.jme3.bullet.BulletAppState
import com.jme3.bullet.PhysicsSpace
import com.jme3.math.Vector3f
import com.jme3.scene.Node
import com.jme3.scene.Spatial
import javax.inject.Inject
import javax.inject.Singleton
import org.slf4j.LoggerFactory

@Singleton
class GeometryAndPhysic {
    val log = LoggerFactory.getLogger(GeometryAndPhysic)
    val subRoot = new Node("subRoot")
    final SimpleApplication app

    @Inject package new(SimpleApplication app0) {
        app = app0
        var BulletAppState bulletAppState = app.getStateManager().getState(BulletAppState)
        if (bulletAppState !== null) {
            log.info("bulletAppState.getSpeed() : {}", bulletAppState.getSpeed())
            log.info("bulletAppState.getPhysicsSpace().getAccuracy() : {}",
                bulletAppState.getPhysicsSpace().getAccuracy())
            log.info("bulletAppState.getPhysicsSpace().getBroadphaseType() : {}",
                bulletAppState.getPhysicsSpace().getBroadphaseType()) // bulletAppState.getPhysicsSpace().setAccuracy(1/60);
            // bulletAppState.getPhysicsSpace().setMaxSubSteps(4);
            // bulletAppState.setSpeed(1); //60 fps
            // bulletAppState.setThreadingType(BulletAppState.ThreadingType.PARALLEL);
            // bulletAppState.setDebugEnabled(true);
            bulletAppState.getPhysicsSpace().setGravity(Vector3f.ZERO)
            bulletAppState.getPhysicsSpace().setAccuracy(0.01f) // bulletAppState.getPhysicsSpace().setBroadphaseType(PhysicsSpace.BroadphaseType.DBVT);
        }
        app.getRootNode().attachChild(subRoot)
    }

    def void add(Spatial e) {
        addGeo(e)
        addPhy(e)
        addLight(e)
    }

    def private void addGeo(Spatial e) {
        var Node dest = subRoot
        var String destName = e.getUserData("dest")
        if (destName !== null) {
            dest = subRoot.getChild(destName) as Node
            if (dest === null) {
                dest = new Node(destName)
                subRoot.attachChild(dest)
            }

        }
        if (e.getParent() !== dest) {
            dest.attachChild(e)
        }

    }

    def private void addPhy(Spatial e) {
        var BulletAppState bulletAppState = app.getStateManager().getState(BulletAppState)
        if (bulletAppState != null) {
            var PhysicsSpace space = bulletAppState.getPhysicsSpace()
            space.addAll(e)
        }
    }

    def private void addLight(Spatial e) {
        // TODO remove deferred		
        // if (e instanceof Geometry){
        // Geometry g = (Geometry)e;
        // if (Helpers4Lights.isLight(g)) {
        // AppStateDeferredRendering r = app.getStateManager().getState(AppStateDeferredRendering.class);
        // if (r != null) {
        // r.olights().add.onNext(g);
        // }
        // }
        // }
    }

    def package void remove(Spatial e) {
        removePhy(e)
        e.removeFromParent()
        removeLight(e)
    }

    def private void removePhy(Spatial e) {
        var BulletAppState bulletAppState = app.getStateManager().getState(BulletAppState)
        if (bulletAppState != null) {
            var PhysicsSpace space = bulletAppState.getPhysicsSpace()
            space.removeAll(e)
        }
    }

    def private void removeLight(Spatial e) {
        // TODO remove deferred		
        // if (e instanceof Geometry){
        // Geometry g = (Geometry)e;
        // if (Helpers4Lights.isLight(g)) {
        // AppStateDeferredRendering r = app.getStateManager().getState(AppStateDeferredRendering.class);
        // if (r != null) {
        // r.olights().remove.onNext(g);
        // }
        // }
        // }
    }

    def removeAll() {
        for(Spatial s: subRoot.getChildren()) {
            remove(s)
	}
    }

}
