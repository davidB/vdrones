package vdrones;

import javax.inject.Inject;
import javax.inject.Singleton;

import lombok.RequiredArgsConstructor;

import com.jme3.animation.AnimChannel;
import com.jme3.animation.AnimControl;
import com.jme3.animation.LoopMode;
import com.jme3.scene.Node;
// Animator should be able to run animations on 3D, 2D/HUD/GUI, Sound
// Animation's run can have some parameters/cfg (idea : split animation's run creation + registration and execution)
// Animation could be chained (eg : xxx.then(...))
// Animator should handle cinematic
// Animation can spawn detached spatials,...
@Singleton
@RequiredArgsConstructor(onConstructor=@__(@Inject))
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