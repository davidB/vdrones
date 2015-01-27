/// License [CC0](http://creativecommons.org/publicdomain/zero/1.0/)
package vdrones;

import java.net.URL;
import java.util.ResourceBundle;

import javafx.event.EventHandler;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.geometry.Bounds;
import javafx.scene.control.Button;
import javafx.scene.control.ColorPicker;
import javafx.scene.control.ComboBox;
import javafx.scene.control.ProgressBar;
import javafx.scene.effect.Glow;
import javafx.scene.input.MouseButton;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.Region;
import javafx.scene.layout.VBox;

public class HudGarage implements Initializable{
	@FXML public Region root;
	@FXML public ComboBox<String> profileSelector;
	@FXML public Button back;
	@FXML public VBox propulsion_forward;
	@FXML public VBox rotation_speed;
	@FXML public VBox jumper;
	@FXML public VBox propulsion_side;
	@FXML public VBox boost_forward;
	@FXML public VBox propulsion_backward;
	@FXML public VBox shield_blue;
	@FXML public VBox shield_red;
	@FXML public VBox shield_green;
	@FXML public VBox energy_provider;
	@FXML public VBox energy_store;

	final EventHandler<MouseEvent> updateProgressOnclick = (MouseEvent event) -> {
		if (event.getButton() == MouseButton.PRIMARY){
			ProgressBar p = (ProgressBar)event.getSource();
			Bounds b1 = p.getLayoutBounds();
			double percent = event.getX() / (b1.getMaxX() - b1.getMinX());
			percent = Math.max(0, Math.min(1.0, percent));
			//System.out.printf("percent : %s, %s, %s, %s\n", percent, event.getX(), event.getSceneX(), b1.getMinX());
			p.setProgress(percent);
		}
	};

	@Override
	public void initialize(URL location, ResourceBundle resources) {
		Glow g = new Glow(0.3);
		root.getChildrenUnmodifiable().forEach((n) -> {
			if (n.getStyleClass().contains("indicator_garage")) {
				n.setEffect(g);
			}
		});
		//hud.region.effectProperty().set();
		for(VBox v : new VBox[]{propulsion_forward, rotation_speed, jumper, propulsion_side, boost_forward, boost_forward, propulsion_backward, propulsion_backward, shield_blue, shield_blue, shield_red, shield_green, energy_provider, energy_store}) {
			ProgressBar progress = findProgressBar(v);
			progress.addEventHandler(MouseEvent.MOUSE_DRAGGED, updateProgressOnclick);
			progress.addEventHandler(MouseEvent.MOUSE_PRESSED, updateProgressOnclick);
		}
	}

	ProgressBar findProgressBar(VBox v) {
		return (ProgressBar)v.getChildrenUnmodifiable().filtered((n) -> (n instanceof ProgressBar)).get(0);
	}
}
