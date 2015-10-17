package vdrones

import com.jme3.input.controls.ActionListener
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

class DroneInput implements ActionListener{
	////////////////////////////////////////////////////////////////////////////
	// CLASS
	////////////////////////////////////////////////////////////////////////////
	static final package String LEFT="Left"
	static final package String RIGHT="Right"
	static final package String FORWARD="Forward"
	static final package String BACKWARD="Backward"
	////////////////////////////////////////////////////////////////////////////
	// Object
	////////////////////////////////////////////////////////////////////////////
	val InfoDrone drone
	
	override void onAction(String binding, boolean value, float tpf) {
		
		switch (binding) {
			case LEFT:{
				drone.turnReq.onNext(if ((value)) 1.0f else 0.0f )
			}
			case RIGHT:{
				drone.turnReq.onNext(if ((value)) -1.0f else 0.0f )
			}
			case FORWARD:{
				drone.forwardReq.onNext(if ((value)) 1f else 0f )
			}
			case BACKWARD:{
				drone.forwardReq.onNext(if ((value)) -1f else 0f )
			}
		}
	}
	
	@FinalFieldsConstructor
	new(){}
}