package vdrones

import com.jme3.light.DirectionalLight
import com.jme3.light.Light
import com.jme3.post.FilterPostProcessor
import com.jme3.post.filters.LightScatteringFilter
import com.jme3.post.ssao.SSAOFilter
import com.jme3.renderer.ViewPort
import com.jme3.scene.Node
import com.jme3.shadow.DirectionalLightShadowFilter
import com.jme3.shadow.EdgeFilteringMode
import javax.inject.Inject
import jme3_ext.AppState0

/** 
 * @author davidB
 */
class AppStateLights extends AppState0 {
    FilterPostProcessor fpp
    Node rootNode

    override protected void doInitialize() {
        fpp = new FilterPostProcessor(app.getAssetManager())
        rootNode = app.getRootNode()
    }

    override protected void doEnable() {
        var ViewPort viewport = app.getViewPort()
        viewport.addProcessor(fpp)
    }

    override protected void doDisable() {
        var ViewPort viewport = app.getViewPort()
        viewport.removeProcessor(fpp)
    }

    override protected void doDispose() {
        fpp = null
    }

    def void addLight(Light l) {
        rootNode.addLight(l)
        if (l instanceof DirectionalLight) {
            addFx(l)
        }

    }

    def private void addFx(DirectionalLight l) {
        // Setup shadows
        // -------------------------------------
        var DirectionalLightShadowFilter shadows = new DirectionalLightShadowFilter(app.getAssetManager(), 4096, 4)
        shadows.setShadowIntensity(0.6f)
        shadows.setLambda(0.55f)
        shadows.setShadowIntensity(0.6f)
        shadows.setEdgeFilteringMode(EdgeFilteringMode.Nearest)
        shadows.setLight(l)
        shadows.setEnabled(true)
        fpp.addFilter(shadows) // Setup light scattering
        // --------------------------------------
        var LightScatteringFilter lightScattering = new LightScatteringFilter()
        lightScattering.setLightDensity(1)
        lightScattering.setBlurWidth(1.1f)
        lightScattering.setEnabled(true)
        fpp.addFilter(lightScattering)
        lightScattering.setLightPosition(l.getDirection().mult(-300))
    }

    def void removeLight(Light l) {
        rootNode.removeLight(l)
        if (l instanceof DirectionalLight) {
            removeFx(l)
        }

    }

    def private void removeFx(DirectionalLight l) {
        // TODO remove only lights
    }

    def package void reset() {
        fpp.removeAllFilters() // SSAO
        // --------------------------------------
        var SSAOFilter ssao = new SSAOFilter(0.2f, 5.0f, 0.05f, 0.3f)
        ssao.setEnabled(true)
        fpp.addFilter(ssao)
    }

    @Inject
    new() {}

}
