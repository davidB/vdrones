/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package vdrones;

import com.jme3.bullet.control.RigidBodyControl;
import com.jme3.math.Vector3f;
import com.jme3.renderer.RenderManager;
import com.jme3.renderer.ViewPort;
import com.jme3.scene.Spatial;
import com.jme3.scene.control.AbstractControl;

class ControlDronePhy extends AbstractControl {

    private Vector3f dir = new Vector3f(1.0f, 0.0f, 0.0f);
    private Vector3f forward = new Vector3f(1.0f, 0.0f, 0.0f);
    private Vector3f turn = new Vector3f(1.0f, 0.0f, 0.0f);
    private Vector3f gravity = new Vector3f(0.0f, 9.0f, 0.0f);

    float turnLg = 0f;
    float forwardLg = 0f;
    float linearDamping = 0f;

    @Override
	protected void controlUpdate(float tpf) {
    	//System.out.println(this + " forwardLg : " + forwardLg);
        RigidBodyControl phy0 = spatial.getControl(RigidBodyControl.class);
        dir.set(1.0f, 0.0f, 0.0f);
        //gp.geom.getWorldRotation().multLocal(dir);
        phy0.getPhysicsRotation().multLocal(dir);
        dir.y = 0f;
        dir.normalizeLocal();
        forward.set(dir).multLocal(forwardLg);
        turn.set(0.0f, turnLg, 0.0f);
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
        phy0.setLinearDamping(linearDamping);
        phy0.setAngularVelocity(turn);

//        CollisionResults results = new CollisionResults();
//        //Spatial area = entity.getParent().getChild("area");
//        //gp.geom.collideWith(area, results);
//        // Use the results
//        if (results.size() > 0) {
//            // how to react when a collision was detected
//            CollisionResult closest = results.getClosestCollision();
//            System.out.println("What was hit? " + closest.getGeometry().getName());
//            System.out.println("Where was it hit? " + closest.getContactPoint());
//            System.out.println("Distance? " + closest.getDistance());
//        } else {
//            // how to react when no collision occured
//        }
    }

	@Override
	protected void controlRender(RenderManager rm, ViewPort vp) {
	}

}
