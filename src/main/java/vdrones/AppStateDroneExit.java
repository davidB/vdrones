package vdrones;

import java.util.LinkedList;
import java.util.List;

import javax.inject.Inject;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import rx.Subscription;
import rx.subscriptions.Subscriptions;

import com.jme3.math.Vector3f;

@Slf4j
@RequiredArgsConstructor(onConstructor=@__(@Inject))
public class AppStateDroneExit extends AppState0 {
	private final List<InfoDrone> drones = new LinkedList<>();
	private final List<Location> exits = new LinkedList<>();
	private Subscription subs;
	final Channels channels;
	// tmp
	private Vector3f segment = new Vector3f();

	@Override
	protected void doEnable(){
		subs = Subscriptions.from(
			channels.drones.flatMap(v -> v.state.map(s -> new T2<InfoDrone, Boolean>(v, s == InfoDrone.State.driving)).distinctUntilChanged()).subscribe(v -> {
				if (v._2) {
					drones.add(v._1);
				} else {
					drones.remove(v._1);
				}
			})
			, channels.areaCfgs.subscribe(v -> {
				exits.clear();
				exits.addAll(v.exitPoints);
				log.info("exitPoints : {}", exits.size());
			})
		);
	};

	@Override
	protected void doDisable(){
		if (subs != null) {
			subs.unsubscribe();
			subs = null;
		}
	};

	@Override
	protected void doUpdate(float tpf) {
		// quicker than using spatial partition or physics collision (via ghosts)
		for(Location loc : exits){
			for(InfoDrone drone : drones){
				drone.node.getWorldTranslation().subtract(loc.position, segment);
				segment.y = 0; // flat into plan XZ
				//log.info("dist {}", segment.length());
				if (segment.length() <= drone.cfg.exitRadius) {
					drones.remove(drone);
					drone.stateReq.onNext(InfoDrone.State.exiting);
				}
			}
		}
	}
}
