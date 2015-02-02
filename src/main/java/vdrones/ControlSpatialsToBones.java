/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

package vdrones;

import java.util.ArrayList;
import java.util.List;

import com.jme3.animation.Bone;
import com.jme3.animation.Skeleton;
import com.jme3.math.Quaternion;
import com.jme3.math.Vector3f;
import com.jme3.renderer.RenderManager;
import com.jme3.renderer.ViewPort;
import com.jme3.scene.Node;
import com.jme3.scene.Spatial;
import com.jme3.scene.control.AbstractControl;
import com.jme3.scene.control.Control;

/**
 *
 * @author dwayne
 */
public class ControlSpatialsToBones extends AbstractControl {
	Skeleton skel;
	List<BoneAndSpatial> bindings = new ArrayList<>();
	Vector3f v0 = new Vector3f();

	@Override
	protected void controlUpdate(float tpf) {
		bindings.stream().forEach((e) -> {
			v0.set(e.spatial.getLocalTranslation()).subtractLocal(e.p0);
			e.bone.setUserTransforms(v0, e.spatial.getLocalRotation(), e.spatial.getLocalScale());
			//e.bone.setUserTransforms(v0, Quaternion.IDENTITY, Vector3f.UNIT_XYZ);
		});
	}

	@Override
	public Control cloneForSpatial(Spatial spatial) {
		ControlSpatialsToBones control = new ControlSpatialsToBones();
		control.setSpatial(spatial);
		return control;
	}

	@Override
	public void setSpatial(Spatial spatial) {
		super.setSpatial(spatial);
		bindings.clear();
		if (bindings.isEmpty() && spatial != null && (skel = Spatials.findSkeleton(spatial)) != null) {
			for(int i = skel.getBoneCount() - 1; i > -1; i--) {
				Bone b = skel.getBone(i);
				Spatial child = ((Node)spatial).getChild(b.getName());
				if (child != null) {
					BoneAndSpatial e = new BoneAndSpatial();
					e.bone = b;
					e.spatial = child;
					//e.p0.set(b.getWorldBindPosition().z, b.getWorldBindPosition().x, b.getWorldBindPosition().y);
					e.p0.set(b.getWorldBindPosition().y, b.getWorldBindPosition().x, -b.getWorldBindPosition().z);
					child.setLocalTranslation(e.p0.clone());
					//System.out.printf("%s : %s : %s\n", b.getName(), b.getWorldBindPosition(), child.getLocalTranslation());
					e.bone.setUserControl(true);
					b.getLocalPosition().set(e.p0);
					bindings.add(e);
				}
			}
			skel.setBindingPose();
		}
	}

	@Override
	protected void controlRender(RenderManager rm, ViewPort vp) {
	}

	static class BoneAndSpatial {
		Bone bone;
		Spatial spatial;
		Vector3f p0 = new Vector3f();
	}

}
