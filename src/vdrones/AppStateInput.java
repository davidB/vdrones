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
import com.simsilica.es.Entity;
import com.simsilica.es.EntityComponent;
import com.simsilica.es.EntityData;
import com.simsilica.es.EntitySet;
import vdrones.CCameraFollower.Mode;
import static vdrones.DroneInput.LEFT;

class CDroneInput implements EntityComponent {
}

public class AppStateInput extends AbstractAppState {

    DroneInput droneInput;
    InputManager inputManager;

    @Override
    public void initialize(AppStateManager stateManager, Application app) {
        super.initialize(stateManager, app);
        EntityData ed = ((Main) app).entityData;
        droneInput = new DroneInput(ed);
        inputManager = app.getInputManager();
        DroneInput.bind(inputManager, droneInput);
    }

    @Override
    public void cleanup() {
        DroneInput.unbind(inputManager, droneInput);
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
    private EntitySet droneSet;

    DroneInput(EntityData ed) {
        droneSet = ed.getEntities(CDroneInfo.class, CDroneInput.class, CCameraFollower.class);
    }

    @Override
    public void onAction(String binding, boolean value, float tpf) {
        droneSet.applyChanges();
        if (droneSet.isEmpty()) {
            System.out.println("no drone to drive");
            return;
        }
        Entity e = droneSet.iterator().next();
        CDroneInfo info = e.get(CDroneInfo.class).copy();
        switch (binding) {
            case LEFT:
                info.turn = (value) ? 1 : 0;
                e.set(info);
                break;
            case RIGHT:
                info.turn = (value) ? -1 : 0;
                e.set(info);
                break;
            case FORWARD:
                info.forward = (value) ? 1 : 0;
                e.set(info);
                break;
            case BACKWARD:
                info.forward = (value) ? -1 : 0;
                e.set(info);
                break;
            case TOGGLE_CAMERA:
                if (value) {
                    CCameraFollower f = e.get(CCameraFollower.class);
                    e.set(new CCameraFollower((f.mode == Mode.TPS) ? Mode.TOP : Mode.TPS));
                }
        }
    }
}
