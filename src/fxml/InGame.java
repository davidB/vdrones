package fxml;

import com.jme3x.jfx.FxPlatformExecutor;

import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.control.ProgressBar;
import javafx.scene.layout.StackPane;
import javafx.scene.shape.Rectangle;

public class InGame {
	@FXML
	private StackPane	root;

	@FXML
	private Label clock;

	@FXML
	private ProgressBar energy;

	@FXML
	private Rectangle health;

	@FXML
	private Label score;

	private int healthMax;
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
		health.widthProperty().bind(root.widthProperty());
		health.heightProperty().bind(root.heightProperty());
	}

	public void setHealthMax(int v) {
		healthMax = v;
	}

	public void setHealth(int current) {
		FxPlatformExecutor.runOnFxApplication(() ->
			health.setOpacity(((double)(healthMax - current))/healthMax)
		);
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
