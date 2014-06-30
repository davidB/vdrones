package vdrones;

import com.jme3.app.Application;
import com.jme3.app.state.AbstractAppState;
import com.jme3.app.state.AppStateManager;
import com.jme3.asset.AssetManager;
import com.jme3.light.DirectionalLight;
import com.jme3.post.FilterPostProcessor;
import com.jme3.post.filters.LightScatteringFilter;
import com.jme3.post.ssao.SSAOFilter;
import com.jme3.renderer.ViewPort;
import com.jme3.shadow.DirectionalLightShadowFilter;
import com.jme3.shadow.EdgeFilteringMode;

/**
 * @author davidB
 */
public class AppStateShadow extends AppState0 {
    private FilterPostProcessor fpp;

    @Override
    protected void initialize() {
        fpp = new FilterPostProcessor(injector.getInstance(AssetManager.class));
    }
    
    @Override
    protected void enable() {
        ViewPort viewport = injector.getInstance(Application.class).getViewPort();
        viewport.addProcessor(fpp);
    }

    @Override
    protected void disable() {
        ViewPort viewport = injector.getInstance(Application.class).getViewPort();
        viewport.removeProcessor(fpp);
    }
    
    @Override
    protected void dispose() {
        fpp = null;
    }
    
    public void addLight(DirectionalLight l) {
      
        // Setup shadows
        //-------------------------------------
        DirectionalLightShadowFilter shadows = new DirectionalLightShadowFilter(injector.getInstance(AssetManager.class), 4096, 4);
        shadows.setShadowIntensity(0.6f); 
        shadows.setLambda(0.55f);
        shadows.setShadowIntensity(0.6f);
        shadows.setEdgeFilteringMode(EdgeFilteringMode.Nearest);
        shadows.setLight(l);
        shadows.setEnabled(true);
        fpp.addFilter(shadows);
        
        // Setup light scattering
        //--------------------------------------
        LightScatteringFilter lightScattering = new LightScatteringFilter();
        lightScattering.setLightDensity(1);
        lightScattering.setBlurWidth(1.1f);
        lightScattering.setEnabled(true);
        fpp.addFilter(lightScattering);
        
        lightScattering.setLightPosition(l.getDirection().mult(-300));
    }

    void reset() {
        fpp.removeAllFilters();
        
        // SSAO
        //--------------------------------------
        SSAOFilter ssao = new SSAOFilter(0.2f, 5.0f, 0.05f, 0.3f);
        ssao.setEnabled(true);
        fpp.addFilter(ssao);
    }
    
}
