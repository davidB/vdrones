/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package vdrones;

import com.jme3.app.Application;
import com.jme3.app.state.AppStateManager;
import com.jme3.input.InputManager;
import com.jme3.input.KeyInput;
import com.jme3.input.controls.ActionListener;
import com.jme3.input.controls.KeyTrigger;
import com.simsilica.es.Entity;
import com.simsilica.es.EntityComponent;
import com.simsilica.es.EntityData;
import com.simsilica.es.EntityId;
import com.simsilica.es.EntitySet;

class CDroneInput implements EntityComponent {
}

class DroneInput implements ActionListener {
    ////////////////////////////////////////////////////////////////////////////
    // CLASS
    ////////////////////////////////////////////////////////////////////////////

    static final String LEFT = "Left";
    static final String RIGHT = "Right";
    static final String FORWARD = "Forward";
    static final String BACKWARD = "Backward";

    static void bind(InputManager inputManager, DroneInput ctrl) {
        inputManager.addMapping(LEFT, new KeyTrigger(KeyInput.KEY_H));
        inputManager.addMapping(RIGHT, new KeyTrigger(KeyInput.KEY_K));
        inputManager.addMapping(FORWARD, new KeyTrigger(KeyInput.KEY_U));
        inputManager.addMapping(BACKWARD, new KeyTrigger(KeyInput.KEY_J));
        //inputManager.addMapping(RESET, new KeyTrigger(KeyInput.KEY_RETURN));
        inputManager.addListener(ctrl, LEFT, RIGHT, FORWARD, BACKWARD);
    }

    static void unbind(InputManager inputManager, DroneInput ctrl) {
        inputManager.removeListener(ctrl);
    }
    ////////////////////////////////////////////////////////////////////////////
    // Object
    ////////////////////////////////////////////////////////////////////////////
    private EntitySet droneSet;

    DroneInput(EntityData ed) {
        droneSet = ed.getEntities(CDroneInfo.class, CDroneInput.class);
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
        e.set(info);
    }
}
