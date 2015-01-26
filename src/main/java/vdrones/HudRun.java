package vdrones;

import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.control.ProgressBar;
import javafx.scene.shape.Rectangle;

import com.jme3x.jfx.FxPlatformExecutor;

public class HudRun {

	@FXML
	private Label clock;

	@FXML
	private ProgressBar energy;

	@FXML
	private Rectangle health;

	@FXML
	private Label score;

	private float healthMax;
	private float energyMax;

	@FXML
	public void initialize() {
		//this.website.getEngine().load("http://acid3.acidtests.org/");
		setScore(0);
		setClock(60);
		setEnergyMax(100);
		setEnergy(50);
		setHealthMax(100);
		setHealth(10);
	}

	public void setHealthMax(float v) {
		healthMax = v;
	}

	public void setHealth(float current) {
		FxPlatformExecutor.runOnFxApplication(() -> {
			double ratio = (double)((healthMax - current)/healthMax);
			ratio = ratio * ratio;
			health.setOpacity(ratio);
		});
	}

	public void setScore(int v) {
		FxPlatformExecutor.runOnFxApplication(() ->
			score.textProperty().setValue(((v > 0) ?"+" :"") + v)
		);
	}

	public void setClock(int v) {
		FxPlatformExecutor.runOnFxApplication(() ->
			clock.textProperty().setValue(String.format("%2d", v))
		);

	}

	public void setEnergyMax(float v) {
		energyMax = v;
	}

	public void setEnergy(float current) {
		FxPlatformExecutor.runOnFxApplication(() ->
			energy.setProgress(((double)current)/energyMax)
		);
	}

}
