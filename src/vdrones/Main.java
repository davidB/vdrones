package vdrones;

import com.jme3.app.DebugKeysAppState;
import com.jme3.app.FlyCamAppState;
import com.jme3.app.SimpleApplication;
import com.jme3.app.StatsAppState;
import com.jme3.app.state.ScreenshotAppState;
import com.jme3.bullet.BulletAppState;
import com.jme3.math.ColorRGBA;
import com.jme3.renderer.RenderManager;
import com.jme3.scene.Spatial;

/**
 * test
 */
public class Main extends SimpleApplication {
    private static boolean assertionsEnabled;
    private static boolean enabled() {
        Main.assertionsEnabled = true;
        return true;
    }
    
    public static void main(final String[] args) {
        assert Main.enabled();
        if (!Main.assertionsEnabled) {
            throw new RuntimeException("Assertions must be enabled (vm args -ea");
        }
        Main app = new Main();
        app.start();
    }
    
    private boolean spawned = false;

    public Main() {
    }

    @Override
    public void simpleInitApp() {
        //setDisplayStatView(true);
        //setDisplayFps(true);
        //flyCam.setEnabled(false);
        
        stateManager.detach(stateManager.getState(FlyCamAppState.class));
        stateManager.attach(new StatsAppState());
        stateManager.attach(new DebugKeysAppState());
        stateManager.attach(new ScreenshotAppState("", System.currentTimeMillis()));
        stateManager.attach(new BulletAppState());
        //stateManager.attach(new AppStatePostProcessing());
        stateManager.attach(new AppStateShadow());
        stateManager.attach(new AppStateCamera());
        stateManager.attach(new AppStateInput());
        stateManager.attach(new AppStateDrone());
        stateManager.attach(new AppStateGeoPhy());
        stateManager.attach(new AppStateLevelLoader());
        stateManager.attach(new AppStateHudInGame());
        spawned = false;
        setDebug(false);
    }

    @Override
    public void simpleUpdate(float tpf) {
        if (!spawned) {
            spawned = true;
            EntityFactory efactory = Injectors.find(this).getInstance(EntityFactory.class);

            stateManager.getState(AppStateLevelLoader.class).loadLevel(efactory.newLevel("area0"), true);
            
            //Spatial vd = VDrone.newDrone(assetManager);
            Spatial vd = efactory.newDrone();
            CDroneInfo info = new CDroneInfo();
            vd.setUserData(CDroneInfo.K, info);
            stateManager.getState(AppStateInput.class).setDroneInfo(info);
            stateManager.getState(AppStateDrone.class).entity = vd;
            stateManager.getState(AppStateCamera.class).target = vd;
            stateManager.getState(AppStateCamera.class).follower = new CameraFollower(CameraFollower.Mode.TPS);
            stateManager.getState(AppStateGeoPhy.class).toAdd.offer(vd);
        }
    }

    @Override
    public void simpleRender(RenderManager rm) {
        //TODO: add render code
    }

    void setDebug(boolean v) {
        stateManager.getState(BulletAppState.class).setDebugEnabled(v);
        inputManager.setCursorVisible(v);
        viewPort.setBackgroundColor(v? ColorRGBA.Pink : ColorRGBA.White);
    }
 }
