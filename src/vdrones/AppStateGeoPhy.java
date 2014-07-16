/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package vdrones;

import java.util.Queue;
import java.util.concurrent.ConcurrentLinkedQueue;

import lombok.extern.slf4j.Slf4j;

import com.jme3.bullet.BulletAppState;
import com.jme3.bullet.PhysicsSpace;
import com.jme3.math.Vector3f;
import com.jme3.scene.Node;
import com.jme3.scene.Spatial;

@Slf4j
public class AppStateGeoPhy extends AppState0 {

    //final BulletAppState bulletAppState = new BulletAppState();
    final Queue<Spatial> toAdd = new ConcurrentLinkedQueue<>();
    final Queue<Spatial> toRemove = new ConcurrentLinkedQueue<>();

    @Override
	protected void doInitialize() {
        BulletAppState bulletAppState = app.getStateManager().getState(BulletAppState.class);
        if (bulletAppState != null) {
            log.info("bulletAppState.getSpeed() : {}", bulletAppState.getSpeed());
            log.info("bulletAppState.getPhysicsSpace().getAccuracy() : {}", bulletAppState.getPhysicsSpace().getAccuracy());
            log.info("bulletAppState.getPhysicsSpace().getBroadphaseType() : {}", bulletAppState.getPhysicsSpace().getBroadphaseType());
            //bulletAppState.getPhysicsSpace().setAccuracy(1/60);
            //bulletAppState.getPhysicsSpace().setMaxSubSteps(4);
            //bulletAppState.setSpeed(1); //60 fps
            //bulletAppState.setThreadingType(BulletAppState.ThreadingType.PARALLEL);
            //bulletAppState.setDebugEnabled(true);
            bulletAppState.getPhysicsSpace().setGravity(Vector3f.ZERO);
            bulletAppState.getPhysicsSpace().setAccuracy(0.01f);
            //bulletAppState.getPhysicsSpace().setBroadphaseType(PhysicsSpace.BroadphaseType.DBVT);
        }
    }

    @Override
	protected void doUpdate(float tpf) {
        try {
        Node rootNode = app.getRootNode();
        toRemove.stream().filter((e) -> !(e == null)).forEach((e) -> {
            e.removeFromParent();
        });
        toAdd.stream().filter((e) -> !(e == null)).forEach((e) -> {
        	Node dest = rootNode;
        	String destName = e.getUserData("dest");
        	if (destName != null) {
        		dest = (Node) rootNode.getChild(destName);
        		if (dest == null) {
        			dest = new Node(destName);
        			rootNode.attachChild(dest);
        		}
        	}
            dest.attachChild(e);
        });

        BulletAppState bulletAppState = app.getStateManager().getState(BulletAppState.class);
        if (bulletAppState != null) {
            PhysicsSpace space = bulletAppState.getPhysicsSpace();
            toRemove.stream().filter((e) -> !(e == null)).forEach((e) -> {
                space.removeAll(e);
            });
            toAdd.stream().filter((e) -> !(e == null)).forEach((e) -> {
                space.addAll(e);
            });
        }

        } catch (Exception exc) {
            log.warn("failed to process toAdd and toRemove", exc);
        } finally {
            toAdd.clear();
            toRemove.clear();
        }
    }

    @Override
    protected void doDispose() {
        toRemove.clear();
        toAdd.clear();
    }
}
