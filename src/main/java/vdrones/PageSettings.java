package vdrones;

import javax.inject.Inject;

import jme3_ext.AppState0;
import jme3_ext.AudioManager;
import jme3_ext.Hud;
import jme3_ext.HudTools;
import jme3_ext.InputMapper;
import jme3_ext.PageManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import rx.Subscription;
import rx.subjects.PublishSubject;
import rx.subscriptions.Subscriptions;

import com.jme3.audio.AudioNode;
import com.jme3x.jfx.FxPlatformExecutor;

@RequiredArgsConstructor(onConstructor=@__(@Inject))
@Slf4j
public class PageSettings extends AppState0{
	private final HudTools hudTools;
	private final PublishSubject<Pages> pm;
	private final AudioManager audioMgr;
	private final HudSettings hudSettings;
	private final InputMapper inputMapper;
	private final Commands commands;

	private Subscription inputSub;
	private boolean prevCursorVisible;
	private AudioNode audioMusicTest;
	private AudioNode audioSoundTest;
	private Hud<HudSettings> hud;

	@Override
	public void doInitialize() {
		hud = hudTools.newHud("Interface/HudSettings.fxml", hudSettings);
		//hudTools.scaleToFit(hud, app.getGuiViewPort());
	}

	@Override
	protected void doEnable() {
		prevCursorVisible = app.getInputManager().isCursorVisible();
		app.getInputManager().setCursorVisible(true);
		app.getInputManager().addRawInputListener(inputMapper.rawInputListener);
		hudTools.show(hud);
		try {
			audioMusicTest = new AudioNode(app.getAssetManager(), "Musics/Hypnothis.ogg", true);
			audioMusicTest.setLooping(false);
			audioMusicTest.setPositional(false);
			audioMgr.musics.add(audioMusicTest);
			app.getRootNode().attachChild(audioMusicTest);
		} catch (Exception exc){
			log.warn("failed to setup audioMusicTest", exc);
		}

		try {
			audioSoundTest = new AudioNode(app.getAssetManager(), "Sounds/boost.wav", false); // buffered
			audioSoundTest.setLooping(false);
			audioMusicTest.setPositional(false);
			app.getRootNode().attachChild(audioSoundTest);
		} catch (Exception exc){
			log.warn("failed to setup audioSoundTest", exc);
		}

		FxPlatformExecutor.runOnFxApplication(() -> {
			HudSettings p = hud.controller;
			p.load(app);

			p.audioMusicTest.onActionProperty().set((e) -> {
				app.enqueue(()-> {
					if (audioMusicTest != null) audioMusicTest.play();
					return true;
				});
			});
			p.audioMusicTest.setDisable(audioMusicTest == null);

			p.audioSoundTest.onActionProperty().set((e) -> {
				app.enqueue(()-> {
					if (audioSoundTest != null) audioSoundTest.playInstance();
					return true;
				});
			});
			p.audioSoundTest.setDisable(audioSoundTest == null);

			p.back.onActionProperty().set((e) -> {
				app.enqueue(()-> {
					pm.onNext(Pages.Welcome);
					return true;
				});
			});
		});

		inputSub = Subscriptions.from(
			commands.exit.value.subscribe((v) -> {
				if (!v) hud.controller.back.fire();
			})
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
		if (audioSoundTest != null) {
			audioSoundTest.pause();
			app.getRootNode().detachChild(audioSoundTest);
		}
		if (audioMusicTest != null) {
			audioMusicTest.pause();
			app.getRootNode().detachChild(audioMusicTest);
			audioMgr.musics.remove(audioMusicTest);
		}
	}
}
