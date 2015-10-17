package vdrones

import com.jme3.collision.CollisionResult
import com.jme3.collision.CollisionResults
import com.jme3.math.Quaternion
import com.jme3.math.Ray
import com.jme3.math.Vector3f
import com.jme3.renderer.Camera
import com.jme3.scene.Node
import com.jme3.scene.Spatial
import javax.inject.Inject
import jme3_ext.AppState0

package class CameraFollower {
	public enum Mode {
		TOP, TPS, FPS
	}
	final package Mode mode
	final package Vector3f lookAtOffset=new Vector3f()
	final package Vector3f positionOffset=new Vector3f()
	final package Vector3f up=Vector3f.UNIT_Y.clone()
	final package Spatial target
	package  new(Mode mode, Spatial target) {
		this.target=target this.mode=mode 
		switch (mode) {
			case TOP:{
				lookAtOffset.set(0f, 0f, 0f)
				positionOffset.set(0.0f, 80.0f, 0.0f)
				up.set(0.0f, 0.0f, 1.0f) /* FIXME Unsupported BreakStatement: */
			}
			case TPS:{
				lookAtOffset.set(0.0f, 0f, 10f)
				positionOffset.set(0.0f, 4.0f, -10.0f)
				 up.set(0.0f, 1.0f, 0.0f) /* FIXME Unsupported BreakStatement: */
			}
			case FPS:{
				lookAtOffset.set(10.0f, 0f, 0f)
				positionOffset.set(0.01f, 0f, 0.0f)
				up.set(0.0f, 1.0f, 0.0f) /* FIXME Unsupported BreakStatement: */
			}
		}
	}
	
}

//TODO Convert into a Control to plug on a CameraNode
class AppStateCamera extends AppState0 {
	Camera camera
	final Vector3f v0=new Vector3f(0,0,0)
	CameraFollower follower
	Node rootNode
	def void setCameraFollower(CameraFollower follower) {
		this.follower=follower if (follower === null || follower.target === null) {
			setEnabled(false) 
		} else {
			setEnabled(true) 
		}
	}
	override void doInitialize() {
		camera=app.getCamera()
		rootNode= app.getRootNode()
		setEnabled(false) 
	}
	override void doUpdate(float tpf) {
		if (follower !== null) {
			var Spatial target=follower.target 
			var float step=Math.min(1.0f, tpf * 4.0f) 
			offsetPosition(v0, follower.positionOffset, target.getWorldTranslation(), target.getWorldRotation(), true) camera.setLocation(approachMulti(v0, camera.getLocation(), step)) // TODO approachMulti on v0
			offsetPosition(v0, follower.lookAtOffset, target.getWorldTranslation(), target.getWorldRotation(), false) camera.lookAt(v0, follower.up) 
		}
		
	}
	def private float approachMulti(float target, float current, float step) {
		var float mstep=target - current 
		return current + step * mstep 
	}
	def private Vector3f approachMulti(Vector3f target, Vector3f current, float step) {
		target.x=approachMulti(target.x, current.x, step) target.y=approachMulti(target.y, current.y, step) target.z=approachMulti(target.z, current.z, step) return target 
	}
	def private Vector3f offsetPosition(Vector3f out, Vector3f offset, Vector3f targetPosition, Quaternion targetRotation, boolean nearest) {
		out.set(offset) targetRotation.multLocal(out) targetRotation.mult(Vector3f.UNIT_X) if (nearest) {
			var Spatial area=rootNode.getChild(EntityFactory.LevelName) 
			if (area !== null) {
				var CollisionResults results=new CollisionResults() 
				//FIXME: create tmp vec3
				var Ray ray=new Ray(targetPosition,out.normalize()) 
				area.collideWith(ray, results) if (results.size() > 0) {
					var CollisionResult closest=results.getClosestCollision() 
					var float distance=closest.getDistance() 
					if ((distance * distance) < offset.lengthSquared()) {
						out.set(closest.getContactPoint()).subtractLocal(targetPosition) 
					}
					
				}
				
			}
			
		}
		out.addLocal(targetPosition) return out 
	}
	@Inject
	new() {}
	
}