package vdrones

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
import vdrones_settings.Commands

/** 
 * @author David Bernard
 */
package class PageWelcome extends AppState0 {
    final HudTools hudTools
    final PublishSubject<Pages> pm
    final InputMapper inputMapper
    final Commands commands
    boolean prevCursorVisible
    Hud<HudWelcome> hud
    Subscription inputSub

    override void doInitialize() {
        hud = hudTools.newHud("Interface/HudWelcome.fxml", new HudWelcome()) // hudTools.scaleToFit(hud, app.getGuiViewPort());
    }

    override protected void doEnable() {
        prevCursorVisible = app.getInputManager().isCursorVisible()
        app.getInputManager().setCursorVisible(true)
        app.getInputManager().addRawInputListener(inputMapper.rawInputListener)
        hudTools.show(hud)
        FxPlatformExecutor::runOnFxApplication[
            val p = hud.controller
            p.play.onActionProperty().set[v|
                app.enqueue[
                    pm.onNext(Pages.LevelSelection)
                    true
                ]
            ]
            p.garage.onActionProperty().set[v|
                app.enqueue[
                    pm.onNext(Pages.Garage)
                    true
                ]
            ]
            p.settings.onActionProperty().set[v|
                app.enqueue[
                    pm.onNext(Pages.Settings)
                    true
                ]
            ]
            p.quit.onActionProperty().set[v|
                app.enqueue[
                    app.stop()
                    true
                ]
            ]
        ]
        inputSub = Subscriptions::from(commands.exit.value.subscribe[v|
            if (!v) hud.controller.quit.fire()
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
