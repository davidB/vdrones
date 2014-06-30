package vdrones;

import com.jme3.app.SimpleApplication;
import com.jme3.asset.AssetManager;
import com.jme3.light.DirectionalLight;
import com.jme3.light.Light;
import com.jme3.renderer.ViewPort;
import com.jme3.scene.Node;
import com.jme3.scene.Spatial;
import lombok.extern.slf4j.Slf4j;

/**
 *
 * @author dwayne
 */
@Slf4j
public class AppStateLevelLoader extends AppState0 {
    public final static int SHADOWMAP_SIZE = 2048;
    
    private SimpleApplication sapp;
    private Node rootNode;
    private Spatial scene0;
    private EntityFactory factory;
    
    @Override
    protected void enable() {
        sapp = injector.getInstance(SimpleApplication.class);
        factory = injector.getInstance(EntityFactory.class);
        rootNode = sapp.getRootNode();
        Spatial scene = rootNode.getChild("scene");
        log.info(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> {}", rootNode.getQuantity());
        for(Spatial s : rootNode.getChildren()) {
            log.info("child {} / {}", s.getName(), s);
        }
        try {
            if (scene != null) {
                loadLevel(factory.newLevel(scene), false);
            }
        } catch(Exception exc) {
            exc.printStackTrace();
        }
    }

    public Spatial loadLevel(Spatial level, boolean updateLights) {
        unloadLevel();
        scene0 = level;
        //rootNode.attachChild(scene0);
        AppStateGeoPhy gp = sapp.getStateManager().getState(AppStateGeoPhy.class);
        log.warn("try to loadLevel 'scene' in {}", gp);
        if (gp != null) gp.toAdd.offer(scene0);
        if (updateLights) initLights(scene0, rootNode, sapp.getAssetManager(), sapp.getViewPort());
        return scene0;
    }

    public void unloadLevel() {
        AppStateGeoPhy gp = sapp.getStateManager().getState(AppStateGeoPhy.class);
        if (gp != null && scene0 != null) gp.toRemove.offer(scene0);
        //TODO remove lights
    }
    
    @Override
    public void update(float tpf) {
    }
    
    @Override
    public void disable() {
        unloadLevel();
    }
    
    /**
     * Move lights from src (ex: area) to dest (ex: rootNode) and enable shadow for directinalLigths
     */
    void initLights(Spatial src, Spatial dest, AssetManager assetManager, ViewPort viewPort) {
        dest.getLocalLightList().clear();
        AppStateShadow shadows = sapp.getStateManager().getState(AppStateShadow.class);
        if (shadows != null) shadows.reset();
        for (Light l : src.getLocalLightList()) {
            dest.addLight(l);
            if (shadows != null && l instanceof DirectionalLight) {
                shadows.addLight((DirectionalLight)l);
            }
        }
        src.getLocalLightList().clear();
    }
/*
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
        dlsf.setEnabled(true);

        SSAOFilter ssaoFilter = new SSAOFilter(0.2f, 5.0f, 0.05f, 0.3f);

        FilterPostProcessor fpp = new FilterPostProcessor(assetManager);
        fpp.addFilter(dlsf);
        //fpp.addFilter(ssaoFilter);

        viewPort.addProcessor(fpp);
    }
*/
}

