package vdrones_garage

import java.net.URL
import java.util.ResourceBundle
import javafx.event.EventHandler
import javafx.fxml.FXML
import javafx.fxml.Initializable
import javafx.scene.control.Button
import javafx.scene.control.ComboBox
import javafx.scene.control.ProgressBar
import javafx.scene.effect.Glow
import javafx.scene.input.MouseButton
import javafx.scene.input.MouseEvent
import javafx.scene.layout.Region
import javafx.scene.layout.VBox

class HudGarage implements Initializable {
    @FXML public Region root
    @FXML public ComboBox<String> profileSelector
    @FXML public Button back
    @FXML public VBox propulsion_forward
    @FXML public VBox rotation_speed
    @FXML public VBox jumper
    @FXML public VBox propulsion_side
    @FXML public VBox boost_forward
    @FXML public VBox propulsion_backward
    @FXML public VBox shield_blue
    @FXML public VBox shield_red
    @FXML public VBox shield_green
    @FXML public VBox energy_provider
    @FXML public VBox energy_store
    final package EventHandler<MouseEvent> updateProgressOnclick = [MouseEvent event|
        if (event.getButton() == MouseButton.PRIMARY){
            val p = event.getSource() as ProgressBar
            val b1 = p.getLayoutBounds()
            var percent = event.getX() / (b1.getMaxX() - b1.getMinX());
            percent = Math.max(0, Math.min(1.0, percent));
            //System.out.printf("percent : %s, %s, %s, %s\n", percent, event.getX(), event.getSceneX(), b1.getMinX());
            p.setProgress(percent);
        }
    ]

    // System.out.printf("percent : %s, %s, %s, %s\n", percent, event.getX(), event.getSceneX(), b1.getMinX());
    override void initialize(URL location, ResourceBundle resources) {
        val Glow g = new Glow(0.3)
        root.getChildrenUnmodifiable().forEach[n|
            if (n.getStyleClass().contains("indicator_garage")) {
                n.setEffect(g)
            }
        ]
        // hud.region.effectProperty().set();
        val vboxes = #[propulsion_forward, rotation_speed, jumper, propulsion_side, boost_forward, boost_forward,
            propulsion_backward, propulsion_backward, shield_blue, shield_blue, shield_red, shield_green,
            energy_provider, energy_store
        ]
        for (v : vboxes) {
            val progress = findProgressBar(v)
            progress.addEventHandler(MouseEvent.MOUSE_DRAGGED, updateProgressOnclick)
            progress.addEventHandler(MouseEvent.MOUSE_PRESSED, updateProgressOnclick)
        }
    }

    def package ProgressBar findProgressBar(VBox v) {
        return v.getChildrenUnmodifiable().filtered[it instanceof ProgressBar].get(0) as ProgressBar
    }

    //new(){}
}
