package vdrones;

import java.io.IOException;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.function.Function;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import rx.Observable;
import rx.Observer;
import rx.Subscriber;
import rx.functions.Action1;
import rx.subjects.BehaviorSubject;
import rx.subjects.PublishSubject;
import rx_ext.SubscriptionsMap;

import com.google.inject.Inject;
import com.jme3.animation.AnimChannel;
import com.jme3.animation.AnimControl;
import com.jme3.animation.AnimEventListener;
import com.jme3.app.SimpleApplication;
import com.jme3.export.JmeExporter;
import com.jme3.export.JmeImporter;
import com.jme3.math.Rectangle;
import com.jme3.math.Vector3f;
import com.jme3.scene.Node;
import com.jme3.scene.Spatial;

class InfoCube implements com.jme3.export.Savable { //HACK FQN of Savable to avoid a compilation error via gradle
	//- CLASS -----------------------------------------------------------------------------
	public static enum State {
		hidden
		, generating
		, waiting
		, exiting
		, grabbed
	}

	public static final String UD = "CubeInfoUserData";
	public static InfoCube from(Spatial s) {
		return (InfoCube) s.getUserData(UD);
	}

	static Node makeNode(InfoCube v) {
		Node n = new Node("drone");
		n.setUserData(UD, v);
		return n;
	}

	//- INSTANCE --------------------------------------------------------------------------
	final Node node;
	final int zone;
	final Function<InfoCube, InfoCube> translateNext;
	int subzone = -1;
	final BehaviorSubject<Float> dt = BehaviorSubject.create(0f);
	final BehaviorSubject<State> stateReq = BehaviorSubject.create(State.hidden);
	final Observable<State> state = stateReq.distinctUntilChanged().delay(1,TimeUnit.MILLISECONDS);

	InfoCube(int zone, Function<InfoCube, InfoCube> translateNext){
		this.zone = zone;
		this.translateNext = translateNext;
		this.node = makeNode(this);
	}

	@Override
	public void write(JmeExporter ex) throws IOException {
	}
	@Override
	public void read(JmeImporter im) throws IOException {
	}
}

class GenCube extends Subscriber<List<List<Rectangle>>> {
	private final PublishSubject<InfoCube> cubes0 = PublishSubject.create();
	Observable<InfoCube> cubes = cubes0;

	private List<List<Rectangle>> cubeZones;

	InfoCube translateNext(InfoCube c) {
		List<Rectangle> zones = cubeZones.get(c.zone);
		c.subzone = (c.subzone + 1) % zones.size();
		Rectangle r = zones.get(c.subzone);
		Vector3f pos = zones.get(c.subzone).random();
		System.out.println("pos r:" + pos + " .. " + c.subzone + " / " + zones.size() + " .. " + r.getA() + r.getB() + r.getC());
		c.node.setLocalTranslation(pos);
		return c;
	}

	@Override
	public void onCompleted() {
		cubes0.onCompleted();
	}

	@Override
	public void onError(Throwable e) {
		cubes0.onError(e);
	}

	@Override
	public void onNext(List<List<Rectangle>> t) {
		cubeZones = t;
		if (cubeZones.size() > 0) {
			for(int i = cubeZones.size() - 1; i > -1; i--) {
				cubes0.onNext(new InfoCube(i, this::translateNext));
			}
		}
	}
}

@RequiredArgsConstructor(onConstructor=@__(@Inject))
@Slf4j
class ObserverCubeState implements Observer<InfoCube.State> {
	private Action1<InfoCube.State> onExit;
	private InfoCube target;
	private SubscriptionsMap subs = new SubscriptionsMap();
	private AnimEventListener animListener;
	final EntityFactory efactory;
	final SimpleApplication jme;
	final GeometryAndPhysic gp;
	final Animator animator;

	public void bind(InfoCube v) {
		if (target != null && target != v) {
			throw new IllegalStateException("already binded");
		}
		target = v;
		subs.add("0", target.state.subscribe(this));
		animListener = new AnimEventListener(){
			@Override
			public void onAnimCycleDone(AnimControl control, AnimChannel channel, String animName) {
				//log.info("onAnimCycleDone : {} {}", animName, channel.getTime());
				assert(channel.getTime() >= control.getAnimationLength(animName));
				switch(animName) {
				case "generating":
					target.stateReq.onNext(InfoCube.State.waiting);
					break;
				case "exiting":
					target.stateReq.onNext(InfoCube.State.hidden);
					break;
				case "grabbed":
					target.stateReq.onNext(InfoCube.State.hidden);
					break;
				}
			}

			@Override
			public void onAnimChange(AnimControl control, AnimChannel channel, String animName) {
			}
		};
	}

	private void dispose() {
		log.debug("dispose {}", target);
		target = null;
		subs.unsubscribeAll();
	}

	@Override
	public void onCompleted() {
		log.debug("onCompleted {}", target);
		dispose();
	}

	@Override
	public void onError(Throwable e) {
		log.warn("onError", e);
		dispose();
	}

	@Override
	public void onNext(InfoCube.State v) {
		if (onExit != null) {
			try {
				onExit.call(v);
			} catch (Exception e) {
				log.warn("onExit", e);
			}
			onExit = null;
		}
		log.info("Enter in {}", v);
		switch(v) {
		case hidden :
			jme.enqueue(() -> {
				gp.remove(target.node);
				efactory.unas(target.node);
				return true;
			});
			target.stateReq.onNext(InfoCube.State.generating);
			break;
		case generating : {
			jme.enqueue(() -> {
				target.translateNext.apply(target);
				efactory.asCube(target.node);
				gp.add(target.node);
				AnimControl ac = Spatials.findAnimControl(target.node);
				ac.addListener(animListener);
				animator.play(target.node, "generating");
				return true;
			});
			break;
		}
		case waiting :
			jme.enqueue(() -> {
				animator.playLoop(target.node, "waiting");
				return true;
			});
			break;
		case grabbed :
			jme.enqueue(() -> {
				animator.play(target.node, "grabbed");
				return true;
			});
			break;
		case exiting :
			jme.enqueue(() -> {
				animator.play(target.node, "exiting");
				return true;
			});
			break;
		}
	}

}
