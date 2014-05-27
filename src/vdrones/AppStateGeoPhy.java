/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package vdrones;

import com.jme3.app.Application;
import com.jme3.app.state.AbstractAppState;
import com.jme3.app.state.AppStateManager;
import com.jme3.bullet.BulletAppState;
import com.jme3.scene.Node;
import com.jme3.scene.Spatial;
import java.util.LinkedList;
import java.util.Queue;

class AppStateGeoPhy extends AbstractAppState {

    Node rootNode;
    final BulletAppState bulletAppState = new BulletAppState();
    final Queue<Spatial> toAdd = new LinkedList<>();
    final Queue<Spatial> toRemove = new LinkedList<>();

    @Override
    public void initialize(AppStateManager stateManager, Application app) {
        super.initialize(stateManager, app);
        rootNode = ((Main) app).getRootNode();
        bulletAppState.getPhysicsSpace();
        System.out.println("bulletAppState.getSpeed() : " + bulletAppState.getSpeed());
        //bulletAppState.setSpeed(30); //30 fps
        //bulletAppState.setThreadingType(BulletAppState.ThreadingType.PARALLEL);
        bulletAppState.setDebugEnabled(true);
    }

    @Override
    public void update(float tpf) {
        super.update(tpf);
        for (Spatial e : toRemove) {
            e.removeFromParent();
            bulletAppState.getPhysicsSpace().removeAll(e);
        }
        for (Spatial e : toAdd) {
            rootNode.attachChild(e);
            bulletAppState.getPhysicsSpace().addAll(e);
        }
    }

    @Override
    public void stateAttached(AppStateManager stateManager) {
        super.stateAttached(stateManager);
        stateManager.attach(bulletAppState);
    }

    @Override
    public void stateDetached(AppStateManager stateManager) {
        stateManager.detach(bulletAppState);
        super.stateDetached(stateManager);
    }
}
