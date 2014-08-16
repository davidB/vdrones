import org.junit.Test;
import rx.Observable;
import rx.subjects.BehaviorSubject;
import rx_ext.ObserverPrint;

public class RxTest {

	@Test
	public void t1() {
		float energyRegenSpeed = 2;
		float energyForwardSpeed = 4;
		float energyShieldSpeed = 2;
		float energyStoreMax = 100f;
		
		//BehaviorSubject<Integer> energyStore = BehaviorSubject.create(0);
		BehaviorSubject<Float> forwardReq = BehaviorSubject.create(1f);
		BehaviorSubject<Float> shieldReq = BehaviorSubject.create(0f);
		//Observable<Float> dt = PublishSubject.create();
		BehaviorSubject<Float> dt = BehaviorSubject.create(0f);
		BehaviorSubject<Float> energyVelocity = BehaviorSubject.create(0f); 
		Observable<Float> energydt = dt.flatMap((dt0) -> energyVelocity.firstOrDefault(0f).map((v) -> dt0 * v));
		Observable<Float> energy = energydt.scan(0f, (acc, d) -> Math.max(0, Math.min(energyStoreMax, acc + d)));
		Observable<Float> forward = Observable.combineLatest(energy, forwardReq, (o1, o2) -> (o1 > energyForwardSpeed) ? o2 : 0f);//.distinctUntilChanged();
		Observable<Float> shield = Observable.combineLatest(energy, shieldReq, (o1, o2) -> (o1 > energyShieldSpeed) ? o2 : 0f).distinctUntilChanged();
		Observable.combineLatest(forward, shield, (o1, o2) -> (energyRegenSpeed - Math.abs(o1 * energyForwardSpeed) /*- Math.abs(o2 * energyShieldSpeed)*/)).subscribe(energyVelocity);
		//energyVelocity.onNext(energyRegenSpeed);
		forward.subscribe(new ObserverPrint<>("forward"));
		shield.subscribe(new ObserverPrint<>("shield"));
		energy.subscribe(new ObserverPrint<>("energy"));
		energyVelocity.subscribe(new ObserverPrint<>("energyV"));
		dt.onNext(0.5f);
		//energyVelocity.onNext(1.0f);
		dt.onNext(0.5f);
		dt.onNext(0.5f);
		dt.onNext(0.5f);
		dt.onNext(0.5f);
		dt.onNext(0.5f);
		dt.onNext(0.5f);
		dt.onNext(0.5f);
		dt.onNext(0.5f);
		dt.onNext(0.5f);
		//energy.subscribe( (v) -> energy.onNext(v + 2)); infinite loop
		//energy.map(v -> )
		//energy.onNext(44);
	}
}
