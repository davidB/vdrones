package vdrones

import java.io.IOException
import org.eclipse.xtext.xbase.lib.Functions.Function1
import com.jme3.animation.AnimChannel
import com.jme3.animation.AnimControl
import com.jme3.animation.Track
import com.jme3.export.JmeExporter
import com.jme3.export.JmeImporter
import com.jme3.math.FastMath
import com.jme3.util.TempVars
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

class TrackScale implements Track {
	final package float length
	final package Function1<Float, Float> ease

	override void write(JmeExporter ex) throws IOException {
		// TODO Auto-generated method stub
	}

	override void read(JmeImporter im) throws IOException {
		// TODO Auto-generated method stub
	}

	override void setTime(float time, float weight, AnimControl control, AnimChannel channel, TempVars vars) {
		var float ratio = FastMath.clamp(time / length, 0.0f, 1.0f)
		ratio = ease.apply(ratio)
		control.getSpatial().setLocalScale(ratio)
	}

	override float getLength() {
		return length
	}

	override Track clone() {
		return new TrackScale(length, ease)
	}

	@FinalFieldsConstructor
	new(){}
	
	override getKeyFrameTimes() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
}
