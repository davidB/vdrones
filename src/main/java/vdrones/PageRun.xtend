package vdrones

import com.jme3x.jfx.FxPlatformExecutor
import javax.inject.Inject
import javax.inject.Provider
import jme3_ext.AppState0
import jme3_ext.Hud
import jme3_ext.HudTools
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import rx.Observable
import rx.Subscriber
import rx.Subscription
import rx.subjects.PublishSubject
import rx.subscriptions.Subscriptions
import vdrones_runend.PageRunEnd
import vdrones_settings.Commands

class PageRun extends AppState0 {
	final HudTools hudTools
	final package Provider<AppStateRun> asRunP
	final package PageRunEnd pageRunEnd
	final Commands commands
	val PublishSubject<Pages> pm
	// use Provider as Hack to break the dependency cycle PageManager -> Page -> PageManager
	boolean prevCursorVisible
	Hud<HudRun> hud
	Subscription subscription

	override void doInitialize() {
		hud = hudTools.newHud("Interface/HudRun.fxml", new HudRun())
		hudTools.scaleToFit(hud, app.getGuiViewPort())
		reset()
	}

	override protected void doEnable() {
		prevCursorVisible = app.getInputManager().isCursorVisible()
		app.getInputManager().setCursorVisible(true)
		hudTools.show(hud)
		app.getStateManager().detach(app.getStateManager().getState(typeof(AppStateRun)))
		var AppStateRun asRun = asRunP.get()
		app.getStateManager().attach(asRun)
		var Channels channels = asRun.channels
		// Observable.switchOnNext(channels.droneInfo2s)
		var Subscription s1 = channels.drones.subscribe(
			new Subscriber<InfoDrone>() {
				Subscription subscription = null

				def void terminate() {
					if(subscription !== null) subscription.unsubscribe()
				}

				override void onCompleted() {
					terminate()
				}

				override void onError(Throwable e) {
					terminate()
				}

				override void onNext(InfoDrone t) {
					terminate()
					hud.controller.setEnergyMax(t.cfg.energyStoreMax)
					hud.controller.setHealthMax(t.cfg.healthMax)
					subscription = Subscriptions::from(
						t.energy.subscribe[v| hud.controller.energy = v]
						, t.health.subscribe[v| hud.controller.health = v]
						, t.score.subscribe[v| hud.controller.score = v]
						, t.score.subscribe[v| pageRunEnd.score = v]
					)
				}
			})
		// Observable.switchOnNext(
		var Subscription s2 = channels.areaInfo2s.subscribe(new Subscriber<InfoArea>() {
			Subscription subscription = null

			def void terminate() {
				if(subscription !== null) subscription.unsubscribe()
			}

			override void onCompleted() {
				terminate()
			}

			override void onError(Throwable e) {
				terminate()
			}

			override void onNext(InfoArea area) {
				terminate()
				subscription = area.clock.map[it.intValue()].distinctUntilChanged().subscribe[v| hud.controller.clock = v]
			}
		})
		var Subscription s5 = Subscriptions::from(commands.exit.value.subscribe[v|
			if (!v) pm.onNext(Pages.Welcome)
		])
		val success = channels.drones.flatMap[it.state].filter[it == InfoDrone.State.disconnecting].map[true]
		val failure = channels.areaInfo2s.flatMap[it.clock].filter[it <= 0].map[false]
		val end = Observable::merge(success, failure).first().subscribe[end(it)]
		subscription = Subscriptions::from(s1, s2, end, s5)
		hack_letFocusOn3d()
	}

	override protected void doDisable() {
		if (subscription !== null) {
			subscription.unsubscribe()
			subscription = null
		}
		hudTools.hide(hud)
		app.getInputManager().setCursorVisible(prevCursorVisible)
		app.getStateManager().detach(app.getStateManager().getState(typeof(AppStateRun)))
	}

	def package void hack_letFocusOn3d() {
		FxPlatformExecutor::runOnFxApplication[
			//HACK TO force focus (keyboard) on play area
			//hud.region.focusedProperty().addListener((v) -> System.out.println("focus change : " + v));
			//hud.region.requestFocus();
			//Scene scene = hud.region.getScene();
			//scene.getWindow().requestFocus();
			//Event.fireEvent(scene.getWindow(), new MouseEvent(MouseEvent.MOUSE_CLICKED, 10, 10, (int)scene.getWindow().getX() + 10, (int)scene.getWindow().getY() + 10, MouseButton.PRIMARY, 1, true, true, true, true, true, true, true, true, true, true, null));
			try {
				val r = new java.awt.Robot();
//				r.mouseMove((int)scene.getWindow().getX() + 10, (int)scene.getWindow().getY() + 10);
				r.mousePress(java.awt.event.InputEvent.BUTTON1_DOWN_MASK);
				r.mouseRelease(java.awt.event.InputEvent.BUTTON1_DOWN_MASK);
			} catch (Exception e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		]
	}

	def package void end(boolean success) {
		System::out.println('''end :«success»'''.toString)
		pageRunEnd.success = success
		app.enqueue[
			pm.onNext(Pages.RunEnd)
			reset()
			true
		]
	}

	def void reset() {
		setEnabled(false)
		setEnabled(true)
		hack_letFocusOn3d()
	}

	@Inject
	@FinalFieldsConstructor
	new(){}
}
