package vdrones.settings

import com.jme3.audio.AudioNode
import com.jme3x.jfx.FxPlatformExecutor
import javax.inject.Inject
import jme3_ext.AppState0
import jme3_ext.AudioManager
import jme3_ext.Hud
import jme3_ext.HudTools
import jme3_ext.InputMapper
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.slf4j.LoggerFactory
import rx.Subscription
import rx.subjects.PublishSubject
import rx.subscriptions.Subscriptions
import vdrones.Pages

class PageSettings extends AppState0 {
    val log = LoggerFactory::getLogger(typeof(PageSettings))
    final HudTools hudTools
    final PublishSubject<Pages> pm
    final AudioManager audioMgr
    final HudSettings hudSettings
    final InputMapper inputMapper
    final Commands commands
    Subscription inputSub
    boolean prevCursorVisible
    AudioNode audioMusicTest
    AudioNode audioSoundTest
    Hud<HudSettings> hud

    override void doInitialize() {
        hud = hudTools.newHud("Interface/HudSettings.fxml", hudSettings) // hudTools.scaleToFit(hud, app.getGuiViewPort());
    }

    override protected void doEnable() {
        prevCursorVisible = app.getInputManager().isCursorVisible()
        app.getInputManager().setCursorVisible(true)
        app.getInputManager().addRawInputListener(inputMapper.rawInputListener)
        hudTools.show(hud)
        try {
            audioMusicTest = new AudioNode(app.getAssetManager(), "Musics/Hypnothis.ogg", true)
            audioMusicTest.setLooping(false)
            audioMusicTest.setPositional(false)
            audioMgr.musics.add(audioMusicTest)
            app.getRootNode().attachChild(audioMusicTest)
        } catch (Exception exc) {
            log.warn("failed to setup audioMusicTest", exc)
        }
        try {
            audioSoundTest = new AudioNode(app.getAssetManager(), "Sounds/boost.wav", false) // buffered
            audioSoundTest.setLooping(false)
            audioMusicTest.setPositional(false)
            app.getRootNode().attachChild(audioSoundTest)
        } catch (Exception exc) {
            log.warn("failed to setup audioSoundTest", exc)
        }
        FxPlatformExecutor::runOnFxApplication[
            val p = hud.controller;
            p.load(app)
            p.audioMusicTest.onActionProperty().set[e|
                app.enqueue[
                    if (audioMusicTest != null) audioMusicTest.play()
                    true                    
                ]
            ]
            p.audioMusicTest.setDisable(audioMusicTest == null)

            p.audioSoundTest.onActionProperty().set[e|
                app.enqueue[
                    if (audioSoundTest != null) audioSoundTest.playInstance()
                    true
                ]
            ]
            p.audioSoundTest.setDisable(audioSoundTest == null)
            
            p.back.onActionProperty().set[e|
                app.enqueue[
                    pm.onNext(Pages.Welcome)
                    true
                ]
            ]
        ]

        inputSub = Subscriptions::from(commands.exit.value.subscribe[v|
            if (!v) hud.controller.back.fire()
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
        if (audioSoundTest !== null) {
            audioSoundTest.pause()
            app.getRootNode().detachChild(audioSoundTest)
        }
        if (audioMusicTest !== null) {
            audioMusicTest.pause()
            app.getRootNode().detachChild(audioMusicTest)
            audioMgr.musics.remove(audioMusicTest)
        }

    }

    @Inject
    @FinalFieldsConstructor
    new(){}
}
