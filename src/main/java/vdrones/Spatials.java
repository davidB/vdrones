/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package vdrones;

import com.jme3.animation.AnimControl;
import com.jme3.animation.Skeleton;
import com.jme3.animation.SkeletonControl;
import com.jme3.asset.AssetManager;
import com.jme3.material.Material;
import com.jme3.math.ColorRGBA;
import com.jme3.scene.Geometry;
import com.jme3.scene.Node;
import com.jme3.scene.Spatial;
import com.jme3.scene.debug.SkeletonDebugger;

/**
 *
 * @author dwayne
 */
public class Spatials {

    public static Geometry findGeom(Spatial spatial, String name) {
        Geometry r = null;
        if (spatial instanceof Geometry && spatial.getName().startsWith(name)) {
            r = (Geometry) spatial;
        }
        if (r == null && spatial instanceof Node) {
            Node node = (Node) spatial;
            for (int i = 0; r == null && i < node.getQuantity(); i++) {
                Spatial child = node.getChild(i);
                r = findGeom(child, name);
            }
        }
        return r;
    }

    public static AnimControl findAnimControl(Spatial spatial) {
        AnimControl r = spatial.getControl(AnimControl.class);
        if (r == null && spatial instanceof Node) {
            Node node = (Node) spatial;
            for (int i = 0; r == null && i < node.getQuantity(); i++) {
                Spatial child = node.getChild(i);
                r = findAnimControl(child);
            }
        }
        return r;
    }

    public static Skeleton findSkeleton(Spatial spatial) {
        //List<Spatial> r = v.descendantMatches(Spatial.class, "Drone");
    	//children can have AnimControl without Skeleton => don't use findAnimControl
        Skeleton r = null;
    	SkeletonControl c0 = spatial.getControl(SkeletonControl.class);
    	if (c0 != null) {
    		r = c0.getSkeleton();
    	}
    	if (r == null) {
	        AnimControl control = spatial.getControl(AnimControl.class);
	        if (control != null) {
	            r = control.getSkeleton();
	        }
    	}
        if (r == null && spatial instanceof Node) {
            Node node = (Node) spatial;
            for (int i = 0; r == null && i < node.getQuantity(); i++) {
                Spatial child = node.getChild(i);
                r = findSkeleton(child);
            }
        }
        return r;
    }

    public static void setDebugSkeleton(Spatial spatial, AssetManager assetManager, ColorRGBA color) {
        Skeleton skel = findSkeleton(spatial);
        if (skel != null) {
            final SkeletonDebugger skeletonDebug = new SkeletonDebugger("skeleton", skel);
            final Material mat = new Material(assetManager, "Common/MatDefs/Misc/Unshaded.j3md");
            mat.setColor("Color", color);
            mat.getAdditionalRenderState().setDepthTest(false);
            skeletonDebug.setMaterial(mat);
            ((Node)spatial).attachChild(skeletonDebug);
        }
    }
}
