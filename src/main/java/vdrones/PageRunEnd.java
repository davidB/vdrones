/// License [CC0](http://creativecommons.org/publicdomain/zero/1.0/)
package vdrones;

import javax.inject.Inject;
import javax.inject.Provider;

import jme3_ext.AppState0;
import jme3_ext.Hud;
import jme3_ext.HudTools;
import jme3_ext.InputMapper;
import jme3_ext.PageManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import rx.Subscription;
import rx.subscriptions.Subscriptions;

import com.jme3.audio.AudioNode;
import com.jme3x.jfx.FxPlatformExecutor;

/**
 *
 * @author David Bernard
 */
@Slf4j
@RequiredArgsConstructor(onConstructor=@__(@Inject))
class PageRunEnd extends AppState0 {
	private final HudTools hudTools;
	private final InputMapper inputMapper;
	private final Commands controls;
	private final Provider<PageManager> pm; // use Provider as Hack to break the dependency cycle PageManager -> Page -> PageManager

	private boolean prevCursorVisible;
	private Hud<HudRunEnd> hud;
	private Subscription inputSub;
	private AudioNode audioGameOver;
	private AudioNode audioTryAgain;
	public boolean success = true;


	@Override
	public void doInitialize() {
		hud = hudTools.newHud("Interface/HudRunEnd.fxml", new HudRunEnd());
		try {
			audioGameOver = new AudioNode(app.getAssetManager(), "Sounds/game_over.ogg", false); // buffered
			audioGameOver.setLooping(false);
			audioGameOver.setPositional(true);
			app.getRootNode().attachChild(audioGameOver);
		} catch(Exception exc){
			log.warn("failed to load 'Sounds/game_over.ogg'", exc);
		}
		try {
			audioTryAgain = new AudioNode(app.getAssetManager(), "Sounds/try_again.ogg", false); // buffered
			audioTryAgain.setLooping(false);
			audioTryAgain.setPositional(true);
			app.getRootNode().attachChild(audioTryAgain);
		} catch(Exception exc){
			log.warn("failed to load 'Sounds/ry_again.ogg'", exc);
		}
	}

	@Override
	protected void doEnable() {
		prevCursorVisible = app.getInputManager().isCursorVisible();
		app.getInputManager().setCursorVisible(true);
		app.getInputManager().addRawInputListener(inputMapper.rawInputListener);
		hudTools.show(hud);

		FxPlatformExecutor.runOnFxApplication(() -> {
			HudRunEnd p = hud.controller;
			if (success) {
				p.time.setVisible(true);
				//p.timeCount.setText(String.format("%d",app.getStateManager().getState(PageRun.class).score()));
				app.enqueue(()->{
					if (audioTryAgain != null) audioTryAgain.play();
					return true;
				});
			} else {
				p.time.setVisible(false);
				p.timeCount.setText("Game Over !!");
				app.enqueue(()->{
					if (audioGameOver != null) audioGameOver.play();
					return true;
				});
			}
			p.retry.onActionProperty().set((v) -> {
				app.enqueue(()-> {
					//app.getStateManager().getState(PageRun.class).reset();
					setEnabled(false);
					app.getStateManager().detach(this);
					PageRun pr = app.getStateManager().getState(PageRun.class);
					//app.getStateManager().getState(PageRun.class).setEnabled(false);
					pr.reset();
					//pm.get().goTo(Pages.Run.ordinal());
					return true;
				});
			});
			p.levels.onActionProperty().set((v) -> {
				app.enqueue(()-> {
					setEnabled(false);
					app.getStateManager().detach(this);
					app.getStateManager().getState(PageRun.class).setEnabled(false);
					pm.get().goTo(Pages.LevelSelection.ordinal());
					return true;
				});
			});
			p.home.onActionProperty().set((v) -> {
				app.enqueue(()-> {
					setEnabled(false);
					app.getStateManager().detach(this);
					app.getStateManager().getState(PageRun.class).setEnabled(false);
					pm.get().goTo(Pages.Welcome.ordinal());
					return true;
				});
			});
		});

		inputSub = Subscriptions.from(
			controls.exit.value.subscribe((v) -> {
				if (!v) hud.controller.retry.fire();
			})
//			,controls.def.value.subscribe((v) -> {
//				if (!v) hud.controller.retry.fire();
//			})
		);
	}

	@Override
	protected void doDisable() {
		hudTools.hide(hud);
		app.getInputManager().setCursorVisible(prevCursorVisible);
		app.getInputManager().removeRawInputListener(inputMapper.rawInputListener);
		if (inputSub != null){
			inputSub.unsubscribe();
			inputSub = null;
		}
	}
}
