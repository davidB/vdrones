package vdrones;

import java.util.ArrayList;
import java.util.List;

import lombok.RequiredArgsConstructor;
import lombok.val;
import rx.Observable;
import rx.Subscriber;
import rx.Subscription;
import rx.subjects.BehaviorSubject;
import rx.subjects.PublishSubject;
import rx.subscriptions.Subscriptions;

import com.google.inject.Singleton;
import com.jme3.light.Light;
import com.jme3.math.Quaternion;
import com.jme3.math.Rectangle;
import com.jme3.math.Vector3f;
import com.jme3.scene.Spatial;

@Singleton
class Channels{
	final BehaviorSubject<DroneInfo2> droneInfo2s = BehaviorSubject.create();
	final BehaviorSubject<AreaInfo2> areaInfo2s = BehaviorSubject.create();
	final BehaviorSubject<AreaCfg> areaCfgs = BehaviorSubject.create();
}

class DroneCfg {
    public float turn = 2.0f;
    public float forward = 150f;
    public float linearDamping = 0.5f;
	public float energyRegenSpeed = 2;
	public float energyForwardSpeed = 4;
	public float energyShieldSpeed = 2;
	public float energyStoreMax = 100f;
}

class DroneGen {
	enum Kind {
		first,
		restore,
	}
	Location loc;
	Kind kind;
}

class DroneInfo2 {
	DroneCfg cfg;

	final BehaviorSubject<Boolean> drivable = BehaviorSubject.create(false);
	final BehaviorSubject<Float> forwardReq = BehaviorSubject.create(0f);
	final BehaviorSubject<Float> turnReq = BehaviorSubject.create(0f);
	final BehaviorSubject<Float> shieldReq = BehaviorSubject.create(0f);
	//BehaviorSubject<Vector3f> position = BehaviorSubject.create(new Vector3f());
	Observable<Float> energy;
	Observable<Float> forward;
	Observable<Float> turn;
	Observable<Float> shield;

}

@RequiredArgsConstructor
class Cube {
	final Vector3f position;
	final int zone;
	final int subzone;
}

@Singleton
class AreaInfo2 {
	AreaCfg cfg;
	Observable<Float> clock;
}


class AreaCfg {
	String name;
	float timeout;

	final List<Light> lights = new ArrayList<>();
	final List<Spatial> bg = new ArrayList<>();
	final List<List<Rectangle>> cubeZones = new ArrayList<>();
	final Location spawnPoint = new Location();
}

class Location {
	final Vector3f position = new Vector3f();
	final Quaternion orientation = new Quaternion(Quaternion.IDENTITY);
}

class CubeGenerator extends Subscriber<List<List<Rectangle>>> {
	private final PublishSubject<Observable<Cube>> cubes0 = PublishSubject.create();
	Observable<Observable<Cube>> cubes = cubes0;
	private Subscription subscription;

	private List<List<Rectangle>> cubeZones;

	void generateNext(Cube c) {
		generateIn(c.zone, c.subzone + 1 % cubeZones.get(c.zone).size());
	}

	void generateIn(int zone, int subzone) {
		Rectangle zoneR = cubeZones.get(zone).get(subzone);
		//nextZone = (nextZone + 1) % cubeZones.get(zone).size();
		Cube c = new Cube(zoneR.random(), zone, subzone);
		cubes0.onNext(BehaviorSubject.create(c));
	}

	void stop() {
		if (subscription != null && !subscription.isUnsubscribed()) {
			subscription.unsubscribe();
		}
		subscription = null;
	}

	@Override
	public void onCompleted() {
		cubes0.onCompleted();
		stop();
	}

	@Override
	public void onError(Throwable e) {
		cubes0.onError(e);
		stop();
	}

	@Override
	public void onNext(List<List<Rectangle>> t) {
		stop();
		cubeZones = t;
		if (cubeZones.size() > 0) {
			subscription = cubes.flatMap(v -> v).last().subscribe(this::generateNext);
			for(int i = cubeZones.size() - 1; i > -1; i--) {
				generateIn(i, 0);
			}
		}
	}
}

class DroneGenerator extends Subscriber<Location> {
	private final PublishSubject<Observable<DroneGen>> drones0 = PublishSubject.create();
	Observable<Observable<DroneGen>> drones = drones0;

	private Subscription subscription;
	private Location spawnLoc;

	void generate(boolean first) {
		DroneGen v = new DroneGen();
		v.loc = spawnLoc;
		v.kind = first ? DroneGen.Kind.first : DroneGen.Kind.restore;
		drones0.onNext(BehaviorSubject.create(v));
	}

	void stop() {
		if (subscription != null && !subscription.isUnsubscribed()) {
			subscription.unsubscribe();
		}
		subscription = null;
	}

	@Override
	public void onCompleted() {
		drones0.onCompleted();
		stop();
	}

	@Override
	public void onError(Throwable e) {
		drones0.onError(e);
		stop();
	}

	@Override
	public void onNext(Location t) {
		stop();
		spawnLoc = t;
		if (spawnLoc != null) {
			subscription = drones.flatMap(v -> v).last().subscribe(v -> generate(false));
			generate(true);
		}
	}
}


//see https://github.com/Netflix/RxJava/issues/798
//class ObservableList<T> {
//
//	final Observable<T> onAdd;
//	final Observable<T> onRemove;
//	public void add(T v) {
//
//	}
//
//	public void remove(T v) {
//
//	}
//
//	public void removeAll() {
//
//	}
//}
public class AppStateGameLogic extends AppState0 {
	BehaviorSubject<Float> dt = BehaviorSubject.create(0f);
	Subscription subscription;

	DroneInfo2 newDroneInfo(DroneCfg cfg, Observable<Float> dt) {
		val drone = new DroneInfo2();
		drone.cfg = cfg;
		BehaviorSubject<Float> energyVelocity = BehaviorSubject.create(0f);
		Observable<Float> energydt = dt.flatMap((dt0) -> energyVelocity.firstOrDefault(0f).map((v) -> dt0 * v));
		drone.energy = energydt.scan(0f, (acc, d) -> Math.max(0, Math.min(cfg.energyStoreMax, acc + d)));
		drone.forward = Observable.combineLatest(drone.energy, drone.forwardReq, (o1, o2) -> (o1 > cfg.energyForwardSpeed) ? o2 : 0f).distinctUntilChanged();
		drone.turn = drone.turnReq.distinctUntilChanged();
		drone.shield = Observable.combineLatest(drone.energy, drone.shieldReq, (o1, o2) -> (o1 > cfg.energyShieldSpeed) ? o2 : 0f).distinctUntilChanged();
		Observable.combineLatest(drone.forward, drone.shield, (o1, o2) -> (cfg.energyRegenSpeed - Math.abs(o1 * cfg.energyForwardSpeed) /*- Math.abs(o2 * energyShieldSpeed)*/)).subscribe(energyVelocity);
		return drone;
	}

	AreaInfo2 newAreaInfo(AreaCfg cfg, Observable<Float> dt) {
		val area = new AreaInfo2();
		area.cfg = cfg;
		area.clock = dt.scan(0f, (acc, dt0) -> acc + dt0);
		return area;
	}


	@Override
	protected void doInitialize() {
		Channels channels = injector.getInstance(Channels.class);
		DroneGenerator droneGenerator = injector.getInstance(DroneGenerator.class);

		subscription =  Subscriptions.from(
			channels.areaCfgs.map(v -> newAreaInfo(v, dt)).subscribe(channels.areaInfo2s)
			, Pipes.pipe(channels.areaCfgs, droneGenerator)
			, droneGenerator.drones.flatMap(v -> v).map(v -> newDroneInfo(new DroneCfg(), dt)).subscribe(channels.droneInfo2s)
			, channels.droneInfo2s.subscribe(v -> v.drivable.onNext(true))
		);
	}

	@Override
	protected void doUpdate(float tpf) {
		dt.onNext(tpf);
	}

	protected void doDispose() {
		subscription.unsubscribe();
	}
}
