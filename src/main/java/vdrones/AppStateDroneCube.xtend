package vdrones

import java.util.LinkedList
import java.util.List
import javax.inject.Inject
import jme3_ext.AppState0
import rx.Subscription
import rx.subscriptions.Subscriptions
import com.jme3.bullet.control.RigidBodyControl
import com.jme3.math.Vector3f
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

class AppStateDroneCube extends AppState0 {
    final List<InfoDrone> drones = new LinkedList()
    final List<InfoCube> cubes = new LinkedList()
    Subscription subs
    final package Channels channels
    // tmp
    Vector3f segment = new Vector3f()
    boolean forceApply = false
    Vector3f force = new Vector3f()

    override protected void doEnable() {
        subs = Subscriptions.from(
            channels.drones.flatMap[v|
                v.state.map[s| new T2<InfoDrone, Boolean>(v, s == InfoDrone.State.driving)].distinctUntilChanged()
            ].subscribe[v|
                if (v._2) {
                    drones.add(v._1);
                } else {
                    drones.remove(v._1);
                }
            ],
            channels.cubes.flatMap[v|
                v.state.map[s| new T2<InfoCube, Boolean>(v, s == InfoCube.State.waiting)].distinctUntilChanged()
            ].subscribe[v|
                if (v._2) {
                    cubes.add(v._1);
                } else {
                    cubes.remove(v._1);
                }
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
        forceApply = false
        force.set(0, 0, 0)
        for (InfoCube cube : cubes) {
            var boolean grabbed = false
            var RigidBodyControl body = cube.node.getControl(RigidBodyControl)
            body.clearForces()
            for (InfoDrone drone : drones) {
                drone.node.getWorldTranslation().subtract(cube.node.getWorldTranslation(), segment)
                var float segmentLg = segment.length()
                if (segmentLg <= drone.cfg.grabRadius) {
                    drone.scoreReq.onNext(1)
                    grabbed = true /* FIXME Unsupported BreakStatement: */
                } else if (segmentLg <= drone.cfg.attractorRadius) {
                    force.addLocal(segment.multLocal(drone.cfg.attractorRadius / segmentLg))
                    forceApply = true
                }

            }
            if (grabbed) {
                // remove from the active list to avoid redo test until state change is propagated
                cubes.remove(cube)
                cube.stateReq.onNext(InfoCube.State.grabbed)
            }
            if (forceApply) {
                force.y = 0
                body.applyForce(force, Vector3f.ZERO)
            }

        }

    }

    @Inject
    @FinalFieldsConstructor
    new(){}

}