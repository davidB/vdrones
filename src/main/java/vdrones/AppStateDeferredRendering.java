package vdrones;

import javax.inject.Inject;

import jme3_ext.AppState0;
import jme3_ext_deferred.SceneProcessor4Deferred;
import lombok.RequiredArgsConstructor;
import rx_ext.Observable4AddRemove;

import com.jme3.scene.Geometry;

@RequiredArgsConstructor(onConstructor=@__(@Inject))
public class AppStateDeferredRendering extends AppState0 {
	final SceneProcessor4Deferred processor;

	Observable4AddRemove<Geometry> olights(){return  processor.lights.ar;}

	protected void doEnable() {
		app.getViewPort().addProcessor(processor);
	}

}
