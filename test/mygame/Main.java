package mygame;

import com.jme3.app.SimpleApplication;
import com.jme3.bullet.BulletAppState;
import com.jme3.bullet.control.BetterCharacterControl;
import com.jme3.bullet.control.RigidBodyControl;
import com.jme3.input.ChaseCamera;
import com.jme3.input.KeyInput;
import com.jme3.input.controls.ActionListener;
import com.jme3.input.controls.KeyTrigger;
import com.jme3.light.AmbientLight;
import com.jme3.light.DirectionalLight;
import com.jme3.material.Material;
import com.jme3.math.ColorRGBA;
import com.jme3.math.FastMath;
import com.jme3.math.Plane;
import com.jme3.math.Vector3f;
import com.jme3.renderer.RenderManager;
import com.jme3.scene.Geometry;
import com.jme3.scene.Node;
import com.jme3.scene.Spatial;
import com.jme3.scene.shape.Box;

public class Main extends SimpleApplication implements ActionListener {

    public static void main(String[] args) {
        Main app = new Main();
        app.start();
    }

    private BulletAppState bulletAppState;
    private Spatial gameLevel;
    private Spatial player;
    private BetterCharacterControl playerControl;
    private ChaseCamera chaseCam;
    private boolean left,right, up, down;

    private Vector3f walkDirection = new Vector3f(0,0,0);
    private Vector3f viewDirection = new Vector3f(0,0,0);
    //private float airTime = 0;

    Node playerNode;

    @Override
    public void simpleInitApp() {

    bulletAppState = new BulletAppState();
    stateManager.attach(bulletAppState);

    flyCam.setEnabled(false);
    mouseInput.setCursorVisible(false);

    initSunLight();
    initAmbientLight();
    initScene();
    initPlayer();
    initPlayerPhysics();
    initChaseCam();
    initControls();

    }

    @Override
    public void simpleUpdate(float tpf) {
		walkDirection.set(0,0,0);
		float speed = 5.0f;
		if (up) walkDirection.addLocal(speed, 0f, 0f);
		if (down) walkDirection.addLocal(- speed, 0f, 0f);
		// change to World (only apply rotation)
		player.getWorldRotation().multLocal(walkDirection);
		playerControl.setWalkDirection(walkDirection);

		if (left || right) {
			viewDirection.set(playerControl.getViewDirection());
			player.getWorldRotation().inverse().multLocal(viewDirection);
			if (left) viewDirection.addLocal(0.1f, 0f, 0f);
			if (right) viewDirection.addLocal(-0.1f, 0f, 0f);
			viewDirection.normalizeLocal();
			player.getWorldRotation().multLocal(viewDirection);
			playerControl.setViewDirection(viewDirection);
		}
    }

    @Override
    public void simpleRender(RenderManager rm) {

    }

    private void initSunLight(){

    DirectionalLight sun = new DirectionalLight();
    sun.setDirection((new Vector3f(-0.5f, -0.5f, -0.5f)).normalizeLocal());
    sun.setColor(ColorRGBA.White);
    rootNode.addLight(sun);
    }

    private void initAmbientLight(){
         /** A white ambient light source. */
    AmbientLight ambient = new AmbientLight();
    ambient.setColor(ColorRGBA.White.mult(1.3f));
    rootNode.addLight(ambient);
    }

    private void initScene(){
        //gameLevel = assetManager.loadModel("Scenes/Scene.j3o");
        Box box = new Box(10, 1, 10);
        gameLevel = new Geometry("Plane", box);
        Material mat = new Material(assetManager, "Common/MatDefs/Misc/Unshaded.j3md");
        mat.setColor("Color", ColorRGBA.Blue);
        gameLevel.setMaterial(mat);

        gameLevel.setLocalTranslation(0, -2, 0);
        gameLevel.addControl(new RigidBodyControl(0f));
        // 0 stands for the weight of the object (how fast it falls to the ground)
        rootNode.attachChild(gameLevel);
        bulletAppState.getPhysicsSpace().addAll(gameLevel);
    }

    private void initPlayer(){
    Box playerBox = new Box(3, 1, 2);
    player = new Geometry("Player", playerBox);
    Material mat = new Material(assetManager, "Common/MatDefs/Misc/Unshaded.j3md");
    mat.setColor("Color", ColorRGBA.Orange);
    player.setMaterial(mat);
    //create player
    //player = assetManager.loadModel("Models/turtlefinished_80_textured/turtlefinished_80_textured.j3o");
    //player.scale(1f);
    //player.rotate(0, FastMath.PI / 2 , 0);
    player.setLocalTranslation(0, 2, 0);

    playerNode = new Node();
    playerNode.attachChild(player);

    }

    private void initPlayerPhysics(){
      //Create Controls
    playerControl = new BetterCharacterControl(0.26f, 0.5f, 20f); //contruct character collsion shape and weight
    playerNode.addControl(playerControl); //attach Control to playerNode crated above
            playerControl.setJumpForce(new Vector3f(0, 5f, 0));
            playerControl.setGravity(new Vector3f(0, 10f, 0));
    playerControl.warp(new Vector3f(0, 10, 10));
            bulletAppState.getPhysicsSpace().add(playerControl);
            bulletAppState.getPhysicsSpace().addAll(playerNode);
     rootNode.attachChild(playerNode);
    }

    private void initChaseCam(){
    chaseCam = new ChaseCamera(cam, playerNode, inputManager);
    chaseCam.setSmoothMotion(true);
    chaseCam.setTrailingEnabled(true);
    chaseCam.setMinDistance(10f);
    }

    private void initControls(){
     inputManager.addMapping("CharLeft", new KeyTrigger(KeyInput.KEY_H));
     inputManager.addMapping("CharRight", new KeyTrigger(KeyInput.KEY_K));
     inputManager.addMapping("CharForward", new KeyTrigger(KeyInput.KEY_U));
     inputManager.addMapping("CharBackward", new KeyTrigger(KeyInput.KEY_J));
     inputManager.addListener(this, "CharLeft", "CharRight");
     inputManager.addListener(this, "CharForward", "CharBackward");

    }

    public void onAction(String name, boolean isPressed, float tpf) {
       if (name.equals("CharLeft")) {
            left = isPressed;

        } else if (name.equals("CharRight")) {
            right = isPressed;

        } else if (name.equals("CharForward")) {
            up = isPressed;

        } else if (name.equals("CharBackward")) {
            down = isPressed;

        }
    }

}