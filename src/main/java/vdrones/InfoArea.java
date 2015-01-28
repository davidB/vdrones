package vdrones;

import java.util.ArrayList;
import java.util.List;

import javax.inject.Singleton;

import lombok.RequiredArgsConstructor;
import rx.Observable;

import com.jme3.math.Rectangle;
import com.jme3.scene.Spatial;

@Singleton
class InfoArea {
	CfgArea cfg;
	Observable<Float> clock;
}

class CfgArea {
	Area area;

	final List<Spatial> bg = new ArrayList<>();
	final List<List<Rectangle>> cubeZones = new ArrayList<>();
	final List<Location> spawnPoints = new ArrayList<>();
	final List<Location> exitPoints = new ArrayList<>();
}

@RequiredArgsConstructor
enum Area {
	A00(true, null, 360),
	B00(true, null, 45),
	B01(true, null, 90),
	B02(false, null, 120),
	B04(false, null, 120),
	T01(false, null, 90)
	;
	final boolean enable;
	final String music;
	final float time;
//	Area(String music, float time) {
//		this.music = music;
//		this.time = time;
//	}
}