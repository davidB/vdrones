/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package vdrones

import com.jme3.animation.AnimControl
import com.jme3.animation.Animation
import com.jme3.asset.AssetManager
import com.jme3.bounding.BoundingBox
import com.jme3.bullet.collision.shapes.BoxCollisionShape
import com.jme3.bullet.collision.shapes.CollisionShape
import com.jme3.bullet.collision.shapes.SphereCollisionShape
import com.jme3.bullet.control.PhysicsControl
import com.jme3.bullet.control.RigidBodyControl
import com.jme3.bullet.joints.SixDofSpringJoint
import com.jme3.material.Material
import com.jme3.math.ColorRGBA
import com.jme3.math.Matrix3f
import com.jme3.math.Rectangle
import com.jme3.math.Vector3f
import com.jme3.renderer.queue.RenderQueue.ShadowMode
import com.jme3.scene.Geometry
import com.jme3.scene.Mesh
import com.jme3.scene.Node
import com.jme3.scene.Spatial
import com.jme3.scene.VertexBuffer
import com.jme3.scene.control.Control
import com.jme3.scene.mesh.IndexBuffer
import com.jme3.scene.shape.Box
import com.jme3.scene.shape.Quad
import com.jme3.util.SkyFactory
import java.nio.Buffer
import java.util.ArrayList
import java.util.Collection
import java.util.List
import java.util.stream.Stream
import javax.inject.Inject
import jme3_ext_deferred.MaterialConverter
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.slf4j.LoggerFactory

package class CollisionGroups {
    static final package int NONE = 0
    static final package int DRONE = 1
    static final package int WALL = 2
    static final package int CUBE = 3

    def static void setRecursive(Spatial src, int collisionGroup, int collideWith) {
        if (collisionGroup > 0) {
            src.setUserData("CollisionGroup", collisionGroup)
        }
        var RigidBodyControl phy = src.getControl(RigidBodyControl)
        if (phy !== null) {
            if(collisionGroup > 0) phy.setCollisionGroup(collisionGroup)
            if(collideWith > 0) phy.setCollideWithGroups(collideWith)
        }
        if (src instanceof Node) {
            src.getChildren().forEach[v|setRecursive(v, collisionGroup, collideWith)]
        }

    }

    def static boolean test(Spatial src, Integer collisionGroup) {
        return collisionGroup.equals(src.getUserData("CollisionGroup"))
    }

    def static int from(Spatial src) {
        var Integer v = src.getUserData("CollisionGroup") as Integer
        return if (v === null) NONE else v.intValue()
    }

}
/** 
 * @author dwayne
 */
class EntityFactory {
    val log = LoggerFactory.getLogger(EntityFactory)
    public static final String LevelName = "scene0"
    public static final String UD_joints = "joints"
    public final AssetManager assetManager
    public final MaterialConverter mc

    def CfgArea newLevel(String name) {
        var Spatial b = assetManager.loadModel('''Scenes/«name».j3o''')
        b.breadthFirstTraversal(mc)
        return newLevel(b)
    }

    def CfgArea newLevel(Spatial src) {
        log.info("check level : {}", Tools.checkIndexesOfPosition(src))
        var replacer = new PlaceHolderReplacer()
        replacer.factory = this
        replacer.assetManager = assetManager
        var level = replacer.replaceTree(src.deepClone())
        level.breadthFirstTraversal(mc)
        log.info("check level : {}", Tools.checkIndexesOfPosition(level))
        val a = new CfgArea()
        a.name = level.getName() // TODO remove deferred		
        // for (Light l : level.getLocalLightList()) {
        // a.bg.add(Helpers4Lights.toGeometry(l, true, assetManager));
        // }
        var sky = SkyFactory.createSky(assetManager, "Textures/sky1.jpg", true)
        sky.rotateUpTo(Vector3f.UNIT_Z)
        addInto(sky, a.bg, "sky")
        extract(level, "backgrounds").forEach[v|addInto(v, a.bg, "backgrounds")]
        extract(level, "spawners").map[v|setY(v, -0.2f)].forEach[v|addInto(v, a.spawnPoints)]
        extract(level, "traps").forEach[v|addInto(v, a.bg, "traps")]
        extract(level, "exits").map[v|setY(v, -1.0f)].forEach[v|addInto(v, a.exitPoints)]
        extract(level, "cubes").map[v|this.extractZone(v)].forEach[v|a.cubeZones.add(v)]
        a.bg.stream().forEach[v|CollisionGroups.setRecursive(v, CollisionGroups.WALL, CollisionGroups.DRONE)]
        return a
    }

    def private Stream<Spatial> extract(Spatial src, String groupName) {
        var Node group = (src as Node).getChild(groupName) as Node
        if(group === null) log.warn("group not found : {}", groupName)
        return if((group !== null)) group.getChildren().stream() else Stream.empty()
    }

    def private void addInto(Spatial s, Collection<Spatial> dest, String groupName) {
        s.setLocalTransform(s.getWorldTransform())
        s.setUserData("dest", EntityFactory.LevelName)
        s.setUserData("groupName", groupName)
        dest.add(s)
    }

    def private Spatial setY(Spatial s, float y) {
        var Vector3f pos = s.getLocalTranslation()
        pos.y = y
        s.setLocalTranslation(pos)
        return s
    }

    //TODO use empty Spatial, scale (to have the bounding box 
    def private List<Rectangle> extractZone(Spatial src) {
        System.out.println('''src name «src.getName()» . «(src as Node).getQuantity()»''')
        return (src as Node).getChildren().map[v|
            val quad = (v as Geometry).getMesh() as Quad
            // quad.getHeight() and quad.getWidth() are equals to 0
            //float xe = quad.getHeight() * 0.5;
            //float ye = quad.getWidth() * 0.5;
            val xe = (quad.getBound() as BoundingBox).getXExtent()
            val ye = (quad.getBound() as BoundingBox).getYExtent()
            val t = v.getWorldTransform()
            val a = t.transformVector(new Vector3f(xe  , ye  , 0.0f), null)
            val b = t.transformVector(new Vector3f(0.0f, ye  , 0.0f), null)
            val c = t.transformVector(new Vector3f(xe  , 0.0f, 0.0f), null)
            System.out.printf("Zone rect :a %s b %s c %s w %s h %s\n", a, b, c, xe, ye)
            new Rectangle(a,b,c) // bc is hypothesus
        ].toList()
    }

    def private void addInto(Spatial s, Collection<Location> dest) {
        var Location loc = new Location()
        loc.position.set(s.getWorldTranslation())
        loc.orientation.set(s.getWorldRotation())
        dest.add(loc)
    }

    def Spatial newMWall(Spatial src, Box shape) {
        var Spatial b = new Geometry(src.getName(), shape)
        log.info("check mwall : {}", Tools.checkIndexesOfPosition(b))
        b.setMaterial(assetManager.loadMaterial("Materials/mwall.j3m"))
        b.breadthFirstTraversal(mc)
        copyCtrlAndTransform(src, b)
        var Vector3f halfExtents = new Vector3f(shape.getXExtent(), shape.getYExtent(), shape.getZExtent()). // .multLocal(0.5f)
        multLocal(src.getWorldScale())
        var CollisionShape cshape = new BoxCollisionShape(halfExtents)
        var RigidBodyControl phy = new RigidBodyControl(cshape)
        phy.setKinematic(true)
        phy.setKinematicSpatial(true)
        b.addControl(phy)
        CollisionGroups.setRecursive(b, CollisionGroups.WALL, CollisionGroups.NONE)
        return b
    }

    def Spatial newSpawnPoint(Location loc) {
        var Spatial b = assetManager.loadModel("Models/spawnPoint.j3o")
        b.breadthFirstTraversal(mc)
        b.setShadowMode(ShadowMode.CastAndReceive) // log.info("check spawner : {}", Tools.checkIndexesOfPosition(b));
        b.setLocalRotation(loc.orientation)
        b.setLocalTranslation(loc.position)
        return b
    }

    def Spatial newExitPoint(Location loc) {
        var Spatial b = assetManager.loadModel("Models/exitPoint.j3o")
        b.breadthFirstTraversal(mc)
        b.setShadowMode(ShadowMode.CastAndReceive)
        b.setLocalRotation(loc.orientation)
        b.setLocalTranslation(loc.position)
        return b
    }

    def Spatial newBox() {
        var Box shape = new Box(1, 1, 1)
        // create cube shape
        var Geometry b = new Geometry("Box", shape)
        // create cube geometry from the shape
        var Material mat = new Material(assetManager, "Common/MatDefs/Misc/Unshaded.j3md")
        // create a simple material
        mat.setColor("Color", ColorRGBA.Blue) // set color of material to blue
        b.setMaterial(mat) // set the cube's material
        return b
    }

    /*
     *     public Spatial newDrone() {
     *         Spatial b = assetManager.loadModel("Models/drone.j3o");
     *         log.info("check drone : {}", Tools.checkIndexesOfPosition(b));
     *         CollisionShape shape = CollisionShapeFactory.createDynamicMeshShape(b);
     *         //CollisionShape shape = new BoxCollisionShape(new Vector3f(2.0f,1.0f,0.5f));
     *         RigidBodyControl phy = new RigidBodyControl(shape, 4.0f);
     *         phy.setAngularFactor(0); //temporary solution to forbid rotation around x and z axis
     *         b.addControl(phy);
     *         return b;
     *     }
     */
    def Node asCube(Node b) {
        var Box mesh = new Box(0.5f, 0.5f, 0.5f)
        var Geometry geom = new Geometry("cube", mesh)
        geom.setMaterial(assetManager.loadMaterial("Materials/cube.j3m"))
        geom.breadthFirstTraversal(mc)
        geom.setShadowMode(ShadowMode.CastAndReceive)
        b.attachChild(geom)
        var CollisionShape shape0 = new SphereCollisionShape(0.5f)
        var RigidBodyControl phy0 = new RigidBodyControl(shape0, 0.1f)
        phy0.setGravity(Vector3f.ZERO)
        phy0.setAngularFactor(0)
        b.addControl(phy0) // CollisionGroups.setRecursive(b, CollisionGroups.CUBE, CollisionGroups.DRONE);
        CollisionGroups.setRecursive(b, CollisionGroups.CUBE, CollisionGroups.WALL)
        var Animation generatingAnim = new Animation("generating", 0.5f)
        var Animation waitingAnim = new Animation("waiting", 2.0f)
        waitingAnim.addTrack(new TrackRotateYX(2.0f))
        var Animation exitingAnim = new Animation("exiting", 0.5f)
        var Animation grabbedAnim = new Animation("grabbed", 2.0f)
        var AnimControl ac = new AnimControl()
        b.addControl(ac)
        ac.addAnim(generatingAnim)
        ac.addAnim(waitingAnim)
        ac.addAnim(exitingAnim)
        ac.addAnim(grabbedAnim)
        ac.clearChannels()
        ac.createChannel()
        return b
    }

    def Node asDrone(Node b) {
        var Spatial m = assetManager.loadModel("Models/drone.j3o")
        m.breadthFirstTraversal(mc)
        m.setShadowMode(ShadowMode.CastAndReceive)
        m.setName("model") // Geometry geom = Spatials.findGeom(m, "Cube.0011");
        b.attachChild(m) // TODO compute radius from model (bones)
        var CollisionShape shape0 = new SphereCollisionShape(0.5f)
        var RigidBodyControl phy0 = new RigidBodyControl(shape0, 4.0f)
        b.addControl(phy0) // http://www.bulletphysics.org/mediawiki-1.5.8/index.php/Code_Snippets#I_want_to_constrain_an_object_to_two_dimensional_movement.2C_skipping_one_of_the_cardinal_axes
        // TODO modify jbullet https://github.com/MovingBlocks/TeraBullet/commit/9cd1cfdc2cfade3647f69c3152a3144827d8954a
        phy0.setAngularFactor(0)
        var CollisionShape shape1 = new SphereCollisionShape(0.3f)
        var Node rn = new Node("rear.R")
        b.attachChild(rn)
        rn.setLocalTranslation(-1f, 0, 1f)
        var RigidBodyControl rp = new RigidBodyControl(shape1, 0.5f)
        rn.addControl(rp)
        rp.setAngularFactor(0)
        var Node ln = new Node("rear.L")
        b.attachChild(ln)
        ln.setLocalTranslation(-1f, 0, -1f)
        var RigidBodyControl lp = new RigidBodyControl(shape1, 0.5f)
        ln.addControl(lp)
        lp.setAngularFactor(0)
        var Node fn = new Node("front")
        b.attachChild(fn)
        fn.setLocalTranslation(2.0f, 0, 0)
        var RigidBodyControl fp = new RigidBodyControl(shape1, 1.0f)
        // fp.setPhysicsLocation(new Vector3f(2f, 0, 0));
        fn.addControl(fp)
        fp.setAngularFactor(0)
        var Node tn = new Node("top")
        b.attachChild(tn)
        tn.setLocalTranslation(0.0f, 0.6f, 0)
        var RigidBodyControl tp = new RigidBodyControl(shape1, 0.5f)
        tp.destroy() // fp.setPhysicsLocation(new Vector3f(2f, 0, 0));
        tn.addControl(tp)
        tp.setAngularFactor(0)
        join(phy0, rp)
        join(phy0, lp)
        join(phy0, fp)
        join(phy0, tp)
        join(tp, rp)
        join(tp, lp)
        join(tp, fp)
        join(fp, lp)
        join(fp, rp)
        join(rp, lp) // Spatials.setDebugSkeleton(b, assetManager, ColorRGBA.Green);
        b.addControl(new ControlSpatialsToBones())
        CollisionGroups.setRecursive(b, CollisionGroups.DRONE, CollisionGroups.WALL)
        var Animation generatingAnim = new Animation("generating", 0.5f)
        var Animation crashingAnim = new Animation("crashing", 2.0f)
        var Animation exitingAnim = new Animation("exiting", 2.0f)
        // generatingAnim.addTrack(new TrackNoOp(3.0f));
        // AnimControl ac = Spatials.findAnimControl(b);
        var AnimControl ac = new AnimControl()
        b.addControl(ac)
        ac.addAnim(generatingAnim)
        ac.addAnim(crashingAnim)
        ac.addAnim(exitingAnim)
        ac.clearChannels()
        ac.createChannel()
        return b
    }

    // can be called on any Node, (like new Node())
    def Node unas(Node b) {
        // AnimControl ac = Spatials.findAnimControl(b);
        var AnimControl ac = b.getControl(AnimControl)
        if (ac !== null) {
            ac.clearListeners()
            ac.clearChannels()
        }
        b.removeControl(ac)
        b.removeControl(ControlSpatialsToBones)
        removeAllPhysic(b)
        b.detachAllChildren()
        return b
    }

    /** 
     * remove physics from Physics space and from Node space (remove control)
     * @param spatial
     */
    def static package void removeAllPhysic(Spatial spatial) {
        var PhysicsControl physicsNode = null
        while ((physicsNode = spatial.getControl(PhysicsControl)) !== null) {
            if(physicsNode.getPhysicsSpace() !== null) physicsNode.getPhysicsSpace().removeAll(spatial)
            spatial.removeControl(physicsNode)
        }
        if (spatial instanceof Node) {
            spatial.getChildren().forEach[v| removeAllPhysic(v)]
        }

    }

    // http://help.autodesk.com/view/MAYAUL/2015/ENU/?guid=GUID-F7CD10A1-47D0-45A0-9E9A-495DF9F49B94
    def static package Object join(RigidBodyControl ri, RigidBodyControl rj) {
        /*
         *         SliderJoint joint = new SliderJoint(ri, rj, Vector3f.ZERO, Vector3f.ZERO, true);
         *         joint.setLowerLinLimit(0.1f);
         *         joint.setUpperLinLimit(1.5f);
         *         joint.setCollisionBetweenLinkedBodys(false);
         */
        var SixDofSpringJoint joint = new SixDofSpringJoint(ri, rj, Vector3f.ZERO, Vector3f.ZERO, Matrix3f.IDENTITY,
            Matrix3f.IDENTITY, true)
        var javax.vecmath.Vector3f vi = ri.getObjectId().getCenterOfMassPosition(new javax.vecmath.Vector3f())
        var javax.vecmath.Vector3f vj = rj.getObjectId().getCenterOfMassPosition(new javax.vecmath.Vector3f())
        var javax.vecmath.Vector3f v = new javax.vecmath.Vector3f()
        v.sub(vj, vi)
        joint.setEquilibriumPoint()
        for (var int i = 0; i < 3; i++) {
            joint.enableSpring(i, true)
            joint.setStiffness(i, 10.0f) // 0-10
            joint.setDamping(i, 0.1f) // 0-1
        }

        for (var int i = 3; i < 6; i++) {
            joint.enableSpring(i, false) // joint.setStiffness(i, 10.0f); // 0-10
            // joint.setDamping(i, 0.5f); // 0-1
        }
        // joint.setLinearLowerLimit(new Vector3f(v.x * 0.9f, v.y * 0.9f, v.z * 0.9f));
        // joint.setLinearUpperLimit(new Vector3f(v.x * 1.1f, v.y * 1.1f, v.z * 1.1f));
        var float delta = 0.5f
        joint.setLinearLowerLimit(new Vector3f(v.x - delta, v.y - delta, v.z - delta))
        joint.setLinearUpperLimit(new Vector3f(v.x + delta, v.y + delta, v.z + delta)) // float d = v.length();
        // joint.setLinearLowerLimit(new Vector3f(0, 0, d * 0.9f));
        // joint.setLinearUpperLimit(new Vector3f(0, 0, d * 1.1f));
        joint.setAngularLowerLimit(Vector3f.ZERO)
        joint.setAngularUpperLimit(Vector3f.ZERO)
        joint.setCollisionBetweenLinkedBodys(false)
        return joint
    }

    def void copyCtrlAndTransform(Spatial src, Spatial dst) {
        dst.setLocalTransform(src.getLocalTransform())
        for (var int i = 0; i < src.getNumControls(); i++) {
            var Control ctrl = src.getControl(i)
            ctrl.cloneForSpatial(dst)
        }

    }

    @Inject
    @FinalFieldsConstructor
    new(){}
}

package class PlaceHolderReplacer {
    package EntityFactory factory
    package AssetManager assetManager

    def Spatial replaceTree(Spatial root) {
        var Spatial rootbis = replace(root)
        if (rootbis === root && rootbis instanceof Node) {
            val Node r = root as Node
            var List<Spatial> children = new ArrayList(r.getChildren())
            r.detachAllChildren()
            children.forEach[v|
                r.attachChild(replaceTree(v));
            ]
        }
        return rootbis
    }

    def Spatial replace(Spatial spatial) {
        var Spatial b = spatial
        if (spatial instanceof Geometry) {
            var String kind = spatial.getName().split("\\.").get(0)

            switch (kind) {
                case "wall": {
                    spatial.setMaterial(assetManager.loadMaterial("Materials/wall.j3m"))
                    spatial.setShadowMode(ShadowMode.Receive)
                    b = spatial /* FIXME Unsupported BreakStatement: */
                }
                case "floor": {
                    spatial.setMaterial(assetManager.loadMaterial("Materials/floor_white.j3m"))
                    spatial.setShadowMode(ShadowMode.Receive)
                    b = spatial /* FIXME Unsupported BreakStatement: */
                }
            }
        }
        return b
    }

}

package class Tools {
    def static boolean checkIndexesOfPosition(Spatial s) {
        var boolean b = true
        if (s instanceof Geometry) {
            b = checkIndexesOfPosition(s.getMesh())
        }
        if (s instanceof Node) {
            for (child : s.getChildren()) {
                b = b && checkIndexesOfPosition(child)
            }

        }
        return b
    }

    def static boolean checkIndexesOfPosition(Mesh m) {
        var boolean b = true
        var IndexBuffer iis = m.getIndexBuffer()
        var VertexBuffer ps = m.getBuffer(VertexBuffer.Type.Position)
        var Buffer psb = ps.getDataReadOnly()
        b = b && (psb.remaining() === (ps.getNumElements() * 3) + ps.getOffset()) // 3 float
        // VertexBuffer ips = m.getBuffer(VertexBuffer.Type.Normal);
        for (var int ii = 0; b && ii < iis.size(); ii++) {
            var int i = iis.get(ii)
            b = b && i < ps.getNumElements() && i > -1
        }
        return b
    }

}