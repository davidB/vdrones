/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package vdrones;

import com.jme3.app.Application;
import com.jme3.app.state.AbstractAppState;
import com.jme3.app.state.AppStateManager;
import com.jme3.input.InputManager;
import com.jme3.input.KeyInput;
import com.jme3.input.controls.KeyTrigger;
import com.simsilica.es.EntityData;
import static vdrones.DroneInput.LEFT;

public class AppStateInput extends AbstractAppState {

    DroneInput droneInput;

    @Override
    public void initialize(AppStateManager stateManager, Application app) {
        EntityData ed = ((Main) app).entityData;
        DroneInput.bind(app.getInputManager(), new DroneInput(ed));
    }
}
