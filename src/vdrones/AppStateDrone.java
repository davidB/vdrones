/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package vdrones;

import com.jme3.app.Application;
import com.jme3.app.state.AbstractAppState;
import com.jme3.app.state.AppStateManager;
import com.jme3.bullet.control.RigidBodyControl;
import com.jme3.collision.CollisionResult;
import com.jme3.collision.CollisionResults;
import com.jme3.export.JmeExporter;
import com.jme3.export.JmeImporter;
import com.jme3.export.Savable;
import com.jme3.math.Vector3f;
import com.jme3.scene.Spatial;
import java.io.IOException;

/**
 *
 * @author dwayne
 */
class CDroneInfo implements Savable {

    public static String K = "DroneInfo";
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

    @Override
    public void write(JmeExporter ex) throws IOException {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    public void read(JmeImporter im) throws IOException {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }
}

class DroneCfg {

    public float turn = 2.0f;
    public float forward = 50f;
    public float linearDamping = 0.5f;
}

class AppStateDrone extends AbstractAppState {

    private Vector3f dir = new Vector3f(1.0f, 0.0f, 0.0f);
    private Vector3f forward = new Vector3f(1.0f, 0.0f, 0.0f);
    private Vector3f turn = new Vector3f(1.0f, 0.0f, 0.0f);
    private Vector3f gravity = new Vector3f(0.0f, 9.0f, 0.0f);
    public Spatial entity;

    @Override
    public void initialize(AppStateManager stateManager, Application app) {
        super.initialize(stateManager, app);
    }

    @Override
    public void update(float tpf) {
        super.update(tpf);
        if (entity == null || entity.getParent() == null) {
            return;
        }
        CDroneInfo drone = entity.getUserData(CDroneInfo.K);

        RigidBodyControl phy0 = entity.getControl(RigidBodyControl.class);
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

        CollisionResults results = new CollisionResults();
        Spatial area = entity.getParent().getChild("area");
        //gp.geom.collideWith(area, results);
        // Use the results
        if (results.size() > 0) {
            // how to react when a collision was detected
            CollisionResult closest = results.getClosestCollision();
            System.out.println("What was hit? " + closest.getGeometry().getName());
            System.out.println("Where was it hit? " + closest.getContactPoint());
            System.out.println("Distance? " + closest.getDistance());
        } else {
            // how to react when no collision occured
        }
    }
}
