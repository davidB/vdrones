package vdrones

import com.jme3.asset.AssetManager
import com.jme3.post.FilterPostProcessor
import com.jme3.post.filters.BloomFilter
import com.jme3.post.filters.DepthOfFieldFilter
import com.jme3.post.filters.FXAAFilter
import com.jme3.renderer.ViewPort
import com.jme3.system.AppSettings
import javax.inject.Inject
import jme3_ext.AppState0
import org.slf4j.LoggerFactory

/** 
 * @author davidB
 */
class AppStatePostProcessing extends AppState0 {
    val log = LoggerFactory.getLogger(AppStatePostProcessing)
    FilterPostProcessor fpp

    override protected void doInitialize() {
        var AssetManager assets = app.getAssetManager()
        var AppSettings settings = app.getContext().getSettings()
        fpp = new FilterPostProcessor(assets) // Setup Bloom
        // --------------------------------------
        var BloomFilter bloom = new BloomFilter()
        bloom.setEnabled(false)
        bloom.setExposurePower(55)
        bloom.setBloomIntensity(1.0f)
        fpp.addFilter(bloom) // Setup FXAA only if regular AA is off
        // --------------------------------------
        // See if sampling is enabled
        var boolean aa = settings.getSamples() !== 0
        log.info("antialias enabling : {}", aa)
        if (aa) {
            fpp.setNumSamples(settings.getSamples())
        }
        var FXAAFilter fxaa = new FXAAFilter()
        fxaa.setEnabled(!aa)
        fpp.addFilter(fxaa) // And finally DoF
        // --------------------------------------
        var DepthOfFieldFilter dof = new DepthOfFieldFilter()
        dof.setEnabled(false)
        dof.setFocusDistance(5)
        dof.setFocusRange(192)
        fpp.addFilter(dof)
    }

    override protected void doDispose() {
        fpp.cleanup()
        fpp = null
    }

    override protected void doEnable() {
        var ViewPort viewport = app.getViewPort()
        viewport.addProcessor(fpp)
    }

    override protected void doDisable() {
        var ViewPort viewport = app.getViewPort()
        viewport.removeProcessor(fpp)
    }

    @Inject
    new() {
    }

}
