/// License [CC0](http://creativecommons.org/publicdomain/zero/1.0/)
package vdrones_runend

import com.jme3.audio.AudioNode
import com.jme3x.jfx.FxPlatformExecutor
import javax.inject.Singleton
import jme3_ext.AppState0
import jme3_ext.Hud
import jme3_ext.HudTools
import jme3_ext.InputMapper
import rx.Subscription
import rx.subjects.PublishSubject
import rx.subscriptions.Subscriptions
import vdrones_settings.Commands
import javax.inject.Inject
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import vdrones.Pages

/** 
 * @author David Bernard
 */
@Singleton
class PageRunEnd extends AppState0 {
	final HudTools hudTools
	final InputMapper inputMapper
	final Commands controls
	val PublishSubject<Pages> pm
	// use Provider as Hack to break the dependency cycle PageManager -> Page -> PageManager
	boolean prevCursorVisible
	Hud<HudRunEnd> hud
	Subscription inputSub
	AudioNode audioGameOver
	AudioNode audioTryAgain
	public boolean success = true
	package int score = 0

	override void doInitialize() {
		hud = hudTools.newHud("Interface/HudRunEnd.fxml", new HudRunEnd()) // try {
		// audioGameOver = new AudioNode(app.getAssetManager(), "Sounds/game_over.ogg", false); // buffered
		// audioGameOver.setLooping(false);
		// audioGameOver.setPositional(true);
		// app.getRootNode().attachChild(audioGameOver);
		// } catch(Exception exc){
		// log.warn("failed to load 'Sounds/game_over.ogg'", exc);
		// }
		// try {
		// audioTryAgain = new AudioNode(app.getAssetManager(), "Sounds/try_again.ogg", false); // buffered
		// audioTryAgain.setLooping(false);
		// audioTryAgain.setPositional(true);
		// app.getRootNode().attachChild(audioTryAgain);
		// } catch(Exception exc){
		// log.warn("failed to load 'Sounds/ry_again.ogg'", exc);
		// }
	}

	override protected void doEnable() {
		prevCursorVisible = app.getInputManager().isCursorVisible()
		app.getInputManager().setCursorVisible(true)
		app.getInputManager().addRawInputListener(inputMapper.rawInputListener)
		hudTools.show(hud)
		FxPlatformExecutor::runOnFxApplication[
			val p = hud.controller
			if (success) {
				p.time.setText(""+score)
				p.timeCount.setText("")
				p.time.setVisible(true)
				//p.timeCount.setText(String.format("%d",app.getStateManager().getState(PageRun.class).score()));
				app.enqueue[
					if (audioTryAgain != null) audioTryAgain.play()
					true
				]
			} else {
				p.time.setVisible(false);
				p.timeCount.setText("Time Out !!");
				app.enqueue[
					if (audioGameOver != null) audioGameOver.play()
					true
				]
			}
			p.retry.onActionProperty().set[v|
				app.enqueue[
					//app.getStateManager().getState(PageRun.class).reset();
					pm.onNext(Pages.Run)
					true
				]
			]
			p.levels.onActionProperty().set[v|
				app.enqueue[
//					setEnabled(false);
//					app.getStateManager().detach(this);
//					app.getStateManager().getState(PageRun.class).setEnabled(false);
					pm.onNext(Pages.LevelSelection)
					true
				]
			]
			p.home.onActionProperty().set[v|
				app.enqueue[
//					setEnabled(false);
//					app.getStateManager().detach(this);
//					app.getStateManager().getState(PageRun.class).setEnabled(false);
					pm.onNext(Pages.Welcome)
					true
				]
			]
		]
 // p.timeCount.setText(String.format("%d",app.getStateManager().getState(PageRun.class).score()));
		// app.getStateManager().getState(PageRun.class).reset();
		// setEnabled(false);
		// app.getStateManager().detach(this);
		// app.getStateManager().getState(PageRun.class).setEnabled(false);
		// setEnabled(false);
		// app.getStateManager().detach(this);
		// app.getStateManager().getState(PageRun.class).setEnabled(false);
		inputSub = Subscriptions::from(
			controls.exit.value.subscribe[v|
				if (!v) hud.controller.home.fire()
			]
		)
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
