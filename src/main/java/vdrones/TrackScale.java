package vdrones;

import java.io.IOException;
import java.util.function.Function;

import lombok.RequiredArgsConstructor;

import com.jme3.animation.AnimChannel;
import com.jme3.animation.AnimControl;
import com.jme3.animation.Track;
import com.jme3.export.JmeExporter;
import com.jme3.export.JmeImporter;
import com.jme3.math.FastMath;
import com.jme3.util.TempVars;

@RequiredArgsConstructor
public class TrackScale implements Track {
	final float length;
	final Function<Float, Float> ease;

	@Override
	public void write(JmeExporter ex) throws IOException {
		// TODO Auto-generated method stub

	}

	@Override
	public void read(JmeImporter im) throws IOException {
		// TODO Auto-generated method stub

	}

	@Override
	public void setTime(float time, float weight, AnimControl control, AnimChannel channel, TempVars vars) {
		float ratio = FastMath.clamp(time/length, 0.0f, 1.0f);
		ratio = ease.apply(ratio);
		control.getSpatial().setLocalScale(ratio);
	}

	@Override
	public float getLength() {
		return length;
	}

	@Override
	public Track clone() {
		return new TrackScale(length, ease);
	}

}
