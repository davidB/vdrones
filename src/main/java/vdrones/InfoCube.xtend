package vdrones

import com.jme3.animation.AnimChannel
import com.jme3.animation.AnimControl
import com.jme3.animation.AnimEventListener
import com.jme3.app.SimpleApplication
import com.jme3.export.JmeExporter
import com.jme3.export.JmeImporter
import com.jme3.export.Savable
import com.jme3.math.FastMath
import com.jme3.math.Transform
import com.jme3.math.Vector3f
import com.jme3.scene.Node
import com.jme3.scene.Spatial
import java.io.IOException
import java.util.List
import java.util.concurrent.TimeUnit
import java.util.function.Function
import javax.inject.Inject
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.slf4j.LoggerFactory
import rx.Observable
import rx.Observer
import rx.Subscriber
import rx.functions.Action1
import rx.subjects.BehaviorSubject
import rx.subjects.PublishSubject
import rx_ext.SubscriptionsMap

class InfoCube implements Savable {
    // HACK FQN of Savable to avoid a compilation error via gradle
    // - CLASS -----------------------------------------------------------------------------
    public static enum State {
        hidden,
        generating,
        waiting,
        exiting,
        grabbed
    }

    public static final String UD = "CubeInfoUserData"

    def static InfoCube from(Spatial s) {
        return s.getUserData(UD) as InfoCube
    }

    def static package Node makeNode(InfoCube v) {
        var Node n = new Node("cubez." + v.zone)
        n.setUserData(UD, v)
        return n
    }

    // - INSTANCE --------------------------------------------------------------------------
    final package Node node
    final package int zone
    final package Function<InfoCube, InfoCube> translateNext
    package int subzone = -1
    final package BehaviorSubject<Float> dt = BehaviorSubject.create(0f)
    final package BehaviorSubject<State> stateReq = BehaviorSubject.create(State.hidden)
    final package Observable<State> state = stateReq.distinctUntilChanged().delay(1, TimeUnit.MILLISECONDS)

    package new(int zone, Function<InfoCube, InfoCube> translateNext) {
        this.zone = zone
        this.translateNext = translateNext
        this.node = makeNode(this)
    }

    override void write(JmeExporter ex) throws IOException {
    }

    override void read(JmeImporter im) throws IOException {
    }

}

class GenCube extends Subscriber<List<List<Transform>>> {
    final PublishSubject<InfoCube> cubes0 = PublishSubject.create()
    package Observable<InfoCube> cubes = cubes0
    var List<List<Transform>> cubeZones

    val translateNext = [InfoCube c|
        val zones = cubeZones.get(c.zone)
        c.subzone = (c.subzone + 1) % zones.size()
        val r = zones.get(c.subzone)
        val pos = r.transformVector(new Vector3f(FastMath.nextRandomFloat(), 1.0f, FastMath.nextRandomFloat()), new Vector3f());  
        System.out.println('''pos r:«pos» .. «c.subzone» / «zones.size()» .. «pos»''')
        c.node.setLocalTranslation(pos)
        return c
    ]

    override void onCompleted() {
        cubes0.onCompleted()
    }

    override void onError(Throwable e) {
        cubes0.onError(e)
    }

    override void onNext(List<List<Transform>> t) {
        cubeZones = t
        if (cubeZones.size() > 0) {
            for (var int i = cubeZones.size() - 1; i > -1; i--) {
                cubes0.onNext(new InfoCube(i, translateNext))
            }
        }
    }

    @Inject
    new() {}
}

class ObserverCubeState implements Observer<InfoCube.State> {
    val log = LoggerFactory.getLogger(ObserverCubeState)
    Action1<InfoCube.State> onExit
    InfoCube target
    SubscriptionsMap subs = new SubscriptionsMap()
    AnimEventListener animListener
    final package EntityFactory efactory
    final package SimpleApplication jme
    final package GeometryAndPhysic gp
    final package Animator animator

    def void bind(InfoCube v) {
        if (target !== null && target !== v) {
            throw new IllegalStateException("already binded")
        }
        target = v
        subs.add("0", target.state.subscribe(this))
        animListener = new AnimEventListener() {
            override void onAnimCycleDone(AnimControl control, AnimChannel channel, String animName) {
                // log.info("onAnimCycleDone : {} {}", animName, channel.getTime());
                if (!((channel.getTime() >= control.getAnimationLength(animName)))) {
                    throw new AssertionError()
                }
                switch (animName) {
                    case "generating": {
                        target.stateReq.onNext(InfoCube.State.waiting) /* FIXME Unsupported BreakStatement: */
                    }
                    case "exiting": {
                        target.stateReq.onNext(InfoCube.State.hidden) /* FIXME Unsupported BreakStatement: */
                    }
                    case "grabbed": {
                        target.stateReq.onNext(InfoCube.State.hidden) /* FIXME Unsupported BreakStatement: */
                    }
                }
            }

            override void onAnimChange(AnimControl control, AnimChannel channel, String animName) {
            }
        }
    }

    def private void dispose() {
        log.debug("dispose {}", target)
        target = null
        subs.unsubscribeAll()
    }

    override void onCompleted() {
        log.debug("onCompleted {}", target)
        dispose()
    }

    override void onError(Throwable e) {
        log.warn("onError", e)
        dispose()
    }

    override void onNext(InfoCube.State v) {
        if (onExit !== null) {
            try {
                onExit.call(v)
            } catch (Exception e) {
                log.warn("onExit", e)
            }
            onExit = null
        }
        log.info("Enter in {}", v)
        switch (v) {
            case hidden: {
                jme.enqueue[
                    gp.remove(target.node)
                    efactory.unas(target.node)
                    true
                ]
                target.stateReq.onNext(InfoCube.State.generating)
            }
            case generating: {
                jme.enqueue[
                    target.translateNext.apply(target)
                    efactory.asCube(target.node)
                    gp.add(target.node)
                    val ac = Spatials.findAnimControl(target.node)
                    ac.addListener(animListener)
                    animator.play(target.node, "generating")
                    true
                ]
            }
            case waiting: {
                jme.enqueue[
                    animator.playLoop(target.node, "waiting")
                    true
                ]
            }
            case grabbed: {
                jme.enqueue[
                    animator.play(target.node, "grabbed")
                    true
                ]
            }
            case exiting: {
                jme.enqueue[
                    animator.play(target.node, "exiting")
                    true
                ]
            }
        }
    }

    @Inject
    @FinalFieldsConstructor
    new(){}
}