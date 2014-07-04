package vdrones;

import lombok.extern.slf4j.Slf4j;

import com.jme3.app.SimpleApplication;
import com.jme3.scene.Node;
import com.jme3.scene.Spatial;

/**
 *
 * @author dwayne
 */
@Slf4j
public class AppStateLevelLoader extends AppState0 {
    private LevelLoader lloader;

    @Override
    protected void enable() {
        SimpleApplication sapp = injector.getInstance(SimpleApplication.class);
        EntityFactory factory = injector.getInstance(EntityFactory.class);
        lloader = injector.getInstance(LevelLoader.class);
        Node rootNode = sapp.getRootNode();
        Spatial scene = rootNode.getChild("scene");
        log.info(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> {}", rootNode.getQuantity());
        for(Spatial s : rootNode.getChildren()) {
            log.info("child {} / {}", s.getName(), s);
        }
        try {
            if (scene != null) {
                lloader.loadLevel(factory.newLevel(scene), false);
            }
        } catch(Exception exc) {
            exc.printStackTrace();
        }
    }

    @Override
    public void disable() {
    	lloader.unloadLevel();
    }
}

