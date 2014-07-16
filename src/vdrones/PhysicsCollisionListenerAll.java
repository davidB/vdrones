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
		DroneInfo2 drone = findDrone(event.getNodeA());
		float lt = event.getLifeTime() * tpf;
		if (drone != null) {
			drone.wallCollisions.onNext(new DroneCollisionEvent(new Vector3f(event.getPositionWorldOnA()), lt));
		} else {
			drone = findDrone(event.getNodeB());
			if (drone != null) {
				drone.wallCollisions.onNext(new DroneCollisionEvent(new Vector3f(event.getPositionWorldOnB()), lt));
			}
		}
	}

	DroneInfo2 findDrone(Spatial n) {
		Object o = n.getUserData(DroneInfo2.UD);
		return (DroneInfo2)((o == null) ? n.getParent().getUserData(DroneInfo2.UD) : o);
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
