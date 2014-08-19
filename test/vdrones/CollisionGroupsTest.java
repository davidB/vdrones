package vdrones;

import static org.junit.Assert.*;

import org.junit.Test;

import com.jme3.scene.Node;


public class CollisionGroupsTest {

	@Test
	public void test() {
		Node n = new Node("toto");
		CollisionGroups.setRecursive(n, CollisionGroups.CUBE, CollisionGroups.DRONE);
		assertTrue(CollisionGroups.test(n, CollisionGroups.CUBE));
		assertFalse(CollisionGroups.test(n, CollisionGroups.DRONE));
		assertFalse(CollisionGroups.test(n, CollisionGroups.NONE));
		assertFalse(CollisionGroups.test(n, CollisionGroups.WALL));
	}

}
