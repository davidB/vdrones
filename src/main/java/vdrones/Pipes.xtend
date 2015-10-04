package vdrones

import com.jme3.input.InputManager
import com.jme3.input.KeyInput
import com.jme3.input.controls.KeyTrigger
import com.jme3.scene.Spatial
import org.eclipse.xtend.lib.annotations.Data
import rx.Observable
import rx.Subscription
import rx.subscriptions.Subscriptions

class Pipes {
    def static Subscription pipeA(Observable<CfgArea> l, GeometryAndPhysic gp, EntityFactory efactory) {
        var Observable<Spatial> bg = l.flatMap[v| Observable.from(v.bg)]
        var Observable<Spatial> spawns = l.flatMap[v| Observable.from(v.spawnPoints)].map[v| efactory.newSpawnPoint(v)]
        var Observable<Spatial> exits = l.flatMap[v| Observable.from(v.exitPoints)].map[v| efactory.newExitPoint(v)]
        // TODO manage remove of spatial
        return Subscriptions::from(
            bg.subscribe[v| gp.add(v)],
            spawns.subscribe[v| gp.add(v)],
            exits.subscribe[v| gp.add(v)]
        )
    }

    def static package Subscription pipe(Observable<InfoDrone> drone, InputManager inputManager) {
        inputManager.addMapping(DroneInput::LEFT, new KeyTrigger(KeyInput::KEY_LEFT), new KeyTrigger(KeyInput::KEY_A),
            new KeyTrigger(KeyInput::KEY_Q))
        inputManager.addMapping(DroneInput::RIGHT, new KeyTrigger(KeyInput::KEY_RIGHT), new KeyTrigger(KeyInput::KEY_D))
        inputManager.addMapping(DroneInput::FORWARD, new KeyTrigger(KeyInput::KEY_UP), new KeyTrigger(KeyInput::KEY_W),
            new KeyTrigger(KeyInput::KEY_Z))
        inputManager.addMapping(DroneInput::BACKWARD, new KeyTrigger(KeyInput::KEY_DOWN),
            new KeyTrigger(KeyInput::KEY_S)) // inputManager.addMapping(DroneInput.TOGGLE_CAMERA, new KeyTrigger(KeyInput.KEY_M));
        // inputManager.addMapping(RESET, new KeyTrigger(KeyInput.KEY_RETURN));
        //FIXME use a temporary variable m to avoid type inference issue.
        val Observable<T2<DroneInput, InfoDrone.State>> m = drone.flatMap[v|
            val ctrl = new DroneInput(v)
            v.state.map[v0| new T2<DroneInput, InfoDrone.State>(ctrl, v0)] //as Observable<T2<DroneInput, InfoDrone.State>> 
        ]
        m.subscribe[v|
            if (v._2 == InfoDrone.State.driving) {
                inputManager.addListener(v._1, DroneInput.LEFT, DroneInput.RIGHT, DroneInput.FORWARD, DroneInput.BACKWARD)
            } else {
                inputManager.removeListener(v._1)
            }
        ]
    }

}

@Data
class T2<A1, A2> {
    public val A1 _1
    public val A2 _2
}
