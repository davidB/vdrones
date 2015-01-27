package vdrones;

import javax.inject.Inject;

import jme3_ext.AppState0;
import jme3_ext.AudioManager;
import lombok.RequiredArgsConstructor;

import com.jme3.app.state.AppStateManager;
import com.jme3.audio.AudioNode;
import com.jme3.material.RenderState;
import com.jme3.math.ColorRGBA;
import com.jme3.math.Quaternion;
import com.jme3.math.Vector3f;
import com.jme3.renderer.Camera;
import com.jme3.renderer.RenderManager;
import com.jme3.renderer.ViewPort;
import com.jme3.scene.Geometry;
import com.jme3.scene.Node;
import com.jme3.scene.SceneGraphVisitorAdapter;
import com.jme3.scene.Spatial;
import com.jme3.scene.control.AbstractControl;
import com.jme3.util.SkyFactory;

@RequiredArgsConstructor(onConstructor=@__(@Inject))
public class AppStateGarage extends AppState0{
	final AppStatePostProcessing appPostProcessing;
	final AppStateDeferredRendering appDeferredRendering;
	//final AppStateDebug appDebug;
	final EntityFactory entityFactory;
	final AudioManager audioMgr;
	private Node scene;
	private AudioNode audioBg;

	@Override
	protected void doInitialize() {
		AppStateManager stateManager = app.getStateManager();
		app.getViewPort().setBackgroundColor(ColorRGBA.White);
		stateManager.attach(appDeferredRendering);
		stateManager.attach(appPostProcessing);
		//stateManager.attach(appDebug);
	}

	protected void doDispose() {
		AppStateManager stateManager = app.getStateManager();
		//stateManager.detach(appDebug);
		stateManager.detach(appDeferredRendering);
		stateManager.detach(appPostProcessing);
	}

	protected void doEnable() {
		//app.getViewPort().clearScenes();
		scene = makeScene();
		app.getRootNode().attachChild(scene);
		Camera cam = app.getViewPort().getCamera();
		cam.setLocation(new Vector3f(0,3,-8).mult(0.8f));
		cam.lookAt(scene.getWorldTranslation(), Vector3f.UNIT_Y);
		if (audioBg != null) {
			audioBg.play();
		}
	}

	protected void doDisable() {
		if (audioBg != null) {
			audioBg.pause();
			audioBg.removeFromParent();
			audioBg = null;
		}
		if (scene != null) {
			scene.removeFromParent();
			scene = null;
		}
	}

	Node makeScene() {
		Node scene = new Node("garage");
		scene.attachChild(SkyFactory.createSky(app.getAssetManager(), "Textures/sky0.jpg", true));
		audioBg = makeAudioBg();
		scene.attachChild(audioBg);
		scene.attachChild(makeDrone());
		return scene;
	}
	Node makeDrone() {
		Node drone = new Node("drone");
		entityFactory.asDrone(drone);
		drone.breadthFirstTraversal(new SceneGraphVisitorAdapter(){
			public void visit(Geometry geom) {
				RenderState r = geom.getMaterial().getAdditionalRenderState();
				r.setWireframe(true);
				geom.getMaterial().setColor("Color", new ColorRGBA(0.137f,0.137f,0.152f,0.8f));
			}
		});
//		Quaternion q = new Quaternion(0,1,0,1);
//		q.normalizeLocal();
//		drone.setLocalRotation(q.multLocal(drone.getLocalRotation()).normalizeLocal());

		drone.getChild("model").addControl(new AbstractControl() {
			Quaternion q = new Quaternion();
			Quaternion rot0;
			@Override
			public void setSpatial(Spatial spatial) {
				super.setSpatial(spatial);
				if (spatial  != null) {
					rot0 = spatial.getLocalRotation();
				}
			}
			@Override
			protected void controlUpdate(float tpf) {
				//Quaternion q = new Quaternion(0,1,0,tpf*0.1f);
				//q.normalizeLocal();
				//getSpatial().setLocalRotation(q.multLocal(getSpatial().getLocalRotation()).normalizeLocal());
				q.slerp(Quaternion.IDENTITY, new Quaternion(0,1,0,-1).normalizeLocal(), tpf);
				rot0.multLocal(q);
				getSpatial().setLocalRotation(rot0);
			}

			@Override
			protected void controlRender(RenderManager rm, ViewPort vp) {
			}
		});
		return drone;
	}

	AudioNode makeAudioBg() {
		AudioNode audioBg = new AudioNode(app.getAssetManager(), "Musics/Hypnothis.ogg", false);
		audioBg.setName("audioBg");
		audioBg.setLooping(true);
		audioBg.setPositional(false);
		audioMgr.musics.add(audioBg);
		return audioBg;
	}
}
