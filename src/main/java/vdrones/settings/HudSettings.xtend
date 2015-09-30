/// License [CC0](http://creativecommons.org/publicdomain/zero/1.0/)
package vdrones.settings

import com.jme3.app.SimpleApplication
import com.jme3.input.event.InputEvent
import com.jme3.system.AppSettings
import java.awt.DisplayMode
import java.awt.GraphicsDevice
import java.awt.GraphicsEnvironment
import java.net.URL
import java.util.Collection
import java.util.Collections
import java.util.LinkedList
import java.util.List
import java.util.ResourceBundle
import javafx.beans.property.SimpleObjectProperty
import javafx.beans.value.ChangeListener
import javafx.collections.FXCollections
import javafx.fxml.FXML
import javafx.fxml.Initializable
import javafx.geometry.Pos
import javafx.scene.control.Button
import javafx.scene.control.CheckBox
import javafx.scene.control.ChoiceBox
import javafx.scene.control.Label
import javafx.scene.control.Slider
import javafx.scene.control.TableCell
import javafx.scene.control.TableColumn
import javafx.scene.control.TableView
import javafx.scene.image.ImageView
import javafx.scene.layout.HBox
import javafx.util.StringConverter
import javax.inject.Inject
import jme3_ext.AppSettingsLoader
import jme3_ext.AudioManager
import jme3_ext.Command
import jme3_ext.InputMapper
import jme3_ext.InputMapperHelpers
import jme3_ext.InputTextureFinder
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

class HudSettings implements Initializable {
    final package AppSettingsLoader loader
    final package AudioManager audio
    final package InputMapper inputMapper
    final package Commands commands
    final package InputTextureFinder inputTextureFinders
    ResourceBundle resources
    // @FXML
    // public Region root;
    @FXML public Label title
    @FXML public Button back
    @FXML public ChoiceBox<Integer> antialiasing
    @FXML public CheckBox fullscreen
    @FXML public ChoiceBox<DisplayMode> resolution
    @FXML public CheckBox showFps
    @FXML public CheckBox showStats
    @FXML public Slider audioMasterVolume
    @FXML public Slider audioMusicVolume
    @FXML public Slider audioSoundVolume
    @FXML public CheckBox vsync
    @FXML public Button applyVideo
    @FXML public Button audioSoundTest
    @FXML public Button audioMusicTest
    @FXML public TableView<Command<?>> controlsMapping

    override void initialize(URL location, ResourceBundle resources) {
        this.resources = resources
        antialiasing.setConverter(new StringConverter<Integer>() {
            ResourceBundle resourceBundle = ResourceBundle.getBundle("com.jme3.app/SettingsDialog")

            override String toString(Integer input) {
                return if((input === 0)) resourceBundle.getString("antialias.disabled") else '''«input»x'''
            }

            override Integer fromString(String string) {
                // TODO Auto-generated method stub
                return null
            }
        })
        resolution.setConverter(
            new StringConverter<DisplayMode>() {
                override String toString(DisplayMode input) {
                    var String dp = if((input.getBitDepth() > 0)) String.valueOf(input.getBitDepth()) else "??"
                    var String freq = if((input.getRefreshRate() !== DisplayMode.REFRESH_RATE_UNKNOWN)) String.valueOf(
                            input.getRefreshRate()) else "??"
                    return String.format("%dx%d (%s bit) %sHz", input.getWidth(), input.getHeight(), dp, freq)
                }

                override DisplayMode fromString(String string) {
                    // TODO Auto-generated method stub
                    return null
                }
            })

        antialiasing.valueProperty().addListener[v, o, n|applyVideo.setDisable(false)]
        fullscreen.selectedProperty().addListener[v, o, n|applyVideo.setDisable(false)]
        resolution.valueProperty().addListener[v, o, n|applyVideo.setDisable(false)]
        showFps.selectedProperty().addListener[v, o, n|applyVideo.setDisable(false)]
        showStats.selectedProperty().addListener[v, o, n|applyVideo.setDisable(false)]
        vsync.selectedProperty().addListener[v, o, n|applyVideo.setDisable(false)]

        audioMasterVolume.setMax(1.0)
        audioMasterVolume.setMin(0.0)
        audioMusicVolume.setMax(1.0)
        audioMusicVolume.setMin(0.0)
        audioSoundVolume.setMax(1.0)
        audioSoundVolume.setMin(0.0)
        audioSoundTest.setDisable(true)
        audioMusicTest.setDisable(true)
    }

    def void load(SimpleApplication app) {
        val AppSettings settingsInit = new AppSettings(false)
        settingsInit.copyFrom(app.getContext().getSettings())
        loadDisplayModes(settingsInit)
        fullscreen.setSelected(settingsInit.isFullscreen())
        vsync.setSelected(settingsInit.isVSync()) // showStats.setSelected(settingsInit.is) = new DefaultCheckboxModel();
        // showFps.setSelected(settingsInit.isFullscreen());
        loadAntialias(settingsInit)
        val Runnable saveSettings = [
            try {
                loader.save(app.getContext().getSettings());
            } catch (Exception e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            }
        ]
        // TODO Auto-generated catch block
        applyVideo.onActionProperty().set [ v |
            apply(app)
            saveSettings.run()
            applyVideo.setDisable(true)
        ]
        applyVideo.setDisable(true) // TODO save when tab lost focus
        audioMasterVolume.valueProperty().bindBidirectional(audio.masterVolume)
        audioMusicVolume.valueProperty().bindBidirectional(audio.musicVolume)
        audioSoundVolume.valueProperty().bindBidirectional(audio.soundVolume)
        audio.loadFromAppSettings()

        val ChangeListener<Boolean> saveAudio = [ v, o, n |
            // on lost focus
            if (!n) {
                audio.saveIntoAppSettings()
                saveSettings.run()
            }
        ]
        audioMasterVolume.focusedProperty().addListener(saveAudio)
        audioMusicVolume.focusedProperty().addListener(saveAudio)
        audioSoundVolume.focusedProperty().addListener(saveAudio)
        loadControls()
    }

    def package void loadDisplayModes(AppSettings settings0) {
        var List<DisplayMode> r = new LinkedList<DisplayMode>()
        r.add(
            new DisplayMode(settings0.getWidth(), settings0.getHeight(), settings0.getDepthBits(),
                settings0.getFrequency()))
        // r.add(new DisplayMode(800, 600, 24, 60));
        // r.add(new DisplayMode(1024, 768, 24, 60));
        // r.add(new DisplayMode(1280, 720, 24, 60));
        // r.add(new DisplayMode(1280, 1024, 24, 60));
        // for(GraphicsDevice device : GraphicsEnvironment.getLocalGraphicsEnvironment().getScreenDevices()) {
        var GraphicsDevice device = GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice()
        for (DisplayMode mode : device.getDisplayModes()) {
            r.add(mode)
        }
        // }
        Collections.sort(r, [ DisplayMode d1, DisplayMode d2 |
            if (d1.getWidth() > d2.getWidth())
                1
            else if (d1.getHeight() > d2.getHeight())
                1
            else if(d1.getWidth() !== d2.getWidth() || d1.getHeight() !== d2.getHeight()) -1 else 0
        ])
        resolution.itemsProperty().get().clear()
        resolution.itemsProperty().get().setAll(r)
        var DisplayMode current = null

        for (var int i = 0; i < r.size(); i++) {
            var DisplayMode mode = r.get(i)
            if (mode.getWidth() === settings0.getWidth() && mode.getHeight() === settings0.getHeight()) {
                current = mode
            }

        }
        resolution.valueProperty().set(current)
    }

    def package void loadAntialias(AppSettings settings0) {
        val r = #[0, 2, 4, 6, 8, 16]

        antialiasing.itemsProperty().get().clear()
        antialiasing.itemsProperty().get().setAll(r)
        antialiasing.valueProperty().set(Math.max(settings0.getSamples(), 0))
    }

    def package void apply(SimpleApplication app) {
        try {
            app.setDisplayFps(showFps.isSelected())
            app.setDisplayStatView(showStats.isSelected())
            app.setShowSettings(true)
            var AppSettings settingsEdit = new AppSettings(false)
            settingsEdit.copyFrom(app.getContext().getSettings())
            settingsEdit.setFullscreen(fullscreen.isSelected())
            settingsEdit.setVSync(vsync.isSelected())
            var DisplayMode mode = resolution.getValue()
            settingsEdit.setResolution(mode.getWidth(), mode.getHeight())
            settingsEdit.setDepthBits(mode.getBitDepth())
            settingsEdit.setFrequency(
                if(!vsync.isSelected()) 0 else if((mode.getRefreshRate() !== DisplayMode.REFRESH_RATE_UNKNOWN)) mode.
                    getRefreshRate() else 60)
            settingsEdit.setSamples(antialiasing.getValue())
            app.setSettings(settingsEdit)
            settingsEdit.save(settingsEdit.getTitle())
            app.restart()
        // ((Main)app).onNextReshape = new Function<Main,Boolean>(){
        // @Override
        // public Boolean apply(Main input) {
        // Widgets.fullCamera(hudPanel, input.getCamera());
        // return true;
        // }
        //
        // };
        } catch (Exception exc) {
            throw new RuntimeException(exc)
        }

    }

    def package void loadControls() {
        controlsMapping.setItems(FXCollections.observableArrayList(commands.all)) /*FIXME Cannot add Annotation to Variable declaration. Java code: @SuppressWarnings("unchecked")*/
        val labels = controlsMapping.getColumns().get(0) as TableColumn<Command<?>, String>
        labels.setCellValueFactory(null) // labels.setCellValueFactory(new PropertyValueFactory<Control<?>, String>("label")); //TODO i18n
        /*FIXME Cannot add Annotation to Variable declaration. Java code: @SuppressWarnings("unchecked")*/
        val inputs = controlsMapping.getColumns().get(1) as TableColumn<Command<?>, Collection<InputEvent>>
        // inputs.setCellValueFactory((p) -> FXCollections.observableList(InputMapperHelpers.findTemplatesOf(inputMapper, p.getValue().value)));
        inputs.setCellValueFactory [ p |
            new SimpleObjectProperty(InputMapperHelpers.findTemplatesOf(inputMapper, p.getValue().value))
        ]
        inputs.setCellFactory [ TableColumn<Command<?>, Collection<InputEvent>> param |
            new TC(inputTextureFinders)
        ]
        controlsMapping.setColumnResizePolicy(TableView.CONSTRAINED_RESIZE_POLICY)
        /*
         *         firstNameCol.setMinWidth(100);
         *         firstNameCol.setCellValueFactory(
         *             new PropertyValueFactory<Person, String>("firstName"));
         *         firstNameCol.setCellFactory(TextFieldTableCell.forTableColumn());
         *         firstNameCol.setOnEditCommit(
         *             new EventHandler<CellEditEvent<Person, String>>() {
         *                 @Override
         *                 public void handle(CellEditEvent<Person, String> t) {
         *                     ((Person) t.getTableView().getItems().get(
         *                             t.getTablePosition().getRow())
         *                             ).setFirstName(t.getNewValue());
         *                 }
         *             }
         *         );
         */

    }

    @Inject
    @FinalFieldsConstructor
    new() {
    }

    static class TC extends TableCell<Command<?>, Collection<InputEvent>> {
        val InputTextureFinder inputTextureFinders
        val container = new HBox()

        new(InputTextureFinder inputTextureFinders) {
            container.setAlignment(Pos.CENTER)
            setGraphic(container)
            this.inputTextureFinders = inputTextureFinders
        }

        def protected ImageView newImageView(URL v) {
            var ImageView imageView = new ImageView(v.toExternalForm())
            // HACK
            imageView.setFitWidth(32)
            imageView.setPreserveRatio(true)
            return imageView
        }

        override protected void updateItem(Collection<InputEvent> item, boolean empty) {
            container.getChildren().clear()
            if (item !== null) {
                item.map[v|inputTextureFinders.findUrl(v)].forEach [ v |
                    val n = if(v == null) new Label("[?]") else newImageView(v)
                    container.getChildren().add(n)
                ]
            }
        }
    }
}