package vdrones

import com.jme3.app.SimpleApplication
import com.jme3.app.state.AppStateManager
import com.jme3.input.InputManager
import com.jme3.input.KeyInput
import com.jme3.input.controls.ActionListener
import com.jme3.input.controls.KeyTrigger
import javax.inject.Inject
import jme3_ext.AppState0
import jme3_ext_deferred.AppState4ViewDeferredTexture
import jme3_ext_spatial_explorer.AppStateSpatialExplorer
import jme3_ext_spatial_explorer.Helper
import jme3_ext_spatial_explorer.SpatialExplorer
import org.controlsfx.control.action.Action
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import rx.subjects.PublishSubject

class AppStateDebug extends AppState0 {
    final package PublishSubject<Pages> pm

    override protected void doEnable() {
        System.out.println("DEBUG ENABLE")
        var AppStateManager stateManager = app.getStateManager()
        app.getInputManager().setCursorVisible(true) // app.getViewPort().setBackgroundColor(v? ColorRGBA.Pink : ColorRGBA.White);
        var AppStateDeferredRendering r = stateManager.getState(AppStateDeferredRendering)
        if (r !== null) {
            stateManager.attach(
                new AppState4ViewDeferredTexture(r.processor, AppState4ViewDeferredTexture.ViewKey.values()))
        }
        Helper.setupSpatialExplorerWithAll(app)
        app.setPauseOnLostFocus(false)
        app.enqueue[
            val se = app.getStateManager().getState(AppStateSpatialExplorer)
            registerBarAction_ShowDeferredTexture(se.spatialExplorer, app);
            registerShortcut_GotoPage(pm, app);
            true
        ]
    }

    override protected void doDispose() {
        var AppStateManager stateManager = app.getStateManager()
        stateManager.detach(stateManager.getState(AppStateSpatialExplorer))
        System.out.println("DEBUG DISABLE")
    }

    def static void registerBarAction_ShowDeferredTexture(SpatialExplorer se, SimpleApplication app) {
        se.barActions.add(new Action("Show Deferred Texture", [evt|
            app.enqueue[
                val stateManager = app.getStateManager()
                val r = stateManager.getState(AppStateDeferredRendering)
                if (r != null) {
                    val s = stateManager.getState(AppState4ViewDeferredTexture)
                    if (s == null) {
                        stateManager.attach(new AppState4ViewDeferredTexture(r.processor, AppState4ViewDeferredTexture.ViewKey.values()))
                    } else {
                        stateManager.detach(s)
                    }
                }
                true
            ]
        ]))
    }

    def static void registerShortcut_GotoPage(PublishSubject<Pages> pm, SimpleApplication app) {
        val String prefixGoto = "GOTOPAGE_"
        var ActionListener a = [ String name, boolean isPressed, float tpf |
            if (isPressed && name.startsWith(prefixGoto)) {
                var int page = Integer.parseInt(name.substring(prefixGoto.length()))
                pm.onNext({
                    val _rdIndx_values = page
                    Pages.values().get(_rdIndx_values)
                })
            };
        ]
        var InputManager inputManager = app.getInputManager()

        for (var int i = 0; i < Pages.values().length; i++) {
            inputManager.addListener(a, prefixGoto + i)
        }
        inputManager.addMapping(prefixGoto + Pages.Welcome.ordinal(), new KeyTrigger(KeyInput.KEY_NUMPAD0)) // inputManager.addMapping(PageManager.prefixGoto + Page.LevelSelection.ordinal(), new KeyTrigger(KeyInput.KEY_NUMPAD1));
        // inputManager.addMapping(PageManager.prefixGoto + Page.Loading.ordinal(), new KeyTrigger(KeyInput.KEY_NUMPAD2));
        // inputManager.addMapping(PageManager.prefixGoto + Page.InGame.ordinal(), new KeyTrigger(KeyInput.KEY_NUMPAD3));
        // inputManager.addMapping(PageManager.prefixGoto + Page.Result.ordinal(), new KeyTrigger(KeyInput.KEY_NUMPAD4));
        inputManager.addMapping(prefixGoto + Pages.Settings.ordinal(), new KeyTrigger(KeyInput.KEY_NUMPAD5)) // inputManager.addMapping(PageManager.prefixGoto + Page.Scores.ordinal(), new KeyTrigger(KeyInput.KEY_NUMPAD6));
        // inputManager.addMapping(PageManager.prefixGoto + Page.About.ordinal(), new KeyTrigger(KeyInput.KEY_NUMPAD7));
    }

    @Inject
    @FinalFieldsConstructor
    new(){}

}
