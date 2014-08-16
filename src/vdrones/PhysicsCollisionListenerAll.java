package vdrones;

import com.jme3.bullet.BulletAppState;
import com.jme3.bullet.collision.PhysicsCollisionEvent;
import com.jme3.bullet.collision.PhysicsCollisionListener;
import com.jme3.math.Vector3f;
import com.jme3.scene.Spatial;

public class PhysicsCollisionListenerAll extends AppState0 implements PhysicsCollisionListener {
	Channels channels;

	private float tpf;

	@Override
	public void collision(PhysicsCollisionEvent event) {
		InfoDrone drone = findDrone(event.getNodeA());
		float lt = event.getLifeTime() * tpf;
		if (drone != null) {
			drone.collisions.onNext(new DroneCollisionEvent(new Vector3f(event.getPositionWorldOnA()), lt, event.getNodeB()));
		} else {
			drone = findDrone(event.getNodeB());
			if (drone != null) {
				drone.collisions.onNext(new DroneCollisionEvent(new Vector3f(event.getPositionWorldOnB()), lt, event.getNodeA()));
			}
		}
	}

	InfoDrone findDrone(Spatial n) {
		if (n == null) return null; // can be null if getNodeA no longer exists or is no longer a Spatial
		Object o = n.getUserData(InfoDrone.UD);
		if (o == null && (n.getParent() != null)) {
			o = n.getParent().getUserData(InfoDrone.UD);
		}
		return (InfoDrone)o;
	}

	@Override
	protected void doInitialize() {
		channels = injector.getInstance(Channels.class);
        BulletAppState bulletAppState = app.getStateManager().getState(BulletAppState.class);
        if (bulletAppState != null) {
            bulletAppState.getPhysicsSpace().addCollisionListener(this);
        }
    }

    @Override
	protected void doUpdate(float tpf) {
    	this.tpf = tpf;
    }

    @Override
    protected void doDispose() {
    	BulletAppState bulletAppState = app.getStateManager().getState(BulletAppState.class);
    	if (bulletAppState != null) {
    		bulletAppState.getPhysicsSpace().removeCollisionListener(this);
    	}
    }

}
