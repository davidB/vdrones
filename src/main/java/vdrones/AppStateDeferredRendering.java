package vdrones;

import javax.inject.Inject;

import jme3_ext.AppState0;
import jme3_ext_deferred.SceneProcessor4Deferred;
import lombok.RequiredArgsConstructor;

@RequiredArgsConstructor(onConstructor=@__(@Inject))
public class AppStateDeferredRendering extends AppState0 {
	final SceneProcessor4Deferred processor;

	//TODO remove deferred		
	//Observable4AddRemove<Geometry> olights(){return  processor.lights.ar;}

	protected void doEnable() {
		app.getViewPort().addProcessor(processor);
	}

	protected void doDisable() {
		app.getViewPort().removeProcessor(processor);
	}
}
