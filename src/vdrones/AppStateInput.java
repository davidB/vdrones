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
import com.jme3.input.controls.ActionListener;
import com.jme3.input.controls.KeyTrigger;
import static vdrones.DroneInput.LEFT;

public class AppStateInput extends AbstractAppState {

    final DroneInput droneInput = new DroneInput();
    InputManager inputManager;

    @Override
    public void initialize(AppStateManager stateManager, Application app) {
        super.initialize(stateManager, app);
        inputManager = app.getInputManager();
        setEnabled(true);
    }

    void setDroneInfo(CDroneInfo v) {
        droneInput.info = v;
    }

    @Override
    public void setEnabled(boolean enabled) {
        super.setEnabled(enabled); //To change body of generated methods, choose Tools | Templates.
        if (enabled) {
            DroneInput.bind(inputManager, droneInput);
        } else {
            DroneInput.unbind(inputManager, droneInput);
        }
    }

    @Override
    public void cleanup() {
        setEnabled(false);
        inputManager = null;
        super.cleanup();
    }
}

class DroneInput implements ActionListener {
    ////////////////////////////////////////////////////////////////////////////
    // CLASS
    ////////////////////////////////////////////////////////////////////////////

    static final String LEFT = "Left";
    static final String RIGHT = "Right";
    static final String FORWARD = "Forward";
    static final String BACKWARD = "Backward";
    static final String TOGGLE_CAMERA = "toggle_camera";

    static void bind(InputManager inputManager, DroneInput ctrl) {
        inputManager.addMapping(LEFT, new KeyTrigger(KeyInput.KEY_H));
        inputManager.addMapping(RIGHT, new KeyTrigger(KeyInput.KEY_K));
        inputManager.addMapping(FORWARD, new KeyTrigger(KeyInput.KEY_U));
        inputManager.addMapping(BACKWARD, new KeyTrigger(KeyInput.KEY_J));
        inputManager.addMapping(TOGGLE_CAMERA, new KeyTrigger(KeyInput.KEY_M));
        //inputManager.addMapping(RESET, new KeyTrigger(KeyInput.KEY_RETURN));
        inputManager.addListener(ctrl, LEFT, RIGHT, FORWARD, BACKWARD, TOGGLE_CAMERA);
    }

    static void unbind(InputManager inputManager, DroneInput ctrl) {
        inputManager.removeListener(ctrl);
    }
    ////////////////////////////////////////////////////////////////////////////
    // Object
    ////////////////////////////////////////////////////////////////////////////
    public CDroneInfo info;

    @Override
    public void onAction(String binding, boolean value, float tpf) {
        if (info == null) {
            return;
        }
        switch (binding) {
            case LEFT:
                info.turn = (value) ? 1 : 0;
                break;
            case RIGHT:
                info.turn = (value) ? -1 : 0;
                break;
            case FORWARD:
                info.forward = (value) ? 1 : 0;
                break;
            case BACKWARD:
                info.forward = (value) ? -1 : 0;
                break;
        }
    }
}
