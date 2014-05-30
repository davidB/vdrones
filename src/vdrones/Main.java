package vdrones;

import com.jme3.app.SimpleApplication;
import com.jme3.asset.AssetManager;
import com.jme3.input.ChaseCamera;
import com.jme3.light.AmbientLight;
import com.jme3.light.DirectionalLight;
import com.jme3.math.ColorRGBA;
import com.jme3.math.Vector3f;
import com.jme3.post.FilterPostProcessor;
import com.jme3.post.ssao.SSAOFilter;
import com.jme3.renderer.RenderManager;
import com.jme3.renderer.ViewPort;
import com.jme3.scene.Node;
import com.jme3.scene.Spatial;
import com.jme3.shadow.DirectionalLightShadowFilter;
import com.jme3.shadow.DirectionalLightShadowRenderer;
import com.jme3.shadow.EdgeFilteringMode;

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
    private boolean spawned = false;
    private ChaseCamera chaseCam;

    public Main() {
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
            Spatial vd = VDrone.newDrone(assetManager);
            CDroneInfo info = new CDroneInfo();
            vd.setUserData(CDroneInfo.K, info);
            stateManager.getState(AppStateInput.class).setDroneInfo(info);
            stateManager.getState(AppStateDrone.class).entity = vd;
            stateManager.getState(AppStateCamera.class).target = vd;
            stateManager.getState(AppStateCamera.class).follower = new CameraFollower(CameraFollower.Mode.TPS);
            stateManager.getState(AppStateGeoPhy.class).toAdd.offer(vd);
            Spatial area = newArea(assetManager);
            stateManager.getState(AppStateGeoPhy.class).toAdd.offer(area);

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
    static Spatial newArea(AssetManager assetManager) {
        Node area = new Node("area");
        Spatial n = assetManager.loadModel("Scenes/area0.j3o");
        area.attachChild(n);
        return area;
    }

    static void initLights(Node anchor, AssetManager assetManager, ViewPort viewPort) {
        AmbientLight light0 = new AmbientLight();
        light0.setColor(ColorRGBA.White.mult(0.4f));
        anchor.addLight(light0);

        DirectionalLight light = new DirectionalLight();
        light.setDirection(new Vector3f(-1, -1, -1).normalizeLocal());
        light.setColor(ColorRGBA.White.multLocal(.9f));
        anchor.addLight(light);
        shadow(light, assetManager, viewPort);
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
        //fpp.addFilter(ssaoFilter);

        viewPort.addProcessor(fpp);
    }
}
