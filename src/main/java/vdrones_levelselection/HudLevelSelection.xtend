package vdrones_levelselection

import java.net.URL
import java.util.ResourceBundle
import javafx.beans.property.SimpleObjectProperty
import javafx.collections.FXCollections
import javafx.fxml.FXML
import javafx.fxml.Initializable
import javafx.scene.control.Button
import javafx.scene.image.ImageView
import javafx.scene.layout.FlowPane
import javafx.scene.layout.Region
import vdrones.Area

class HudLevelSelection implements Initializable {
	@FXML public Region root
	@FXML public Button back
	@FXML public FlowPane panes
	public val areas = FXCollections.<Area>observableArrayList()
	public val areaSelected = new SimpleObjectProperty<Area>()

//	val updateProgressOnclick = new EventHandler<MouseEvent>(){
//		override handle(MouseEvent event) {
//			if (event.getButton() == MouseButton.PRIMARY){
//				val p = event.getSource() as ProgressBar
//				val b1 = p.getLayoutBounds()
//				var percent = event.getX() / (b1.getMaxX() - b1.getMinX())
//				percent = Math.max(0, Math.min(1.0, percent))
//				p.setProgress(percent)
//			}
//		}
//	} 

	override void initialize(URL location, ResourceBundle resources) {
		// panes.setVgap(8);
		// panes.setHgap(4);
		// panes.setPrefWrapLength(300); // preferred width = 300
		// panes.orientationProperty();
		for (Area area : areas) {
			val img = new ImageView(this.getClass().getResource('''/Scenes/«area.name()».jpg''').toExternalForm())
			val btn = new Button("", img)
			btn.setDisable(!area.enable)
			btn.getStyleClass().add("btn_area")
			btn.setOnAction[v|areaSelected.set(area)]
			panes.getChildren().add(btn)
		}

	}

}
