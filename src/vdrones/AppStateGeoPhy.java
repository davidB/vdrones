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
import com.simsilica.es.Entity;
import com.simsilica.es.EntityComponent;
import com.simsilica.es.EntityData;
import com.simsilica.es.EntitySet;
import java.util.List;

/**
 *
 * @author dwayne
 */
class CGeoPhy implements EntityComponent {

    final Spatial geom;
    final List<Object> physics;

    public CGeoPhy(Spatial geom, List<Object> physics) {
        this.geom = geom;
        this.physics = physics;
    }
}

class AppStateGeoPhy extends AbstractAppState {

    EntitySet geophySet;
    Node rootNode;
    final BulletAppState bulletAppState = new BulletAppState();

    @Override
    public void initialize(AppStateManager stateManager, Application app) {
        super.initialize(stateManager, app);
        EntityData ed = ((Main) app).entityData;
        geophySet = ed.getEntities(CGeoPhy.class);
        rootNode = ((Main) app).getRootNode();
        bulletAppState.getPhysicsSpace();
        bulletAppState.setDebugEnabled(true);
    }

    @Override
    public void update(float tpf) {
        super.update(tpf);
        geophySet.applyChanges();
        for (Entity e : geophySet.getRemovedEntities()) {
            System.out.println("remove " + e.getId());
            CGeoPhy c = e.get(CGeoPhy.class);
            c.geom.removeFromParent();
            for (Object o : c.physics) {
                bulletAppState.getPhysicsSpace().remove(o);
            }
        }
        for (Entity e : geophySet.getAddedEntities()) {
            System.out.println("add " + e.getId());
            CGeoPhy c = e.get(CGeoPhy.class);
            rootNode.attachChild(c.geom);
            for (Object o : c.physics) {
                bulletAppState.getPhysicsSpace().add(o);
            }
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
