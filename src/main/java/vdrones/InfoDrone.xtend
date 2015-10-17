package vdrones

import com.jme3.animation.AnimChannel
import com.jme3.animation.AnimControl
import com.jme3.animation.AnimEventListener
import com.jme3.app.SimpleApplication
import com.jme3.bullet.control.RigidBodyControl
import com.jme3.export.JmeExporter
import com.jme3.export.JmeImporter
import com.jme3.export.Savable
import com.jme3.math.Quaternion
import com.jme3.math.Vector3f
import com.jme3.scene.Node
import com.jme3.scene.Spatial
import java.io.IOException
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.slf4j.LoggerFactory
import rx.Observable
import rx.Observer
import rx.Subscriber
import rx.Subscription
import rx.functions.Action1
import rx.subjects.BehaviorSubject
import rx.subjects.PublishSubject
import rx.subscriptions.Subscriptions
import rx_ext.SubscriptionsMap
import vdrones.InfoDrone.State

package class InfoDrone implements Savable{
	//HACK FQN of Savable to avoid a compilation error via gradle
	//- CLASS -----------------------------------------------------------------------------
	public static enum State {
		hidden, generating, driving, crashing, disconnecting, exiting}public static final String UD="DroneInfoUserData"
	def static InfoDrone from(Spatial s) {
		return s.getUserData(UD) as InfoDrone 
	}
	def static package Node makeNode(InfoDrone v) {
		var Node n=new Node("drone") 
		n.setUserData(UD, v) return n 
	}
	//- INSTANCE --------------------------------------------------------------------------
	final package CfgDrone cfg
	final package Node node=makeNode(this)
	final package BehaviorSubject<Float> dt=BehaviorSubject.create(0f)
	final package BehaviorSubject<State> stateReq=BehaviorSubject.create(State.hidden)
	final package Observable<State> state=stateReq.distinctUntilChanged().delay(1, TimeUnit.MILLISECONDS)
	final package BehaviorSubject<Float> forwardReq=BehaviorSubject.create(0f)
	final package Observable<Float> forward
	final package BehaviorSubject<Float> turnReq=BehaviorSubject.create(0f)
	final package Observable<Float> turn
	final package BehaviorSubject<Float> shieldReq=BehaviorSubject.create(0f)
	final package Observable<Float> shield
	final package BehaviorSubject<Float> healthReq=BehaviorSubject.create(0f)
	final package Observable<Float> health
	final package BehaviorSubject<DroneCollisionEvent> collisions=BehaviorSubject.create()
	final package BehaviorSubject<Float> energyRegen=BehaviorSubject.create(0f)
	final package Observable<Float> energy
	final package BehaviorSubject<Integer> scoreReq=BehaviorSubject.create(0)
	final package Observable<Integer> score
	//BehaviorSubject<Vector3f> position = BehaviorSubject.create(new Vector3f());
	//HACK delay to async state change (eg: post-pone update after all subscriber receive previous value)
	package Location spawnLoc
	
	new(CfgDrone cfg) {
		this.cfg=cfg
		val energyVelocity = BehaviorSubject.create(0f) 
		val energydt = this.dt.flatMap[dt0| energyVelocity.firstOrDefault(0f).map[v| dt0 * v]] 
		this.energy=energydt.scan(cfg.energyStoreInit, [acc, d| Math.max(0, Math.min(cfg.energyStoreMax, acc + d))])
		this.forward=Observable.combineLatest(this.energy, this.forwardReq, [o1, o2| if (o1 > cfg.energyForwardSpeed) o2 else 0f]).distinctUntilChanged()
		this.turn=this.turnReq.distinctUntilChanged()
		this.health=this.healthReq.scan(cfg.healthMax, [acc, d| Math.max(0, Math.min(cfg.healthMax, acc + d))]).distinctUntilChanged()
		this.shield=Observable.combineLatest(this.energy, this.shieldReq, [o1, o2| if (o1 > cfg.energyShieldSpeed) o2 else 0f]).distinctUntilChanged()
		Observable.combineLatest(this.energyRegen, this.forward, this.shield, [o0, o1, o2| o0 - Math.abs(o1 * cfg.energyForwardSpeed)/*- Math.abs(o2 * energyShieldSpeed)*/]).subscribe(energyVelocity)
		//TODO use a throttleFirst based on game time vs real time
		this.health.filter[v| v <= 0].subscribe[v| this.stateReq.onNext(InfoDrone.State.crashing)]
		this.score=this.scoreReq.scan(0, [acc, d| acc + d]) 
	}
	override void write(JmeExporter ex) throws IOException {
		
	}
	override void read(JmeImporter im) throws IOException {
		
	}
	
}

package class CfgDrone {
	public float turn=2.0f
	public float forward=150f
	public float linearDamping=0.5f
	public float energyRegenSpeed=2
	public float energyForwardSpeed=4
	public float energyShieldSpeed=2
	public float energyStoreInit=50f
	public float energyStoreMax=100f
	public float healthMax=100f
	public float wallCollisionHealthSpeed=-100.0f / 5.0f
	//-100 points in 5 seconds,
	public float attractorRadius=3.5f //6.5f
	public float attractorPower=1.0f
	public float grabRadius=3.0f
	public float exitRadius=1.5f
	
}

@Data
class DroneCollisionEvent {
	val Vector3f position
    val float lifetime
	val  Spatial other

	def DroneCollisionEvent lifetime(float v) {
		return new DroneCollisionEvent(position,v,other) 
	}	
}


class Location {
	final package Vector3f position=new Vector3f()
	final package Quaternion orientation=new Quaternion(Quaternion.IDENTITY)
	
}

package class GenDrone extends Subscriber<Location> {
	final PublishSubject<InfoDrone> drones0=PublishSubject.create()
	package Observable<InfoDrone> drones=drones0
	override void onCompleted() {
		drones0.onCompleted() 
	}
	override void onError(Throwable e) {
		drones0.onError(e) 
	}
	override void onNext(Location t) {
		val drone=new InfoDrone(new CfgDrone()) 
		drone.spawnLoc=t
		drones0.onNext(drone) 
	}
	@Inject
    new() {
	}
}


class ObserverDroneState implements Observer<InfoDrone.State>{
	val log = LoggerFactory.getLogger(ObserverDroneState)
	Action1<State> onExit
	InfoDrone drone
	SubscriptionsMap subs=new SubscriptionsMap()
	AnimEventListener animListener
	final package EntityFactory efactory
	final package SimpleApplication jme
	final package GeometryAndPhysic gp
	final package Animator animator
	def void bind(InfoDrone v) {
		if (drone !== null && drone !== v) {
			throw new IllegalStateException("already binded")
		}
		drone=v subs.add("0", drone.state.subscribe(this)) animListener=new AnimEventListener(){
			override void onAnimCycleDone(AnimControl control, AnimChannel channel, String animName) {
				//log.info("onAnimCycleDone : {} {}", animName, channel.getTime());
				if(!((channel.getTime() >= control.getAnimationLength(animName)))) {throw new AssertionError()}
				switch (animName) {
					case "generating":{
						drone.stateReq.onNext(InfoDrone.State.driving) /* FIXME Unsupported BreakStatement: */
					}
					case "crashing":{
						drone.stateReq.onNext(InfoDrone.State.hidden) /* FIXME Unsupported BreakStatement: */
					}
					case "exiting":{
						drone.stateReq.onNext(InfoDrone.State.disconnecting) /* FIXME Unsupported BreakStatement: */
					}
				}
			}
			override void onAnimChange(AnimControl control, AnimChannel channel, String animName) {
				
			}
			} 
	}
	def private void dispose() {
		log.debug("dispose {}", drone)
		drone=null
		subs.unsubscribeAll() 
	}
	override void onCompleted() {
		log.debug("onCompleted {}", drone) dispose() 
	}
	override void onError(Throwable e) {
		log.warn("onError", e) dispose() 
	}
	override void onNext(State v) {
		if (onExit !== null) {
			try {
				onExit.call(v) 
			} catch (Exception e) {
				log.warn("onExit", e) 
			}
			onExit=null 
		}
		log.info("Enter in {}", v) 
		switch (v) {
			case hidden:{
				jme.enqueue[
                    gp.remove(drone.node)
                    efactory.unas(drone.node)
                    true
                ]
				drone.stateReq.onNext(InfoDrone.State.generating)
			}
			case generating:{
				drone.energyRegen.onNext(drone.cfg.energyStoreMax) /*energyRegenSpeed * 4*/
				drone.healthReq.onNext(drone.cfg.healthMax)
				jme.enqueue[
				    drone.node.setLocalRotation(drone.spawnLoc.orientation)
                    drone.node.setLocalTranslation(drone.spawnLoc.position)
                    efactory.asDrone(drone.node)
                    drone.node.addControl(new ControlDronePhy())
                    subs.add("ControlDronePhy", pipe(drone, drone.node.getControl(ControlDronePhy)))
                    gp.add(drone.node)
                    jme.getStateManager().getState(AppStateCamera).setCameraFollower(new CameraFollower(CameraFollower.Mode.TPS, drone.node))
                    //TODO start animation
                    val ac = Spatials.findAnimControl(drone.node)
                    ac.addListener(animListener)
                    animator.play(drone.node, "generating")
                    true
				] 
				//TODO start animation
				onExit= [n|
                    log.info("Exit from {} to {}", v, n)
                    drone.energyRegen.onNext(drone.cfg.energyRegenSpeed)
                ]
				//TODO switch on end of animation
				//Schedulers.computation().createWorker().schedule((() ->drone.go(DroneInfo2.State.driving)), 1, TimeUnit.SECONDS);
			}
			
			case driving:{
				subs.add("collisions.walls", drone.collisions
				    .filter[v0| CollisionGroups.test(v0.other, CollisionGroups.WALL)]
				    .throttleFirst(250, TimeUnit.MILLISECONDS)
				    .subscribe[v2| drone.healthReq.onNext(drone.cfg.wallCollisionHealthSpeed * 0.25f)]
				) //			subs.add("collisions.cubes", drone.collisions
				//				.filter(v0 -> CollisionGroups.test(v0.other, CollisionGroups.CUBE))
				//				.throttleFirst(250, java.util.concurrent.TimeUnit.MILLISECONDS)
				//				.subscribe(v2 ->{
				//					System.out.println("inc scoree.... RUN");
				//					drone.scoreReq.onNext(1);
				//					InfoCube cube = InfoCube.from(v2.other);
				//					cube.stateReq.onNext(InfoCube.State.grabbed);
				//				})
				//			);
				onExit=[n|
                    log.info("Exit from {} to {}", v, n);
                    drone.energyRegen.onNext(0f);
                    drone.forwardReq.onNext(0f);
                    drone.turnReq.onNext(0f);
                    subs.unsubscribe("collisions.cubes");
                    subs.unsubscribe("collisions.walls");
                    jme.enqueue[
                        subs.unsubscribe("ControlDronePhy");
                        drone.node.removeControl(ControlDronePhy)
                        true
                    ]
                ]
			}
			case crashing:{
				jme.enqueue[
				    animator.play(drone.node, "crashing")
                    true
				]
			}
			case exiting:{
				jme.enqueue[
				    // stop displacement
                    val phy0 = drone.node.getControl(RigidBodyControl)
                    phy0.setMass(0)
                    phy0.clearForces()
                    animator.play(drone.node, "exiting")
                    true
				]
			}
			case disconnecting:{
			}
		}
	}
	def static package Subscription pipe(InfoDrone drone, ControlDronePhy phy) {
		return Subscriptions.from(
		    drone.forward.subscribe[v|
                phy.forwardLg = v * drone.cfg.forward
                phy.linearDamping = drone.cfg.linearDamping
		    ]
		    , drone.turn.subscribe[v|
		        phy.turnLg = v * drone.cfg.turn		        
		    ]
		) 
	}
	
	@Inject
	@FinalFieldsConstructor
    new(){}	
}