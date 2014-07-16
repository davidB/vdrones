/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

package vdrones;

import com.google.inject.Inject;
import com.jme3.asset.AssetManager;
import com.jme3.bullet.collision.shapes.BoxCollisionShape;
import com.jme3.bullet.collision.shapes.CollisionShape;
import com.jme3.bullet.collision.shapes.SphereCollisionShape;
import com.jme3.bullet.control.RigidBodyControl;
import com.jme3.bullet.joints.SixDofSpringJoint;
import com.jme3.light.Light;
import com.jme3.material.Material;
import com.jme3.math.ColorRGBA;
import com.jme3.math.Matrix3f;
import com.jme3.math.Vector3f;
import com.jme3.scene.Geometry;
import com.jme3.scene.Mesh;
import com.jme3.scene.Node;
import com.jme3.scene.Spatial;
import com.jme3.scene.VertexBuffer;
import com.jme3.scene.control.Control;
import com.jme3.scene.mesh.IndexBuffer;
import com.jme3.scene.shape.Box;
import com.jme3.scene.shape.Sphere;

import java.nio.Buffer;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.stream.Stream;

import lombok.extern.slf4j.Slf4j;

class CollisionGroups {
	static final int NONE = 0;
	static final int DRONE = 1;
	static final int WALL = 2;
}
/**
 *
 * @author dwayne
 */
@Slf4j
public class EntityFactory {
    public static final String LevelName = "scene0";
    public static final String UD_joints = "joints";

    @Inject
    public AssetManager assetManager;

    public AreaCfg newLevel(String name) {
        return newLevel(assetManager.loadModel("Scenes/"+ name + ".j3o"));
    }

    public AreaCfg newLevel(Spatial src) {
        log.info("check level : {}", Tools.checkIndexesOfPosition(src));
        PlaceHolderReplacer replacer = new PlaceHolderReplacer();
        replacer.factory = this;
        Spatial level = replacer.replaceTree(src.deepClone());
        log.info("check level : {}", Tools.checkIndexesOfPosition(level));
        AreaCfg a = new AreaCfg();
        a.name = level.getName();
		for (Light l : level.getLocalLightList()) {
			a.lights.add(l);
		}
		extract(level, "backgrounds").forEach(v -> addInto(v, a.bg, "backgrounds"));
		extract(level, "spawners").map(v -> setY(v, -0.2f)).forEach(v -> addInto(v, a.spawnPoints));
		extract(level, "traps").forEach(v -> addInto(v, a.bg, "traps"));
		extract(level, "exits").forEach(v -> addInto(v, a.bg, "exits"));
		a.bg.stream().forEach(v -> setCollisionGroupsRecursive(v, CollisionGroups.WALL, CollisionGroups.DRONE));
		return a;
	}

	private Stream<Spatial> extract(Spatial src, String groupName) {
		Node group = (Node) ((Node)src).getChild(groupName);
		if (group == null) System.out.printf("group not found : %s \n", groupName);
		return (group != null) ? group.getChildren().stream() : Stream.empty();
	}

	private void addInto(Spatial s, Collection<Spatial> dest, String groupName) {
		s.setLocalTransform(s.getWorldTransform());
		s.setUserData("dest", EntityFactory.LevelName);
		s.setUserData("groupName", groupName);
		dest.add(s);
	}

	private Spatial setY(Spatial s, float y) {
		Vector3f pos = s.getLocalTranslation();
		pos.y = y;
		s.setLocalTranslation(pos);
		return s;
	}

	private void addInto(Spatial s, Collection<Location> dest) {
		Location loc = new Location();
		loc.position.set(s.getWorldTranslation());
		loc.orientation.set(s.getWorldRotation());
		dest.add(loc);
	}

	public Spatial newMWall(Spatial src, Box shape) {
        Spatial b = new Geometry(src.getName(), shape);
        log.info("check mwall : {}", Tools.checkIndexesOfPosition(b));
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
        setCollisionGroupsRecursive(b, CollisionGroups.WALL, CollisionGroups.DRONE);
        return b;
    }

    public Spatial newSpawner(Location loc) {
        Spatial b = assetManager.loadModel("Models/plateform8.j3o");
        log.info("check spawner : {}", Tools.checkIndexesOfPosition(b));
        //copyCtrlAndTransform(src, b);
        b.setLocalRotation(loc.orientation);
        b.setLocalTranslation(loc.position);
        return b;
    }

    public Spatial newBox() {
        Box shape = new Box(1, 1, 1); // create cube shape
        Geometry b = new Geometry("Box", shape);  // create cube geometry from the shape
        Material mat = new Material(assetManager, "Common/MatDefs/Misc/Unshaded.j3md");  // create a simple material
        mat.setColor("Color", ColorRGBA.Blue);   // set color of material to blue
        b.setMaterial(mat);                   // set the cube's material
        return b;
    }
/*
    public Spatial newDrone() {
        Spatial b = assetManager.loadModel("Models/drone.j3o");
        log.info("check drone : {}", Tools.checkIndexesOfPosition(b));
        CollisionShape shape = CollisionShapeFactory.createDynamicMeshShape(b);
        //CollisionShape shape = new BoxCollisionShape(new Vector3f(2.0f,1.0f,0.5f));
        RigidBodyControl phy = new RigidBodyControl(shape, 4.0f);
        phy.setAngularFactor(0); //temporary solution to forbid rotation around x and z axis
        b.addControl(phy);
        return b;
    }
*/
    public Node asDrone(Node b) {
        Spatial m = assetManager.loadModel("Models/drone.j3o");
        m.setName("model");
        //Geometry geom = Spatials.findGeom(m, "Cube.0011");
        b.attachChild(m);

        //TODO compute radius from model (bones)
        CollisionShape shape0 = new SphereCollisionShape(0.5f);
        RigidBodyControl phy0 = new RigidBodyControl(shape0, 4.0f);
        b.addControl(phy0);
        phy0.setAngularFactor(0);

        CollisionShape shape1 = new SphereCollisionShape(0.3f);

        Node rn = new Node("rear.R");
        b.attachChild(rn);
        rn.setLocalTranslation(-1f, 0, 1f);
        RigidBodyControl rp = new RigidBodyControl(shape1, 0.5f);
        rn.addControl(rp);
        rp.setAngularFactor(0);

        Node ln = new Node("rear.L");
        b.attachChild(ln);
        ln.setLocalTranslation(-1f, 0, -1f);
        RigidBodyControl lp = new RigidBodyControl(shape1, 0.5f);
        ln.addControl(lp);
        lp.setAngularFactor(0);

        Node fn = new Node("front");
        b.attachChild(fn);
        fn.setLocalTranslation(2.0f, 0, 0);
        RigidBodyControl fp = new RigidBodyControl(shape1, 1.0f);
        //fp.setPhysicsLocation(new Vector3f(2f, 0, 0));
        fn.addControl(fp);
        fp.setAngularFactor(0);

        Node tn = new Node("top");
        b.attachChild(tn);
        tn.setLocalTranslation(0.0f, 0.6f, 0);
        RigidBodyControl tp = new RigidBodyControl(shape1, 0.5f);
        //fp.setPhysicsLocation(new Vector3f(2f, 0, 0));
        tn.addControl(tp);
        tp.setAngularFactor(0);

        join(phy0, rp);
        join(phy0, lp);
        join(phy0, fp);
        join(phy0, tp);

        join(tp, rp);
        join(tp, lp);
        join(tp, fp);

        join(fp, lp);
        join(fp, rp);

        join(rp, lp);

        //Spatials.setDebugSkeleton(b, assetManager, ColorRGBA.Green);
        b.addControl(new ControlSpatialsToBones());
        b.addControl(new ControlDronePhy());
        setCollisionGroupsRecursive(b, CollisionGroups.DRONE, -1);

        return b;
    }

    public Node unasDrone(Node b) {
    	b.detachChildNamed("model");
    	b.detachChildNamed("top");
    	b.detachChildNamed("front");
    	b.detachChildNamed("rear.L");
    	b.detachChildNamed("rear.R");
    	b.removeControl(RigidBodyControl.class);
    	return b;
    }


    // http://help.autodesk.com/view/MAYAUL/2015/ENU/?guid=GUID-F7CD10A1-47D0-45A0-9E9A-495DF9F49B94
    static Object join(RigidBodyControl ri, RigidBodyControl rj) {
        /*
        SliderJoint joint = new SliderJoint(ri, rj, Vector3f.ZERO, Vector3f.ZERO, true);
        joint.setLowerLinLimit(0.1f);
        joint.setUpperLinLimit(1.5f);
        joint.setCollisionBetweenLinkedBodys(false);
        */


        SixDofSpringJoint joint = new SixDofSpringJoint(ri, rj, Vector3f.ZERO, Vector3f.ZERO, Matrix3f.IDENTITY, Matrix3f.IDENTITY, true);
        javax.vecmath.Vector3f vi = ri.getObjectId().getCenterOfMassPosition(new javax.vecmath.Vector3f());
        javax.vecmath.Vector3f vj = rj.getObjectId().getCenterOfMassPosition(new javax.vecmath.Vector3f());
        javax.vecmath.Vector3f v = new javax.vecmath.Vector3f();
        v.sub(vj, vi);
        joint.setEquilibriumPoint();
        for(int i = 0; i < 3; i++){
            joint.enableSpring(i, true);
            joint.setStiffness(i, 10.0f); // 0-10
            joint.setDamping(i, 0.1f); // 0-1
        }
        for(int i = 3; i < 6; i++){
            joint.enableSpring(i, false);
            //joint.setStiffness(i, 10.0f); // 0-10
            //joint.setDamping(i, 0.5f); // 0-1
        }

        //joint.setLinearLowerLimit(new Vector3f(v.x * 0.9f, v.y * 0.9f, v.z * 0.9f));
        //joint.setLinearUpperLimit(new Vector3f(v.x * 1.1f, v.y * 1.1f, v.z * 1.1f));
        float delta = 0.5f;
        joint.setLinearLowerLimit(new Vector3f(v.x - delta, v.y - delta, v.z - delta));
        joint.setLinearUpperLimit(new Vector3f(v.x + delta, v.y + delta, v.z + delta));
        //float d = v.length();
        //joint.setLinearLowerLimit(new Vector3f(0, 0, d * 0.9f));
        //joint.setLinearUpperLimit(new Vector3f(0, 0, d * 1.1f));
        joint.setAngularLowerLimit(Vector3f.ZERO);
        joint.setAngularUpperLimit(Vector3f.ZERO);
        joint.setCollisionBetweenLinkedBodys(false);

        //System.out.println("ri pos : " + ri.getObjectId().getCenterOfMassPosition(new javax.vecmath.Vector3f()));
        //System.out.println("rj pos : " + rj.getObjectId().getCenterOfMassPosition(new javax.vecmath.Vector3f()));
        return joint;
    }

    public void copyCtrlAndTransform(Spatial src, Spatial dst) {
        dst.setLocalTransform(src.getLocalTransform());
        for(int i = 0; i< src.getNumControls(); i++) {
            Control ctrl = src.getControl(i);
            ctrl.cloneForSpatial(dst);
        }
    }

    public void setCollisionGroupsRecursive(Spatial src, int collisionGroup, int collideWith) {
    	RigidBodyControl phy = src.getControl(RigidBodyControl.class);
    	if (phy != null) {
    		if (collisionGroup > 0) phy.setCollisionGroup(collisionGroup);
    		if (collideWith > 0) phy.setCollideWithGroups(collideWith);
    	}
    	if (src instanceof Node) {
    		((Node)src).getChildren().stream().forEach(v -> setCollisionGroupsRecursive(v, collisionGroup, collideWith));
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
            children.stream().forEach((Spatial s) -> {
                r.attachChild(replaceTree(s));
            });
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
//            case "spawner" :
//                b = factory.newSpawner(spatial);
//                break;
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

class Tools {

    public static boolean checkIndexesOfPosition(Spatial s) {
        boolean b = true;
        if (s instanceof Geometry) {
            b = checkIndexesOfPosition(((Geometry) s).getMesh());
        }
        if (s instanceof Node) {
            for(Spatial child : ((Node)s).getChildren()) {
                b = b && checkIndexesOfPosition(child);
            }
        }
        return b;
    }

    public static boolean checkIndexesOfPosition(Mesh m) {
        boolean b = true;
        IndexBuffer iis = m.getIndexBuffer();
        VertexBuffer ps = m.getBuffer(VertexBuffer.Type.Position);
        Buffer psb = ps.getDataReadOnly();
        b = b && (psb.remaining() == (ps.getNumElements() * 3) + ps.getOffset()); // 3 float
        //if (!b) System.out.printf("%d != %d * %d : psb.remaining() == ps.getNumElements() * 3 \n", psb.remaining(), ps.getNumElements());
        //VertexBuffer ips = m.getBuffer(VertexBuffer.Type.Normal);
        for(int ii = 0; b && ii < iis.size(); ii++) {
            int i = iis.get(ii);
            b = b && i < ps.getNumElements() && i > -1;
            //if (!b) System.out.printf("-1 < %d < %d : i < ps.getNumElements()\n", i, ps.getNumElements());
        }
        return b;
    }
}