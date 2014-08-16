package vdrones;

import com.jme3.animation.AnimChannel;
import com.jme3.animation.AnimControl;
import com.jme3.animation.LoopMode;
import com.jme3.scene.Node;

public class Animator {

	public static void play(Node n, String animName) {
		AnimControl ac = Spatials.findAnimControl(n);
		AnimChannel channel = ac.getChannel(0);
		channel.setAnim(animName);
		channel.setLoopMode(LoopMode.DontLoop);
		channel.setSpeed(1f);
	}
	public static void playLoop(Node n, String animName) {
		AnimControl ac = Spatials.findAnimControl(n);
		AnimChannel channel = ac.getChannel(0);
		channel.setAnim(animName);
		channel.setLoopMode(LoopMode.Loop);
		channel.setSpeed(1f);
	}
}