/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

package vdrones;

import com.jme3.asset.AssetManager;
import com.jme3.bullet.collision.shapes.BoxCollisionShape;
import com.jme3.bullet.collision.shapes.CollisionShape;
import com.jme3.bullet.control.RigidBodyControl;
import com.jme3.bullet.util.CollisionShapeFactory;
import com.jme3.math.Vector3f;
import com.jme3.scene.Geometry;
import com.jme3.scene.Mesh;
import com.jme3.scene.Node;
import com.jme3.scene.Spatial;
import com.jme3.scene.control.Control;
import com.jme3.scene.shape.Box;
import com.jme3.scene.shape.Sphere;
import java.util.ArrayList;
import java.util.List;
import lombok.extern.slf4j.Slf4j;

/**
 *
 * @author dwayne
 */
public class EntityFactory {
    public static final String LevelName = "scene0";
        
    public AssetManager assetManager;

    public Spatial newLevel(String name) {
        return newLevel(assetManager.loadModel("Scenes/"+ name + ".j3o"));
    }
    
    public Spatial newLevel(Spatial src) {
        PlaceHolderReplacer replacer = new PlaceHolderReplacer();
        replacer.factory = this;
        Spatial b = replacer.replaceTree(src.deepClone());
        b.setName(LevelName);
        return b;
    }
    
    public Spatial newMWall(Spatial src, Box shape) {
        Spatial b = new Geometry(src.getName(), shape);
        b.setMaterial(assetManager.loadMaterial("Materials/mwall.j3m"));
        copyCtrlAndTransform(src, b);
        Vector3f halfExtents = new Vector3f(shape.getXExtent(), shape.getYExtent(), shape.getZExtent())
                //.multLocal(0.5f)
                .multLocal(src.getWorldScale())
                ;
        CollisionShape cshape = new BoxCollisionShape(halfExtents);
        RigidBodyControl phy = new RigidBodyControl(cshape);
        phy.setKinematic(true);
        phy.setKinematicSpatial(true);
        b.addControl(phy);
        return b;
    }

    public Spatial newSpawner(Spatial src) {
        Spatial b = assetManager.loadModel("Models/plateform8.j3o");
        copyCtrlAndTransform(src, b);
        return b;
    }
    
    public Spatial newDrone() {
        Spatial b = assetManager.loadModel("Models/drone.j3o");
        CollisionShape shape = CollisionShapeFactory.createDynamicMeshShape(b);
        //CollisionShape shape = new BoxCollisionShape(new Vector3f(2.0f,1.0f,0.5f));
        RigidBodyControl phy = new RigidBodyControl(shape, 4.0f);
        phy.setAngularFactor(0); //temporary solution to forbid rotation around x and z axis
        b.addControl(phy);
        return b;
    }
    
    public void copyCtrlAndTransform(Spatial src, Spatial dst) {
        dst.setLocalTransform(src.getLocalTransform());
        for(int i = 0; i< src.getNumControls(); i++) {
            Control ctrl = src.getControl(i);
            ctrl.cloneForSpatial(dst);
        }
    }
    
}

@Slf4j
class PlaceHolderReplacer {
    EntityFactory factory;
    
    public Spatial replaceTree(Spatial root) {
        Spatial rootbis = replace(root);
        if (rootbis == root && rootbis instanceof Node) {
            Node r = (Node)root;
            List<Spatial> children = new ArrayList<>(r.getChildren());
            r.detachAllChildren();
            for(Spatial s : children) {
                r.attachChild(replaceTree(s));
            }
        }
        return rootbis;
    }
    
    public Spatial replace(Spatial spatial) {
        Spatial b = spatial;
        if (spatial instanceof Geometry) {
            Mesh mesh = ((Geometry) spatial).getMesh();
            b = (mesh instanceof Box)? replace(spatial, (Box) mesh)
                : (mesh instanceof Sphere)? replace(spatial, (Sphere) mesh)
                : spatial
                ;
        }
        return b;
    }

    public Spatial replace(Spatial spatial, Box shape) {
        log.debug("{} as box x({}), y({}), z({})", spatial.getName(), shape.getXExtent(), shape.getYExtent(), shape.getZExtent());
        Spatial b;
        switch(spatial.getName()) {
            case "mwall" :
                b = factory.newMWall(spatial, shape);
                break;
            case "spawner" :
                b = factory.newSpawner(spatial);
                break;
            default:
                b = spatial;
        }
        return b;
    }

    public Spatial replace(Spatial src, Sphere shape) {
        log.warn("NOT Implemented as sphere : {}({},{},{})",src.getName(), shape.getZSamples(), shape.getRadialSamples(), shape.getRadius());
        return src;
    }
    
}