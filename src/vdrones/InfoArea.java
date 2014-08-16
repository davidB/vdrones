package vdrones;

import java.util.ArrayList;
import java.util.List;

import rx.Observable;

import com.google.inject.Singleton;
import com.jme3.light.Light;
import com.jme3.math.Rectangle;
import com.jme3.scene.Spatial;

@Singleton
class InfoArea {
	CfgArea cfg;
	Observable<Float> clock;
}

class CfgArea {
	String name;
	float timeout;

	final List<Light> lights = new ArrayList<>();
	final List<Spatial> bg = new ArrayList<>();
	final List<List<Rectangle>> cubeZones = new ArrayList<>();
	final List<Location> spawnPoints = new ArrayList<>();
}