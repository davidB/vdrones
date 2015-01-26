/// License [CC0](http://creativecommons.org/publicdomain/zero/1.0/)
package vdrones;

import java.net.URL;
import java.util.ResourceBundle;

import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Button;
import javafx.scene.control.ComboBox;
import javafx.scene.effect.Glow;
import javafx.scene.layout.Region;

public class HudGarage implements Initializable{
	@FXML
	public Region root;

	@FXML
	public ComboBox<String> profileSelector;

	@FXML
	public Button back;

	@Override
	public void initialize(URL location, ResourceBundle resources) {
		Glow g = new Glow(0.3);
		root.getChildrenUnmodifiable().forEach((n) -> {
			if (n.getStyleClass().contains("indicator_garage")) {
				n.setEffect(g);
			}
		});
		//hud.region.effectProperty().set();
	}

}
