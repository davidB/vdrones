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
        bindings.clear();
        skel = Spatials.findSkeleton(spatial);
        if (skel == null) return;
        for(int i = skel.getBoneCount() - 1; i > -1; i--) {
            Bone b = skel.getBone(i);
            Spatial child = ((Node)spatial).getChild(b.getName());
            if (child != null) {
                BoneAndSpatial e = new BoneAndSpatial();
                e.bone = b;
                e.spatial = child;
                e.bone.setUserControl(true);
                e.p0.set(child.getLocalTranslation());
                bindings.add(e);
            }
        }
        
//        for(BoneAndSpatial e : bindings) {
//            System.out.printf("%s : %s // %s .. %s\n", e.bone.getName(), e.bone.getBindPosition(), e.spatial.getLocalTranslation(), e.spatial.getLocalScale());
//            v0.set(e.spatial.getLocalTranslation());//.subtractLocal(e.bone.getBindPosition());//.mult(0.5f);
//            v0.set(0, 0, 0);
//            e.bone.setBindTransforms(v0, e.spatial.getLocalRotation(), e.spatial.getLocalScale());
//        }
        skel.setBindingPose();
        
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
