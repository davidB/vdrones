/// License [CC0](http://creativecommons.org/publicdomain/zero/1.0/)
package vdrones.garage

import javax.inject.Inject
import vdrones.Pages
import jme3_ext.AppState0
import jme3_ext.Hud
import jme3_ext.HudTools
import jme3_ext.InputMapper
import rx.Subscription
import rx.subjects.PublishSubject
import rx.subscriptions.Subscriptions
import vdrones.settings.Commands
import com.jme3x.jfx.FxPlatformExecutor
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

/** 
 * @author David Bernard
 */
class PageGarage extends AppState0 {
    val HudTools hudTools
    val PublishSubject<Pages> pm
    val InputMapper inputMapper
    val Commands commands
    val AppStateGarage appGarage
    
    var boolean prevCursorVisible
    var Hud<HudGarage> hud
    var Subscription inputSub

    override void doInitialize() {
        hud = hudTools.newHud("Interface/HudGarage.fxml", new HudGarage())
        // hudTools.scaleToFit(hud, app.getGuiViewPort());
    }

    override protected void doEnable() {
        prevCursorVisible = app.getInputManager().isCursorVisible()
        app.getInputManager().setCursorVisible(true)
        app.getInputManager().addRawInputListener(inputMapper.rawInputListener)
        hudTools.show(hud)
        
        FxPlatformExecutor::runOnFxApplication[
            val p = hud.controller
            p.back.onActionProperty().set[e|
                app.enqueue[
                    pm.onNext(Pages.Welcome)
                    true
                ]
            ]
        ]
        app.getStateManager().attach(appGarage)
        inputSub = Subscriptions::from(commands.exit.value.subscribe[v|
            // if (!v) hud.controller.quit.fire()
        ])
        app.getStateManager().attach(appGarage)
    }

    override protected void doDisable() {
        app.getStateManager().detach(appGarage)
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
