package vdrones;

import com.jme3.app.SimpleApplication;
import com.jme3.asset.AssetManager;
import com.jme3.asset.TextureKey;
import com.jme3.bullet.collision.shapes.CollisionShape;
import com.jme3.bullet.control.RigidBodyControl;
import com.jme3.bullet.util.CollisionShapeFactory;
import com.jme3.input.ChaseCamera;
import com.jme3.light.AmbientLight;
import com.jme3.light.DirectionalLight;
import com.jme3.light.PointLight;
import com.jme3.material.Material;
import com.jme3.math.ColorRGBA;
import com.jme3.math.Vector2f;
import com.jme3.math.Vector3f;
import com.jme3.post.FilterPostProcessor;
import com.jme3.post.ssao.SSAOFilter;
import com.jme3.renderer.RenderManager;
import com.jme3.renderer.ViewPort;
import com.jme3.renderer.queue.RenderQueue;
import com.jme3.scene.Geometry;
import com.jme3.scene.Node;
import com.jme3.scene.shape.Box;
import com.jme3.shadow.DirectionalLightShadowFilter;
import com.jme3.shadow.DirectionalLightShadowRenderer;
import com.jme3.shadow.EdgeFilteringMode;
import com.jme3.texture.Texture;
import com.jme3.texture.Texture.WrapMode;
import com.simsilica.es.EntityComponent;
import com.simsilica.es.EntityData;
import com.simsilica.es.EntityId;
import com.simsilica.es.base.DefaultEntityData;
import java.util.ArrayList;
import java.util.List;

/**
 * test
 *
 * @author normenhansen
 */
public class Main extends SimpleApplication {

    public static final int SHADOWMAP_SIZE = 2048;

    public static void main(String[] args) {
        Main app = new Main();
        app.start();
    }
    public final EntityData entityData;
    private boolean spawned = false;
    private ChaseCamera chaseCam;

    public Main() {
        //Create a new Entity System
        entityData = new DefaultEntityData();
    }

    @Override
    public void simpleInitApp() {
        setDisplayStatView(true);
        setDisplayFps(true);

        viewPort.setBackgroundColor(ColorRGBA.Pink);
        //flyCam.setEnabled(false);

        stateManager.attach(new AppStateCamera());
        stateManager.attach(new AppStateInput());
        stateManager.attach(new AppStateDrone());
        stateManager.attach(new AppStateGeoPhy());
        spawned = false;
    }

    @Override
    public void simpleUpdate(float tpf) {
        if (!spawned) {
            spawned = true;
            EntityId droneId = entityData.createEntity();
            entityData.setComponents(droneId, VDrone.newDrone(assetManager));
            entityData.setComponents(droneId, new CDroneInfo(), new CDroneInput(), new CCameraFollower(CCameraFollower.Mode.TPS));
            entityData.setComponents(entityData.createEntity(), newArea(assetManager));
            initLights(rootNode, assetManager, viewPort);
        }
    }

    @Override
    public void simpleRender(RenderManager rm) {
        //TODO: add render code
    }

    /**
     * Make a solid floor and add it to the scene.
     */
    static EntityComponent[] newArea(AssetManager assetManager) {
        Node area = new Node("area");

        Material mat = assetManager.loadMaterial("Materials/Mat1.j3m");
        mat.setColor("Diffuse", ColorRGBA.White);
        mat.setColor("Specular", ColorRGBA.White);
        Box shape = new Box(10f, 0.1f, 5f);
        Geometry geo = new Geometry("Floor", shape);
        //geo.setMaterial(mat);
        //geo.setLocalTranslation(0, -1.0f, 0);
        geo.setShadowMode(RenderQueue.ShadowMode.Receive);
        area.attachChild(geo);

        Geometry geo2 = new Geometry("box0", new Box(2.f, 1f, 3f));
        geo2.setLocalTranslation(0f, 1f, 4f);
        //geo2.setMaterial(mat);
        geo2.setShadowMode(RenderQueue.ShadowMode.CastAndReceive);
        area.attachChild(geo2);

        area.setLocalTranslation(0f, -1.0f, 0f);
        area.setMaterial(mat);

        CollisionShape cshape = CollisionShapeFactory.createMeshShape(area);
        /* Make the floor physical with mass 0.0f! */
        RigidBodyControl phy0 = new RigidBodyControl(cshape, 0.0f);
        geo.addControl(phy0);
        List phy = new ArrayList();
        phy.add(phy0);

        return new EntityComponent[]{new CGeoPhy(area, phy)};
    }

    static void initLights(Node area, AssetManager assetManager, ViewPort viewPort) {
        DirectionalLight light = new DirectionalLight();
        light.setDirection(new Vector3f(-1, -1, -1).normalizeLocal());
        light.setColor(ColorRGBA.White.multLocal(1.0f));
        area.addLight(light);
        shadow(light, assetManager, viewPort);

        AmbientLight light0 = new AmbientLight();
        light0.setColor(ColorRGBA.White.mult(0.4f));
        area.addLight(light0);

        PointLight light1 = new PointLight();
        light1.setColor(ColorRGBA.White.multLocal(4.0f));
        light1.setRadius(1f);
        light1.setPosition(new Vector3f(0.0f, 3.0f, 0.0f));
        //area.addLight(light1);
    }

    static void shadow(DirectionalLight l, AssetManager assetManager, ViewPort viewPort) {
        DirectionalLightShadowRenderer dlsr = new DirectionalLightShadowRenderer(assetManager, SHADOWMAP_SIZE, 3);
        dlsr.setLight(l);
        //dlsr.setLambda(0.55f);
        //dlsr.setShadowIntensity(0.6f);
        //dlsr.setEdgeFilteringMode(EdgeFilteringMode.Nearest);
        //dlsr.displayDebug();
        viewPort.addProcessor(dlsr);

        DirectionalLightShadowFilter dlsf = new DirectionalLightShadowFilter(assetManager, SHADOWMAP_SIZE, 3);
        dlsf.setLight(l);
        dlsf.setLambda(0.55f);
        dlsf.setShadowIntensity(0.6f);
        dlsf.setEdgeFilteringMode(EdgeFilteringMode.Nearest);
        dlsf.setEnabled(false);

        SSAOFilter ssaoFilter = new SSAOFilter(0.2f, 5.0f, 0.05f, 0.3f);

        FilterPostProcessor fpp = new FilterPostProcessor(assetManager);
        fpp.addFilter(dlsf);
        fpp.addFilter(ssaoFilter);

        viewPort.addProcessor(fpp);
    }
}
