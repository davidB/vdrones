package vdrones;

import javax.inject.Inject;

import lombok.RequiredArgsConstructor;

import com.jme3.app.SimpleApplication;
import com.jme3.collision.CollisionResult;
import com.jme3.collision.CollisionResults;
import com.jme3.math.Quaternion;
import com.jme3.math.Ray;
import com.jme3.math.Vector3f;
import com.jme3.renderer.Camera;
import com.jme3.scene.Node;
import com.jme3.scene.Spatial;

class CameraFollower{

    public enum Mode {
        TOP, TPS, FPS
    }

    final Mode mode;
    final Vector3f lookAtOffset = new Vector3f(10.0f, .0f, .0f);
    final Vector3f positionOffset = new Vector3f(-10.0f, 4.0f, 0.0f);
    final Vector3f up = Vector3f.UNIT_Y.clone();
    final Spatial target;

    CameraFollower(Mode mode, Spatial target) {
    	this.target = target;
        this.mode = mode;
        switch (mode) {
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

@RequiredArgsConstructor(onConstructor=@__(@Inject))
class AppStateCamera extends AppState0 {

    private Camera camera;
    private final Vector3f v0 = new Vector3f(0, 0, 0);
    private CameraFollower follower;
    private Node rootNode;

    public void setCameraFollower(CameraFollower follower){
    	this.follower = follower;
        if (follower == null || follower.target == null) {
        	setEnabled(false);
        } else {
        	setEnabled(true);
        }
    }

    @Override
    public void doInitialize() {
        camera = app.getCamera();
        rootNode = ((SimpleApplication) app).getRootNode();
        setEnabled(false);
    }

    @Override
    public void doUpdate(float tpf) {
        Spatial target = follower.target;
        float step = Math.min(1.0f, tpf * 4.0f);
        offsetPosition(v0, follower.positionOffset, target.getWorldTranslation(), target.getWorldRotation(), true);
        camera.setLocation(approachMulti(v0, camera.getLocation(), step));
        // TODO approachMulti on v0
        offsetPosition(v0, follower.lookAtOffset, target.getWorldTranslation(), target.getWorldRotation(), false);
        camera.lookAt(v0, follower.up);
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

    private Vector3f offsetPosition(Vector3f out, Vector3f offset, Vector3f targetPosition, Quaternion targetRotation, boolean nearest) {
        out.set(offset);
        targetRotation.multLocal(out);
        targetRotation.mult(Vector3f.UNIT_X);
        if (nearest) {
            Spatial area = rootNode.getChild(EntityFactory.LevelName);
            if (area != null) {
                CollisionResults results = new CollisionResults();
                //FIXME: create tmp vec3
                Ray ray = new Ray(targetPosition, out.normalize());
                area.collideWith(ray, results);
                if (results.size() > 0) {
                    CollisionResult closest = results.getClosestCollision();
                    float distance = closest.getDistance();
                    if ((distance * distance) < offset.lengthSquared()) {
                        out.set(closest.getContactPoint()).subtractLocal(targetPosition);
                    }
                }
            }
        }
        out.addLocal(targetPosition);
        return out;
    }

}
