/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package vdrones;

import javax.inject.Inject;
import javax.inject.Singleton;

import jme3_ext_deferred.Helpers4Lights;
import lombok.extern.slf4j.Slf4j;

import com.jme3.app.SimpleApplication;
import com.jme3.bullet.BulletAppState;
import com.jme3.bullet.PhysicsSpace;
import com.jme3.math.Vector3f;
import com.jme3.scene.Geometry;
import com.jme3.scene.Node;
import com.jme3.scene.Spatial;

@Slf4j
//@RequiredArgsConstructor(onConstructor=@__(@Inject))
@Singleton
public class GeometryAndPhysic {

	final SimpleApplication app;
	final Node subRoot = new Node("subRoot");

	@Inject
	public GeometryAndPhysic(SimpleApplication app0) {
		app = app0;
		BulletAppState bulletAppState = app.getStateManager().getState(BulletAppState.class);
		if (bulletAppState != null) {
			log.info("bulletAppState.getSpeed() : {}", bulletAppState.getSpeed());
			log.info("bulletAppState.getPhysicsSpace().getAccuracy() : {}", bulletAppState.getPhysicsSpace().getAccuracy());
			log.info("bulletAppState.getPhysicsSpace().getBroadphaseType() : {}", bulletAppState.getPhysicsSpace().getBroadphaseType());
			//bulletAppState.getPhysicsSpace().setAccuracy(1/60);
			//bulletAppState.getPhysicsSpace().setMaxSubSteps(4);
			//bulletAppState.setSpeed(1); //60 fps
			//bulletAppState.setThreadingType(BulletAppState.ThreadingType.PARALLEL);
			//bulletAppState.setDebugEnabled(true);
			bulletAppState.getPhysicsSpace().setGravity(Vector3f.ZERO);
			bulletAppState.getPhysicsSpace().setAccuracy(0.01f);
			//bulletAppState.getPhysicsSpace().setBroadphaseType(PhysicsSpace.BroadphaseType.DBVT);
		}
		app.getRootNode().attachChild(subRoot);
	}

	public void add(Spatial e) {
		addGeo(e);
		addPhy(e);
		addLight(e);
	}

	private void addGeo(Spatial e) {
		Node dest = subRoot;
		String destName = e.getUserData("dest");
		if (destName != null) {
			dest = (Node) subRoot.getChild(destName);
			if (dest == null) {
				dest = new Node(destName);
				subRoot.attachChild(dest);
			}
		}
		if (e.getParent() != dest) {
			dest.attachChild(e);
		}
	}

	private void addPhy(Spatial e) {
		BulletAppState bulletAppState = app.getStateManager().getState(BulletAppState.class);
		if (bulletAppState != null) {
			PhysicsSpace space = bulletAppState.getPhysicsSpace();
			space.addAll(e);
		}
	}

	private void addLight(Spatial e) {
		if (e instanceof Geometry){
			Geometry g = (Geometry)e;
			if (Helpers4Lights.isLight(g)) {
				System.out.println("found lights:" + g);
				AppStateDeferredRendering r = app.getStateManager().getState(AppStateDeferredRendering.class);
				if (r != null) {
					r.olights().add.onNext(g);
				}
			}
		} else if (e instanceof Node) {
			for(Spatial c: ((Node)e).getChildren()) {
				addLight(c);
			}
		}
	}

	public void remove(Spatial e) {
		removePhy(e);
		e.removeFromParent();
		removeLight(e);
	}

	private void removePhy(Spatial e) {
		BulletAppState bulletAppState = app.getStateManager().getState(BulletAppState.class);
		if (bulletAppState != null) {
			PhysicsSpace space = bulletAppState.getPhysicsSpace();
			space.removeAll(e);
		}
	}

	private void removeLight(Spatial e) {
		if (e instanceof Geometry){
			Geometry g = (Geometry)e;
			if (Helpers4Lights.isLight(g)) {
				AppStateDeferredRendering r = app.getStateManager().getState(AppStateDeferredRendering.class);
				if (r != null) {
					r.olights().remove.onNext(g);
				}
			}
		} else if (e instanceof Node) {
			for(Spatial c: ((Node)e).getChildren()) {
				removeLight(c);
			}
		}
	}

	public void removeAll() {
		for(Spatial s: subRoot.getChildren()) {
			remove(s);
		}
	}
}
