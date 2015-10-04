package vdrones

import com.jme3.math.Vector3f
import java.util.LinkedList
import javax.inject.Inject
import jme3_ext.AppState0
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.slf4j.LoggerFactory
import rx.Subscription
import rx.subscriptions.Subscriptions

class AppStateDroneExit extends AppState0 {
    val log = LoggerFactory::getLogger(typeof(AppStateDroneExit))
    val drones = new LinkedList<InfoDrone>()
    val exits = new LinkedList<Location>()
    Subscription subs
    val Channels channels
    // tmp
    val segment = new Vector3f()

    override protected void doEnable() {
        subs = Subscriptions::from(
            channels.drones.flatMap[v|
                v.state.map[s| new T2<InfoDrone, Boolean>(v, s == InfoDrone.State.driving)].distinctUntilChanged()
            ].subscribe[v|
                if (v._2) {
                    drones.add(v._1)
                } else {
                    drones.remove(v._1)
                }
            ],
            channels.areaCfgs.subscribe[v|
                exits.clear()
                exits.addAll(v.exitPoints)
                log.info("exitPoints : {}", exits.size())
            ]
        )
    }

    override protected void doDisable() {
        if (subs !== null) {
            subs.unsubscribe()
            subs = null
        }
    }

    override protected void doUpdate(float tpf) {
        // quicker than using spatial partition or physics collision (via ghosts)
        for (Location loc : exits) {
            for (InfoDrone drone : drones) {
                drone.node.getWorldTranslation().subtract(loc.position, segment)
                segment.y = 0 // flat into plan XZ
                // log.info("dist {}", segment.length());
                if (segment.length() <= drone.cfg.exitRadius) {
                    drones.remove(drone)
                    drone.stateReq.onNext(InfoDrone.State::exiting)
                }
            }
        }
    }

    @Inject
    @FinalFieldsConstructor
    new(){}
}
