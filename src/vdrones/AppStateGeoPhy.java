/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package vdrones;

import com.jme3.app.Application;
import com.jme3.app.SimpleApplication;
import com.jme3.app.state.AbstractAppState;
import com.jme3.app.state.AppStateManager;
import com.jme3.bullet.BulletAppState;
import com.jme3.math.Vector3f;
import com.jme3.scene.Node;
import com.jme3.scene.Spatial;
import java.util.LinkedList;
import java.util.Queue;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class AppStateGeoPhy extends AbstractAppState {

    //final BulletAppState bulletAppState = new BulletAppState();
    final Queue<Spatial> toAdd = new LinkedList<>();
    final Queue<Spatial> toRemove = new LinkedList<>();
    private SimpleApplication sapp;

    @Override
    public void initialize(AppStateManager stateManager, Application app) {
        super.initialize(stateManager, app);
        sapp = (SimpleApplication)app;
        BulletAppState bulletAppState = sapp.getStateManager().getState(BulletAppState.class);
        if (bulletAppState != null) {
            log.info("bulletAppState.getSpeed() : {}", bulletAppState.getSpeed());
            log.info("bulletAppState.getPhysicsSpace().getAccuracy() : {}", bulletAppState.getPhysicsSpace().getAccuracy());
            //bulletAppState.getPhysicsSpace().setAccuracy(1/60);
            //bulletAppState.getPhysicsSpace().setMaxSubSteps(4);
            //bulletAppState.setSpeed(1); //60 fps
            //bulletAppState.setThreadingType(BulletAppState.ThreadingType.PARALLEL);
            //bulletAppState.setDebugEnabled(true);
        }
    }

    @Override
    public void update(float tpf) {
        try {
        super.update(tpf);
        Node rootNode = sapp.getRootNode();
        for (Spatial e : toRemove) {
            if (e == null) continue;
            e.removeFromParent();
        }
        for (Spatial e : toAdd) {
            if (e == null) continue;
            rootNode.attachChild(e);
        }

        BulletAppState bulletAppState = sapp.getStateManager().getState(BulletAppState.class);
        if (bulletAppState != null) {
            for (Spatial e : toRemove) {
                if (e == null) continue;
                bulletAppState.getPhysicsSpace().removeAll(e);
            }
            toRemove.clear();
            for (Spatial e : toAdd) {
                if (e == null) continue;
                bulletAppState.getPhysicsSpace().addAll(e);
            }
        }
        
        } catch (Exception exc) {
            log.warn("failed to process toAdd and toRemove", exc);
        } finally {
            toAdd.clear();
            toRemove.clear();
        }
    }

    @Override
    public void cleanup() {
        toRemove.clear();
        toAdd.clear();
        super.cleanup();
    }
}
