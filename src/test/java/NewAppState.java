/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */



import lombok.extern.slf4j.Slf4j;

import com.jme3.app.Application;
import com.jme3.app.SimpleApplication;
import com.jme3.app.state.AbstractAppState;
import com.jme3.app.state.AppStateManager;
import com.jme3.scene.Geometry;
import com.jme3.scene.Mesh;
import com.jme3.scene.Node;
import com.jme3.scene.SceneGraphVisitor;
import com.jme3.scene.Spatial;
import com.jme3.scene.shape.Box;
import com.jme3.scene.shape.Sphere;

/**
 *
 * @author dwayne
 */
public class NewAppState extends AbstractAppState {
    Node rootNode;

    SceneGraphVisitor visitor = new SceneGraphVisitorDemo();

    @Override
    public void initialize(AppStateManager stateManager, Application app) {
        super.initialize(stateManager, app);
        rootNode = ((SimpleApplication) app).getRootNode();
        rootNode.depthFirstTraversal(visitor);
    }

    @Override
    public void setEnabled(boolean v) {
        if (v) {
            rootNode.depthFirstTraversal(visitor);
        }
        super.setEnabled(v);
    }

    @Override
    public void update(float tpf) {
    }

    @Override
    public void cleanup() {
        super.cleanup();
        //TODO: clean up what you initialized in the initialize method,
        //e.g. remove all spatials from rootNode
        //this is called on the OpenGL thread after the AppState has been detached
    }
}

@Slf4j
class SceneGraphVisitorDemo implements SceneGraphVisitor {

    @Override
    public void visit(Spatial spatial) {
        if (spatial instanceof Geometry) {
            Mesh mesh = ((Geometry) spatial).getMesh();
            if (mesh instanceof Box) visit(spatial, (Box) mesh);
            else if (mesh instanceof Sphere) visit(spatial, (Sphere) mesh);
        }
    }

    public void visit(Spatial spatial, Box shape) {
        log.info("%{} as box x({}), y({}), z({})", spatial.getName(), shape.getXExtent(), shape.getYExtent(), shape.getZExtent());
    }

    public void visit(Spatial spatial, Sphere shape) {
        log.info(spatial.getName() + " as sphere : " + shape.getZSamples() + "," + shape.getRadialSamples() +  "," + shape.getRadius());
    }
}
