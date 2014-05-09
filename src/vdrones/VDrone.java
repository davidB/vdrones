package vdrones;

import com.jme3.asset.AssetManager;
import com.jme3.bullet.collision.shapes.CollisionShape;
import com.jme3.bullet.control.RigidBodyControl;
import com.jme3.material.Material;
import com.jme3.math.ColorRGBA;
import com.jme3.math.Vector3f;
import com.jme3.scene.Geometry;
import com.jme3.scene.Mesh;
import com.jme3.scene.VertexBuffer;
import java.nio.FloatBuffer;
import java.util.ArrayList;
import java.util.List;
import com.jme3.bullet.joints.SliderJoint;
import com.jme3.bullet.util.CollisionShapeFactory;
import com.jme3.export.JmeExporter;
import com.jme3.export.JmeImporter;
import com.jme3.renderer.RenderManager;
import com.jme3.renderer.ViewPort;
import com.jme3.scene.Spatial;
import com.jme3.scene.control.Control;
import java.io.IOException;

public class VDrone {
    ////////////////////////////////////////////////////////////////////////////
    // CLASS
    ////////////////////////////////////////////////////////////////////////////

    static final int DRONE_PCENTER = 0;
    static final int DRONE_PFRONT = 1;
    static final int DRONE_PBACKR = 2;
    static final int DRONE_PBACKL = 3;
    static final Vector3f[] vertices = {
        new Vector3f(0, 1, 0), new Vector3f(2, 0, 0), new Vector3f(-1, 0, -1), new Vector3f(-1, 0, 1)
    };

    static CGeoPhy newDrone(AssetManager assetManager) {
        Spatial geom = newGeometry(assetManager);
        List<Object> phy = newPhysics(geom);
        CGeoPhy b = new CGeoPhy(geom, phy);
        return b;
    }

    static Spatial newGeometry(AssetManager assetManager) {
        Spatial geom = assetManager.loadModel("Models/drone.j3o");

//        Material mat = assetManager.loadMaterial("Materials/Mat1.j3m");
//        mat.setColor("Diffuse", new ColorRGBA(0.118f, 0.118f, 0.545f, 0.25f));
//        geom.setMaterial(mat);

        return geom;
    }

    /*
     static Geometry newGeometry(AssetManager assetManager) {
     int[] indices = {
     DRONE_PFRONT, DRONE_PBACKR, DRONE_PBACKL,
     DRONE_PCENTER, DRONE_PBACKL, DRONE_PBACKR,
     DRONE_PCENTER, DRONE_PBACKR, DRONE_PFRONT,
     DRONE_PCENTER, DRONE_PFRONT, DRONE_PBACKL
     };
     float[] uv = new float[indices.length * 2 / 3];
     uv[DRONE_PFRONT * 2 + 0] = 0.5f;
     uv[DRONE_PFRONT * 2 + 1] = 0.0f;
     uv[DRONE_PCENTER * 2 + 0] = 0.5f;
     uv[DRONE_PCENTER * 2 + 1] = 0.75f;
     uv[DRONE_PBACKR * 2 + 0] = 1.0f;
     uv[DRONE_PBACKR * 2 + 1] = 1.0f;
     uv[DRONE_PBACKL * 2 + 0] = 0.0f;
     uv[DRONE_PBACKL * 2 + 1] = 1.0f;

     //float[] normals = new float[indices.length * 3]

     Mesh mesh = new Mesh();
     mesh.setMode(Mesh.Mode.Triangles);
     mesh.setBuffer(VertexBuffer.Type.Position, 3, BufferUtils.createFloatBuffer(vertices));
     //mesh.setBuffer(VertexBuffer.Type.Normal, 3, BufferUtils.createFloatBuffer(normals));
     mesh.setBuffer(VertexBuffer.Type.TexCoord, 2, BufferUtils.createFloatBuffer(uv));
     mesh.setBuffer(VertexBuffer.Type.Index, 3, BufferUtils.createIntBuffer(indices));
     mesh.updateBound();

     Geometry geom = new Geometry("vdroneMesh", mesh);
     Material mat = new Material(assetManager, "Common/MatDefs/Misc/Unshaded.j3md");
     //mat.getAdditionalRenderState().setFaceCullMode(RenderState.FaceCullMode.Front);
     mat.setColor("Color", new ColorRGBA(0.118f, 0.118f, 0.545f, 0.25f));
     //mat.setBoolean("VertexColor", true);
     //mat.getAdditionalRenderState().setBlendMode(RenderState.BlendMode.AlphaAdditive);
     geom.setMaterial(mat);

     return geom;
     }
     */
    static List<Object> newPhysics(Spatial spatial) {
        ArrayList<Object> b = new ArrayList<>(1);
        CollisionShape shape = CollisionShapeFactory.createDynamicMeshShape(spatial);
        RigidBodyControl ctrl = new RigidBodyControl(shape, 4.0f);
        b.add(ctrl);
        spatial.addControl(ctrl);
        return b;
    }
    /*
     static List<Object> newPhysics(Spâtial spatial) {
     ArrayList<Object> b = new ArrayList<Object>(4 + 6);
     for (int i = 0; i < 4; i++) {
     SphereCollisionShape shape = new SphereCollisionShape(0.1f);
     RigidBodyControl ctrl = new RigidBodyControl(shape, 1.0f);
     ctrl.setPhysicsLocation(vertices[i]);
     b.add(ctrl);
     }
     for (int i = 0; i < 3; i++) {
     for (int j = i + 1; j < 4; j++) {
     b.add(join(b, i, j));
     }
     }
     DronePhyGeom c = new DronePhyGeom();
     c.points = new RigidBodyControl[]{
     (RigidBodyControl) phy.get(0), (RigidBodyControl) phy.get(1), (RigidBodyControl) phy.get(2), (RigidBodyControl) phy.get(3)
     };
     spatial.addControl(c);
     return b;
     }
     */
    /*
     static Object join(ArrayList<Object> b, int i, int j) {
     RigidBodyControl ri = (RigidBodyControl)b.get(i);
     RigidBodyControl rj = (RigidBodyControl)b.get(j);
     SixDofJoint joint = new SixDofJoint(ri, rj, Vector3f.ZERO, Vector3f.ZERO, Matrix3f.IDENTITY, Matrix3f.IDENTITY, true);
     //joint.setCollisionBetweenLinkedBodys(false);
     Vector3f v = ri.getPhysicsLocation().subtract(rj.getPhysicsLocation());
     //joint.setLinearLowerLimit(v.mult(0.5f));
     joint.setLinearUpperLimit(v.mult(0.8f));
     return joint;
     }
     */
    /*
     static Object join(ArrayList<Object> b, int i, int j) {
     RigidBodyControl ri = (RigidBodyControl)b.get(i);
     RigidBodyControl rj = (RigidBodyControl)b.get(j);
     ConeJoint joint = new ConeJoint(ri, rj, Vector3f.ZERO, Vector3f.ZERO);
     //joint.setCollisionBetweenLinkedBodys(false);
     Vector3f v = ri.getPhysicsLocation().subtract(rj.getPhysicsLocation());
     //joint.setLinearLowerLimit(v.mult(0.5f));
     joint.setLimit(1.0f,1.0f,0);
     return joint;
     }
     */

    static Object join(ArrayList<Object> b, int i, int j) {
        RigidBodyControl ri = (RigidBodyControl) b.get(i);
        RigidBodyControl rj = (RigidBodyControl) b.get(j);
        SliderJoint joint = new SliderJoint(ri, rj, Vector3f.ZERO, Vector3f.ZERO, true);
        //joint.setCollisionBetweenLinkedBodys(false);
        Vector3f v = ri.getPhysicsLocation().subtract(rj.getPhysicsLocation());
        //joint.setLinearLowerLimit(v.mult(0.5f));
        //joint.setLimit(1.0f,1.0f,0);
        return joint;
    }
}

class DronePhyGeom implements Control {

    Geometry geom;
    RigidBodyControl[] points;

    @Override
    public Control cloneForSpatial(Spatial spatial) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    public void setSpatial(Spatial spatial) {
        geom = (Geometry) spatial;
    }

    @Override
    public void update(float tpf) {
        Mesh mesh = geom.getMesh();
        VertexBuffer buf0 = mesh.getBuffer(VertexBuffer.Type.Position);
        for (int i = 0; i < 4; i++) {
            //float y = 3.0f + (float)Math.sin(cumul) * 2.0f;
            //buf0.setElementComponent(DRONE_PCENTER, 1, y);
            Vector3f pos = points[i].getPhysicsLocation();
            FloatBuffer buf = (FloatBuffer) buf0.getData();
            buf.put(i * 3 + 0, pos.x);
            buf.put(i * 3 + 1, pos.y);
            buf.put(i * 3 + 2, pos.z);
        }
        buf0.setUpdateNeeded();
        mesh.updateBound();
        geom.updateModelBound();
    }

    @Override
    public void render(RenderManager rm, ViewPort vp) {
        //throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    public void write(JmeExporter ex) throws IOException {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    public void read(JmeImporter im) throws IOException {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }
}
