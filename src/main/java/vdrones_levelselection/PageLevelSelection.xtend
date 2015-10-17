package vdrones_levelselection

import com.jme3x.jfx.FxPlatformExecutor
import javax.inject.Inject
import jme3_ext.AppState0
import jme3_ext.Hud
import jme3_ext.HudTools
import jme3_ext.InputMapper
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import rx.Subscription
import rx.subjects.PublishSubject
import rx.subscriptions.Subscriptions
import vdrones.Area
import vdrones.Pages
import vdrones_settings.Commands

/** 
 * @author David Bernard
 */
class PageLevelSelection extends AppState0 {
	final HudTools hudTools
	val PublishSubject<Pages> pm
	// use Provider as Hack to break the dependency cycle PageManager -> Page -> PageManager
	final InputMapper inputMapper
	final Commands commands
	boolean prevCursorVisible
	Hud<HudLevelSelection> hud
	Subscription inputSub
	public Area areaSelected

	override void doInitialize() {
		var ctrl = new HudLevelSelection()
		ctrl.areas.addAll(Area.values)
		hud = hudTools.newHud("Interface/HudLevelSelection.fxml", ctrl)
		hudTools.scaleToFit(hud, app.getGuiViewPort())
	}

	override protected void doEnable() {
		prevCursorVisible = app.getInputManager().isCursorVisible()
		app.getInputManager().setCursorVisible(true)
		app.getInputManager().addRawInputListener(inputMapper.rawInputListener)
		hudTools.show(hud)
		FxPlatformExecutor::runOnFxApplication[
			val p = hud.controller
			p.areaSelected.addListener[pr, ov, nv|
				areaSelected = nv
				app.enqueue[
					pm.onNext(Pages.Run)
					true
				]
			]
			p.back.onActionProperty().set[e|
				app.enqueue[
					pm.onNext(Pages.Welcome)
					true
				]
			]
			
		]
		inputSub = Subscriptions::from(commands.exit.value.subscribe[v|
			// if (!v) hud.controller.quit.fire();
		])
	}

	override protected void doDisable() {
		hudTools.hide(hud)
		app.getInputManager().setCursorVisible(prevCursorVisible)
		app.getInputManager().removeRawInputListener(inputMapper.rawInputListener)
		if (inputSub !== null) {
			inputSub.unsubscribe()
			inputSub = null
		}

	}

	@Inject
	@FinalFieldsConstructor
	new(){}
}
