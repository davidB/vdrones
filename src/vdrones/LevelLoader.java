package vdrones;

import java.util.ArrayList;
import java.util.Collection;

import rx.Observable;
import rx.subjects.AsyncSubject;
import rx.subjects.PublishSubject;

import com.jme3.light.Light;
import com.jme3.light.LightList;
import com.jme3.scene.Node;
import com.jme3.scene.Spatial;

//class LevelLoader {
//
//	private final PublishSubject<Spatial> addSpatial0 = PublishSubject.create();
//	public final Observable<Spatial> addSpatial = addSpatial0;
//
//	private final PublishSubject<Spatial> removeSpatial0 = PublishSubject.create();
//	public final Observable<Spatial> removeSpatial = AsyncSubject.create();
//
//	private final PublishSubject<Light> addLight0 = PublishSubject.create();
//	public final Observable<Light> addLight = addLight0;
//
//	private final PublishSubject<Light> removeLight0 = PublishSubject.create();
//	public final Observable<Light> removeLight = removeLight0;
//
//	private Collection<Spatial> spatials = new ArrayList<>();
//	private LightList lights;
//
//	public void loadLevel(Spatial level, boolean updateLights) {
//		unloadLevel();
//
//		lights = level.getLocalLightList().clone();
//		//level.getLocalLightList().clear();
//		for (Light l : lights) {
//			addLight0.onNext(l);
//		}
//		extract(spatials, level, "backgrounds");
//		extract(spatials, level, "spawners");
//		extract(spatials, level, "traps");
//		extract(spatials, level, "exits");
//		for (Spatial s : spatials) {
//			addSpatial0.onNext(s);
//		}
//	}
//
//	private void extract(Collection<Spatial> dest, Spatial src, String groupName) {
//		Node group = (Node) ((Node)src).getChild(groupName);
//		if (group != null) {
//			for(Spatial s : group.getChildren()) {
//				s.setLocalTransform(s.getWorldTransform());
//				s.setUserData("dest", EntityFactory.LevelName);
//				s.setUserData("groupName", groupName);
//				dest.add(s);
//			}
//		} else {
//			System.out.printf("group not found : %s \n", groupName);
//		}
//	}
//
//	public void unloadLevel() {
//		if (spatials != null) {
//			for(Spatial s : spatials) {
//				removeSpatial0.onNext(s);
//			}
//			spatials.clear();
//		}
//
//		if (lights != null) {
//			for (Light l : lights) {
//				removeLight0.onNext(l);
//			}
//			lights = null;
//		}
//	}
//}