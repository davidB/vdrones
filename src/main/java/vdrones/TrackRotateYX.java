package vdrones;

import java.io.IOException;

import com.jme3.animation.AnimChannel;
import com.jme3.animation.AnimControl;
import com.jme3.animation.Track;
import com.jme3.export.JmeExporter;
import com.jme3.export.JmeImporter;
import com.jme3.math.Quaternion;
import com.jme3.util.TempVars;

public class TrackRotateYX implements Track {
	private final float length;
	private Quaternion qxp = new Quaternion(1.0f, 0.0f, 0.0f, 1.0f).normalizeLocal();
	private Quaternion qxn = new Quaternion(1.0f, 0.0f, 0.0f, -1.0f).normalizeLocal();
	private Quaternion qyp = new Quaternion(0.0f, 1.0f, 0.0f, 1.0f).normalizeLocal();
	private Quaternion qyn = new Quaternion(0.0f, 1.0f, 0.0f, -1.0f).normalizeLocal();
	private Quaternion q = new Quaternion();
	private Quaternion qy = new Quaternion();

	public TrackRotateYX(float length) {
		this.length = length;
	}

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
		float ratio = time / length;
		ratio = ratio - (float)Math.floor(ratio);
		qy.slerp(qyn, qyp, ratio);
		q.slerp(qxn, qxp, ratio*2);
		q.multLocal(qy).normalizeLocal();
		control.getSpatial().setLocalRotation(q);
	}

	@Override
	public float getLength() {
		return length;
	}

	@Override
	public Track clone() {
		return new TrackRotateYX(length);
	}

	@Override
	public float[] getKeyFrameTimes() {
		// TODO Auto-generated method stub
		return null;
	}

}
