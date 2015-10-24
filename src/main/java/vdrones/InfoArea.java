package vdrones;

import java.util.ArrayList;
import java.util.List;

import javax.inject.Singleton;

import rx.Observable;

import com.jme3.math.Transform;
import com.jme3.scene.Spatial;

@Singleton
class InfoArea {
	CfgArea cfg;
	Observable<Float> clock;
}

class CfgArea {
	Area area;

	//final List<Spatial> bg = new ArrayList<>();
	final List<Spatial> scene = new ArrayList<>();
	final List<List<Transform>> cubeZones = new ArrayList<>();
	final List<Location> spawnPoints = new ArrayList<>();
	final List<Location> exitPoints = new ArrayList<>();
}

