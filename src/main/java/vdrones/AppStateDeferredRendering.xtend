package vdrones

import javax.inject.Inject
import jme3_ext.AppState0
import jme3_ext_deferred.SceneProcessor4Deferred
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

class AppStateDeferredRendering extends AppState0 {
    val SceneProcessor4Deferred processor

    // TODO remove deferred		
    // Observable4AddRemove<Geometry> olights(){return  processor.lights.ar;}
    override protected void doEnable() {
        app.getViewPort().addProcessor(processor)
    }

    override protected void doDisable() {
        app.getViewPort().removeProcessor(processor)
    }

    @Inject
    @FinalFieldsConstructor
    new(){}
}
