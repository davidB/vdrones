package vdrones;

import com.jme3.app.SimpleApplication;
import com.jme3.asset.AssetManager;
import com.jme3.asset.TextureKey;
import com.jme3.bullet.control.RigidBodyControl;
import com.jme3.input.ChaseCamera;
import com.jme3.light.AmbientLight;
import com.jme3.light.DirectionalLight;
import com.jme3.material.Material;
import com.jme3.math.ColorRGBA;
import com.jme3.math.Vector2f;
import com.jme3.math.Vector3f;
import com.jme3.renderer.RenderManager;
import com.jme3.scene.Geometry;
import com.jme3.scene.Node;
import com.jme3.scene.shape.Box;
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
        Box shape = new Box(10f, 0.1f, 5f);
        shape.scaleTextureCoordinates(new Vector2f(3, 6));

        Material mat = new Material(assetManager, "Common/MatDefs/Misc/Unshaded.j3md");
        TextureKey key3 = new TextureKey("Textures/Terrain/Pond/Pond.jpg");
        key3.setGenerateMips(true);
        Texture tex3 = assetManager.loadTexture(key3);
        tex3.setWrap(WrapMode.Repeat);
        mat.setTexture("ColorMap", tex3);

        Geometry geo = new Geometry("Floor", shape);
        geo.setMaterial(mat);
        geo.setLocalTranslation(0, -1.0f, 0);


        /* Make the floor physical with mass 0.0f! */
        RigidBodyControl phy0 = new RigidBodyControl(0.0f);
        geo.addControl(phy0);
        List phy = new ArrayList();
        phy.add(phy0);
        Node area = new Node("area");
        DirectionalLight light = new DirectionalLight();
        light.setDirection(new Vector3f(-0.5f, -0.5f, -0.5f));
        area.addLight(light);
        AmbientLight light0 = new AmbientLight();
        light0.setColor(ColorRGBA.Pink);
        area.addLight(light0);
        area.attachChild(geo);
        return new EntityComponent[]{new CGeoPhy(area, phy)};
    }
}
