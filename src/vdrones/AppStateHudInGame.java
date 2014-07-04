package vdrones;

import rx.Subscription;
import rx.subscriptions.Subscriptions;

import com.jme3x.jfx.FXMLHud;
import com.jme3x.jfx.GuiManager;

import fxml.InGame;

public class AppStateHudInGame extends AppState0 {
	private GuiManager guiManager;
	private FXMLHud<InGame> hud;
	private Subscription subscription;

	@Override
	public void initialize() {
		guiManager = injector.getInstance(GuiManager.class);

		hud = new FXMLHud<>("Interface/ingame.fxml");
		hud.precache();
		guiManager.attachHudAsync(hud);
	}

	@Override
	public void dispose() {
		guiManager.detachHudAsync(hud);
	}

	@Override
	protected void enable() {
		subscription = Subscriptions.from(
			Pipes.pipe(injector.getInstance(DroneInfo.class), hud)
			, Pipes.pipe(injector.getInstance(AreaInfo.class), hud)
		);
	}

	@Override
	protected void disable() {
		subscription.unsubscribe();
	}
}
