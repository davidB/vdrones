/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package vdrones;

import com.jme3.app.Application;
import com.jme3.app.state.AbstractAppState;
import com.jme3.app.state.AppStateManager;
import com.jme3.math.Quaternion;
import com.jme3.math.Vector3f;
import com.jme3.renderer.Camera;
import com.simsilica.es.Entity;
import com.simsilica.es.EntityComponent;
import com.simsilica.es.EntityData;
import com.simsilica.es.EntitySet;
import java.util.Iterator;

class CCameraFollower implements EntityComponent {

    public enum Mode {

        TOP, TPS, FPS
    }
    final Mode mode;
    final Vector3f lookAtOffset = new Vector3f(10.0f, .0f, .0f);
    final Vector3f positionOffset = new Vector3f(-10.0f, 4.0f, 0.0f);
    final Vector3f up = Vector3f.UNIT_Y.clone();

    CCameraFollower(Mode m) {
        mode = m;
        switch (m) {
            case TOP:
                lookAtOffset.set(.0f, .0f, .0f);
                positionOffset.set(0.0f, 80.0f, 0.0f);
                up.set(0.0f, 0.0f, 1.0f);
                break;
            case TPS:
                lookAtOffset.set(10.0f, .0f, .0f);
                positionOffset.set(-10.0f, 4.0f, 0.0f);
                up.set(0.0f, 1.0f, 0.0f);
                break;
            case FPS:
                lookAtOffset.set(10.0f, .0f, .0f);
                positionOffset.set(0.01f, .0f, 0.0f);
                up.set(0.0f, 1.0f, 0.0f);
                break;
        }

    }
}

class AppStateCamera extends AbstractAppState {

    EntitySet targetSet;
    private EntityData ed;
    private Camera camera;
    private Vector3f v0 = new Vector3f(0, 0, 0);

    @Override
    public void initialize(AppStateManager stateManager, Application app) {
        super.initialize(stateManager, app);
        ed = ((Main) app).entityData;
        targetSet = ed.getEntities(CCameraFollower.class, CGeoPhy.class);
        camera = app.getCamera();
    }

    @Override
    public void update(float tpf) {
        super.update(tpf);
        targetSet.applyChanges();
        //take care only of the first
        Iterator<Entity> it = targetSet.iterator();
        if (it.hasNext()) {
            Entity e = it.next();
            CGeoPhy gp = e.get(CGeoPhy.class);
            CCameraFollower follower = e.get(CCameraFollower.class);
            float step = Math.min(1.0f, tpf * 4.0f);
            offsetPosition(v0, follower.positionOffset, gp.geom.getWorldTranslation(), gp.geom.getWorldRotation());
            camera.setLocation(approachMulti(v0, camera.getLocation(), step));
            // TODO approachMulti on v0
            offsetPosition(v0, follower.lookAtOffset, gp.geom.getWorldTranslation(), gp.geom.getWorldRotation());
            camera.lookAt(v0, follower.up);
        }
    }

    private float approachMulti(float target, float current, float step) {
        float mstep = target - current;
        return current + step * mstep;
    }

    private Vector3f approachMulti(Vector3f target, Vector3f current, float step) {
        target.x = approachMulti(target.x, current.x, step);
        target.y = approachMulti(target.y, current.y, step);
        target.z = approachMulti(target.z, current.z, step);
        return target;
    }

    private Vector3f offsetPosition(Vector3f out, Vector3f offset, Vector3f targetPosition, Quaternion targetRotation) {
        out.set(offset);
        targetRotation.multLocal(out);
        out.addLocal(targetPosition);
        return out;
    }
}
