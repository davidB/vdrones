package vdrones;

import java.util.LinkedList;
import java.util.List;

import javax.inject.Inject;

import lombok.RequiredArgsConstructor;
import rx.Subscription;
import rx.subscriptions.Subscriptions;

import com.jme3.bullet.control.RigidBodyControl;
import com.jme3.math.Vector3f;

@RequiredArgsConstructor(onConstructor=@__(@Inject))
public class AppStateDroneCube extends AppState0 {
	private final List<InfoDrone> drones = new LinkedList<>();
	private final List<InfoCube> cubes = new LinkedList<>();
	private Subscription subs;
	final Channels channels;

	@Override
	protected void doEnable(){
		subs = Subscriptions.from(
			channels.drones.flatMap(v -> v.state.map(s -> new T2<InfoDrone, Boolean>(v, s == InfoDrone.State.driving)).distinctUntilChanged()).subscribe(v -> {
				if (v._2) {
					drones.add(v._1);
				} else {
					drones.remove(v._1);
				}
			})
			, channels.cubes.flatMap(v -> v.state.map(s -> new T2<InfoCube, Boolean>(v, s == InfoCube.State.waiting)).distinctUntilChanged()).subscribe(v -> {
				if (v._2) {
					cubes.add(v._1);
				} else {
					cubes.remove(v._1);
				}
			})
		);
	};

	@Override
	protected void doDisable(){
		if (subs != null) {
			subs.unsubscribe();
			subs = null;
		}
	};

	@Override
	protected void doUpdate(float tpf) {
		Vector3f dc = new Vector3f();
		boolean forceA = false;
		Vector3f force = new Vector3f();
		for(InfoCube cube : cubes){
			boolean grabbed = false;
			RigidBodyControl body = cube.node.getControl(RigidBodyControl.class);
			body.clearForces();
			for(InfoDrone drone : drones){
				drone.node.getWorldTranslation().subtract(cube.node.getWorldTranslation(), dc);
				float dcLg = dc.length();
				if (dcLg <= drone.cfg.grabRadius) {
					drone.scoreReq.onNext(1);
					grabbed = true;
					break;
				} else if (dcLg <= drone.cfg.attractorRadius) {
					force.addLocal(dc.multLocal(drone.cfg.attractorRadius/dcLg));
					forceA = true;
				}
			}
			if (grabbed) {
				// remove from the active list to avoid redo test until state change is propagated
				cubes.remove(cube);
				cube.stateReq.onNext(InfoCube.State.grabbed);
			}
			if (forceA){
				force.y = 0;
				body.applyForce(force, Vector3f.ZERO);
			}
		}
	}
}
