package vdrones;

import rx.Observable;
import rx.subjects.BehaviorSubject;

import com.google.inject.Singleton;


class DroneCfg {
    public float turn = 2.0f;
    public float forward = 150f;
    public float linearDamping = 0.5f;
	public float energyRegenSpeed = 2;
	public float energyForwardSpeed = 4;
	public float energyShieldSpeed = 2;
	public float energyStoreMax = 100f;
}

@Singleton
class DroneInfo {
	final DroneCfg cfg = new DroneCfg();
	final BehaviorSubject<Float> forwardReq = BehaviorSubject.create(0f);
	final BehaviorSubject<Float> turnReq = BehaviorSubject.create(0f);
	final BehaviorSubject<Float> shieldReq = BehaviorSubject.create(0f);
	//BehaviorSubject<Vector3f> position = BehaviorSubject.create(new Vector3f());
	Observable<Float> energy;
	Observable<Float> forward;
	Observable<Float> turn;
	Observable<Float> shield;
}

@Singleton
class AreaInfo {
	BehaviorSubject<String> name = BehaviorSubject.create("");
	Observable<Float> clock;
}

public class AppStateGameLogic extends AppState0 {
	BehaviorSubject<Float> dt = BehaviorSubject.create(0f);

	@Override
	protected void enable() {
		DroneInfo drone = injector.getInstance(DroneInfo.class);
		DroneCfg cfg = drone.cfg;

		BehaviorSubject<Float> energyVelocity = BehaviorSubject.create(0f);
		Observable<Float> energydt = dt.flatMap((dt0) -> energyVelocity.firstOrDefault(0f).map((v) -> dt0 * v));
		drone.energy = energydt.scan(0f, (acc, d) -> Math.max(0, Math.min(cfg.energyStoreMax, acc + d)));
		drone.forward = Observable.combineLatest(drone.energy, drone.forwardReq, (o1, o2) -> (o1 > cfg.energyForwardSpeed) ? o2 : 0f).distinctUntilChanged();
		drone.turn = drone.turnReq.distinctUntilChanged();
		drone.shield = Observable.combineLatest(drone.energy, drone.shieldReq, (o1, o2) -> (o1 > cfg.energyShieldSpeed) ? o2 : 0f).distinctUntilChanged();
		Observable.combineLatest(drone.forward, drone.shield, (o1, o2) -> (cfg.energyRegenSpeed - Math.abs(o1 * cfg.energyForwardSpeed) /*- Math.abs(o2 * energyShieldSpeed)*/)).subscribe(energyVelocity);
			//energyVelocity.onNext(energyRegenSpeed);
//			forward.subscribe(new ObserverPrint<Float>("forward"));
//			shield.subscribe(new ObserverPrint<Float>("shield"));
//			energy.subscribe(new ObserverPrint<Float>("energy"));
//			energyVelocity.subscribe(new ObserverPrint<Float>("energyV"));
			//energy.subscribe( (v) -> energy.onNext(v + 2)); infinite loop
			//energy.map(v -> )
			//energy.onNext(44);
		AreaInfo area = injector.getInstance(AreaInfo.class);
		area.clock = dt.scan(0f, (acc, dt0) -> acc + dt0);
	}

	@Override
	public void update(float tpf) {
		super.update(tpf);
		if (isEnabled()) {
			dt.onNext(tpf);
		}
	}

	@Override
	protected void disable() {
		// TODO unsubscribe !!
	}
}
