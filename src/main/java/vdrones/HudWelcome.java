/// License [CC0](http://creativecommons.org/publicdomain/zero/1.0/)
package vdrones;

import java.net.URL;
import java.util.ResourceBundle;

import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Button;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;

public class HudWelcome implements Initializable {
//	@FXML
//	public Region root;

	@FXML
	public Button play;
	@FXML
	public Button garage;
	@FXML
	public Button settings;

	@FXML
	public Button quit;

	@FXML
	public ImageView welcome;

	@Override
	public void initialize(URL location, ResourceBundle resources) {
		Image img = new Image(this.getClass().getResource("/Textures/logo_1280x720.png").toExternalForm());
		welcome.imageProperty().set(img);
	}

}
