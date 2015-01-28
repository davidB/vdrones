package vdrones;

import java.io.IOException;

import lombok.RequiredArgsConstructor;

import com.jme3.animation.AnimChannel;
import com.jme3.animation.AnimControl;
import com.jme3.animation.Track;
import com.jme3.export.JmeExporter;
import com.jme3.export.JmeImporter;
import com.jme3.util.TempVars;

@RequiredArgsConstructor
public class TrackScale implements Track {
	final float length;
	final boolean toZero;

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
		float ratio = Math.min(1.0f, Math.max(0.0f, time / length));
		ratio = toZero ? (1.0f - ratio): ratio;
		control.getSpatial().setLocalScale(ratio);
	}

	@Override
	public float getLength() {
		return length;
	}

	@Override
	public Track clone() {
		return new TrackScale(length, toZero);
	}

}
