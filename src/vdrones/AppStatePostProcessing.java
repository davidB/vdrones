package vdrones;

import com.jme3.app.Application;
import com.jme3.asset.AssetManager;
import com.jme3.post.FilterPostProcessor;
import com.jme3.post.filters.BloomFilter;
import com.jme3.post.filters.DepthOfFieldFilter;
import com.jme3.post.filters.FXAAFilter;
import com.jme3.renderer.ViewPort;
import com.jme3.system.AppSettings;

/**
 * @author davidB
 */
public class AppStatePostProcessing extends AppState0 {
    private FilterPostProcessor fpp;
    
    @Override
    protected void doInitialize() {
        AssetManager assets = injector.getInstance(AssetManager.class);
        AppSettings settings = injector.getInstance(Application.class).getContext().getSettings();
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
    protected void doDispose() {
        fpp = null;
    }

    @Override
    protected void doEnable() {
        ViewPort viewport = injector.getInstance(Application.class).getViewPort();
        viewport.addProcessor(fpp);
    }

    @Override
    protected void doDisable() {
        ViewPort viewport = injector.getInstance(Application.class).getViewPort();
        viewport.removeProcessor(fpp);
    }
    
}
