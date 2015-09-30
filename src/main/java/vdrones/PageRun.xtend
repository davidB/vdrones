package vdrones

import javax.inject.Inject
import jme3_ext.AppState0
import jme3_ext.Hud
import jme3_ext.HudTools
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import rx.Subscriber
import rx.Subscription
import rx.subscriptions.Subscriptions

class PageRun extends AppState0 {
    final HudTools hudTools
    final package Channels channels
    final package AppStateRun asRun
    boolean prevCursorVisible
    Hud<HudRun> hud
    Subscription subscription

    override void doInitialize() {
        hud = hudTools.newHud("Interface/HudRun.fxml", new HudRun()) // hudTools.scaleToFit(hud, app.getGuiViewPort());
    }

    override protected void doEnable() {
        prevCursorVisible = app.getInputManager().isCursorVisible()
        app.getInputManager().setCursorVisible(false)
        hudTools.show(hud) // Observable.switchOnNext(channels.droneInfo2s)
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
                        t.energy.subscribe[v| hud.controller.setEnergy(v)],
                        t.health.subscribe[v| hud.controller.setHealth(v)],
                        t.score.subscribe[v| hud.controller.setScore(v)]
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
                subscription = area.clock
                    .map[v| v.intValue()]
                    .distinctUntilChanged()
                    .subscribe[v| hud.controller.clock = v]
            }
        })
        subscription = Subscriptions::from(s1, s2)
        app.getStateManager().attach(asRun)
    }

    override protected void doDisable() {
        hudTools.hide(hud)
        app.getInputManager().setCursorVisible(prevCursorVisible)
        app.getStateManager().detach(asRun)
        if (subscription !== null) {
            subscription.unsubscribe()
            subscription = null
        }

    }

    @Inject
    @FinalFieldsConstructor
    new(){}

}
