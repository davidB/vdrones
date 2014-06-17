package vdrones;

import com.jme3.app.Application;
import com.jme3.asset.AssetManager;
import com.jme3.post.FilterPostProcessor;
import com.jme3.post.filters.BloomFilter;
import com.jme3.post.filters.DepthOfFieldFilter;
import com.jme3.post.filters.FXAAFilter;
import com.jme3.renderer.ViewPort;
import com.jme3.system.AppSettings;
import com.simsilica.lemur.event.BaseAppState;

/**
 * @author davidB
 */
public class AppStatePostProcessing extends BaseAppState {
    private FilterPostProcessor fpp;
    
    @Override
    protected void initialize(Application app) {
        AssetManager assets = app.getAssetManager();
        AppSettings settings = app.getContext().getSettings();
        fpp = new FilterPostProcessor(assets);
 
        // See if sampling is enabled
        boolean aa = settings.getSamples() != 0;
        if( aa ) {
            fpp.setNumSamples(settings.getSamples());
        }

        // Setup Bloom
        //--------------------------------------
        BloomFilter bloom = new BloomFilter();
        bloom.setEnabled(true);
        bloom.setExposurePower(55);
        bloom.setBloomIntensity(1.0f);
        fpp.addFilter(bloom);
            
        // Setup FXAA only if regular AA is off
        //--------------------------------------
        if( !aa ) {
            FXAAFilter fxaa = new FXAAFilter();
            fxaa.setEnabled(true);
            fpp.addFilter(fxaa);
        }
        
        // And finally DoF                      
        //--------------------------------------
        DepthOfFieldFilter dof = new DepthOfFieldFilter();
        dof.setFocusDistance(0);
        dof.setFocusRange(384);
        dof.setEnabled(true);            
        //fpp.addFilter(dof);
    }

    @Override
    protected void cleanup(Application aplctn) {
        fpp = null;
    }

    @Override
    protected void enable() {
        ViewPort viewport = getApplication().getViewPort();
        viewport.addProcessor(fpp);
    }

    @Override
    protected void disable() {
        ViewPort viewport = getApplication().getViewPort();
        viewport.removeProcessor(fpp);
    }
    
}
