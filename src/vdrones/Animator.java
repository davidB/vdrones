package vdrones;

import java.util.HashMap;
import java.util.Map;

import rx.subjects.BehaviorSubject;
import rx.subjects.Subject;

import com.google.inject.Singleton;
import com.jme3.animation.AnimChannel;
import com.jme3.animation.AnimControl;
import com.jme3.animation.LoopMode;
import com.jme3.scene.Node;

@Singleton
public class Animator {
	public void play(Node n, String animName) {
		AnimControl ac = Spatials.findAnimControl(n);
		AnimChannel channel = ac.getChannel(0);
		channel.setAnim(animName);
		channel.setLoopMode(LoopMode.DontLoop);
		channel.setSpeed(1f);
	}

	public void playLoop(Node n, String animName) {
		AnimControl ac = Spatials.findAnimControl(n);
		AnimChannel channel = ac.getChannel(0);
		channel.setAnim(animName);
		channel.setLoopMode(LoopMode.Loop);
		channel.setSpeed(1f);
	}
}