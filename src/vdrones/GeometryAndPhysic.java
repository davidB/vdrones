/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package vdrones;

import lombok.extern.slf4j.Slf4j;

import com.google.inject.Inject;
import com.jme3.app.SimpleApplication;
import com.jme3.bullet.BulletAppState;
import com.jme3.bullet.PhysicsSpace;
import com.jme3.math.Vector3f;
import com.jme3.scene.Node;
import com.jme3.scene.Spatial;

@Slf4j
//@RequiredArgsConstructor(onConstructor=@__(@Inject))
public class GeometryAndPhysic {

	final SimpleApplication app;

	@Inject
	GeometryAndPhysic(SimpleApplication app0) {
		app = app0;
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

    public void add(Spatial e) {
     System.out.println("ADDDDDDDDDDD " + e);
    	addGeo(e);
    	addPhy(e);
    }

    private void addGeo(Spatial e) {
        Node rootNode = app.getRootNode();
    	Node dest = rootNode;
    	String destName = e.getUserData("dest");
    	if (destName != null) {
    		dest = (Node) rootNode.getChild(destName);
    		if (dest == null) {
    			dest = new Node(destName);
    			rootNode.attachChild(dest);
    		}
    	}
    	if (e.getParent() != dest) {
    		dest.attachChild(e);
    	}
    }

    private void addPhy(Spatial e) {
    	BulletAppState bulletAppState = app.getStateManager().getState(BulletAppState.class);
        PhysicsSpace space = bulletAppState.getPhysicsSpace();
    	space.addAll(e);
    }

    void remove(Spatial e) {
    	removePhy(e);
    	e.removeFromParent();
    }

    private void removePhy(Spatial e) {
    	BulletAppState bulletAppState = app.getStateManager().getState(BulletAppState.class);
        PhysicsSpace space = bulletAppState.getPhysicsSpace();
    	space.removeAll(e);
    }
}
