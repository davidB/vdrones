package vdrones;

import vdrones.Injectors;
import com.jme3.app.Application;
import com.jme3.app.state.AbstractAppState;
import com.jme3.app.state.AppStateManager;
import com.jme3x.jfx.FXMLHud;
import com.jme3x.jfx.GuiManager;

import fxml.InGame;

public class AppStateHudInGame extends AbstractAppState {
	private GuiManager guiManager;
	private FXMLHud<InGame> hud;
	float clock;
	
	@Override
	public void initialize(AppStateManager stateManager, Application app) {
		super.initialize(stateManager, app);
		guiManager = Injectors.find(app).getInstance(GuiManager.class);
		
		hud = new FXMLHud<>("Interface/ingame.fxml");
		hud.precache();
		guiManager.attachHudAsync(hud);
	}
	
	@Override
	public void update(float tpf) {
		super.update(tpf);
		clock += tpf;
		hud.getController().setClock((int)clock);
	}
	
	@Override
	public void cleanup() {
		guiManager.detachHudAsync(hud);
		super.cleanup();
	}
}
