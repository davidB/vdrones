/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package vdrones;

import com.jme3.app.Application;
import com.jme3.app.state.AbstractAppState;
import com.jme3.app.state.AppStateManager;
import com.jme3.bullet.control.RigidBodyControl;
import com.jme3.math.Vector3f;
import com.simsilica.es.Entity;
import com.simsilica.es.EntityComponent;
import com.simsilica.es.EntityData;
import com.simsilica.es.EntitySet;
import java.util.Iterator;

/**
 *
 * @author dwayne
 */
class CDroneInfo implements EntityComponent {

    public float turn = 0f;
    public float forward = 0f;
    public DroneCfg cfg;

    CDroneInfo() {
        this(true);
    }

    private CDroneInfo(boolean createCfg) {
        if (createCfg) {
            cfg = new DroneCfg();
        }
    }

    CDroneInfo copy() {
        CDroneInfo b = new CDroneInfo(false);
        b.cfg = cfg;
        b.turn = turn;
        b.forward = forward;
        return b;
    }
}

class DroneCfg {

    public float turn = 2.0f;
    public float forward = 50f;
    public float linearDamping = 0.5f;
}

class AppStateDrone extends AbstractAppState {

    private EntitySet droneSet;
    private EntityData ed;
    private Vector3f dir = new Vector3f(1.0f, 0.0f, 0.0f);
    private Vector3f forward = new Vector3f(1.0f, 0.0f, 0.0f);
    private Vector3f turn = new Vector3f(1.0f, 0.0f, 0.0f);
    private Vector3f gravity = new Vector3f(0.0f, 9.0f, 0.0f);

    @Override
    public void initialize(AppStateManager stateManager, Application app) {
        super.initialize(stateManager, app);
        ed = ((Main) app).entityData;
        droneSet = ed.getEntities(CDroneInfo.class, CGeoPhy.class);
    }

    @Override
    public void update(float tpf) {
        super.update(tpf);
        droneSet.applyChanges();
        //for (Entity e : droneSet.getChangedEntities()) {
        Iterator<Entity> it = droneSet.iterator();
        while (it.hasNext()) {
            Entity e = it.next();
            CDroneInfo drone = e.get(CDroneInfo.class);
            CGeoPhy gp = e.get(CGeoPhy.class);
            RigidBodyControl phy0 = ((RigidBodyControl) gp.physics.get(0));

            dir.set(1.0f, 0.0f, 0.0f);
            //gp.geom.getWorldRotation().multLocal(dir);
            phy0.getPhysicsRotation().multLocal(dir);
            dir.normalizeLocal();
            forward.set(dir).multLocal(drone.forward * drone.cfg.forward);
            turn.set(0.0f, drone.turn * drone.cfg.turn, 0.0f);
            phy0.applyCentralForce(forward);
            float dist = 0.0f - phy0.getPhysicsLocation().y;
            if (dist > 1.0) {
                dist = 1.0f;
            }
            if (dist < -1.0) {
                dist = -1.0f;
            }
            gravity.set(0.0f, /*9.0f * phy0.getMass()*/ 9.0f * dist, 0.0f);
            phy0.setGravity(gravity);
            phy0.setLinearDamping(drone.cfg.linearDamping);
            phy0.setAngularVelocity(turn);
        }
    }
}
