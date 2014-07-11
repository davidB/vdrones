package vdrones;

import lombok.NonNull;
import lombok.RequiredArgsConstructor;

import com.jme3.input.controls.ActionListener;

@RequiredArgsConstructor
class DroneInput implements ActionListener {
    ////////////////////////////////////////////////////////////////////////////
    // CLASS
    ////////////////////////////////////////////////////////////////////////////

    static final String LEFT = "Left";
    static final String RIGHT = "Right";
    static final String FORWARD = "Forward";
    static final String BACKWARD = "Backward";
    static final String TOGGLE_CAMERA = "toggle_camera";

    ////////////////////////////////////////////////////////////////////////////
    // Object
    ////////////////////////////////////////////////////////////////////////////

    @NonNull
    private final DroneInfo2 drone;

    @Override
    public void onAction(String binding, boolean value, float tpf) {
        switch (binding) {
            case LEFT:
                drone.turnReq.onNext((value) ? 1.0f : 0.0f);
                break;
            case RIGHT:
                drone.turnReq.onNext((value) ? -1.0f : 0.0f);
                break;
            case FORWARD:
            	drone.forwardReq.onNext((value) ? 1f : 0f);
                break;
            case BACKWARD:
            	drone.forwardReq.onNext((value) ? -1f : 0f);
                break;
        }
    }
}

