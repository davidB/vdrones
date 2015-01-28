package vdrones;

import java.net.URL;
import java.util.ResourceBundle;

import javafx.beans.property.SimpleObjectProperty;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.event.EventHandler;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.geometry.Bounds;
import javafx.scene.control.Button;
import javafx.scene.control.ProgressBar;
import javafx.scene.image.ImageView;
import javafx.scene.input.MouseButton;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.FlowPane;
import javafx.scene.layout.Region;
import lombok.val;

public class HudLevelSelection implements Initializable{
	@FXML public Region root;
	@FXML public Button back;
	@FXML public FlowPane panes;

	public final ObservableList<Area> areas = FXCollections.observableArrayList();
	public final SimpleObjectProperty<Area> areaSelected = new SimpleObjectProperty<>();

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
		//panes.setVgap(8);
		//panes.setHgap(4);
		//panes.setPrefWrapLength(300); // preferred width = 300
		//panes.orientationProperty();
		for (Area area : areas) {
			val img = new ImageView(this.getClass().getResource("/Scenes/" + area.name() + ".jpg").toExternalForm());
			val btn = new Button("",img);
			btn.setDisable(!area.enable);
			btn.getStyleClass().add("btn_area");
			btn.setOnAction((evt) -> {
				areaSelected.set(area);
			});
			panes.getChildren().add(btn);
		}
	}
}
