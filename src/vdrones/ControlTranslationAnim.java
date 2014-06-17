package vdrones;

import com.jme3.export.InputCapsule;
import com.jme3.export.JmeExporter;
import com.jme3.export.JmeImporter;
import com.jme3.export.OutputCapsule;
import com.jme3.math.Vector3f;
import com.jme3.renderer.RenderManager;
import com.jme3.renderer.ViewPort;
import com.jme3.scene.Spatial;
import com.jme3.scene.control.AbstractControl;
import com.jme3.scene.control.Control;
import java.io.IOException;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

@ToString
public class ControlTranslationAnim extends AbstractControl {

    @Getter @Setter Vector3f offset = new Vector3f();
    @Getter @Setter long duration = 2000;
    @Getter @Setter boolean pingpong = true;
    @Getter @Setter Vector3f position0;
    
    private final Vector3f tmp0 = new Vector3f();

    @Override
    public void setEnabled(boolean v) {
        super.setEnabled(v);
        if (!isEnabled() && position0 != null) {
            spatial.setLocalTranslation(position0);
            position0 = null;
        }
    }
    
    @Override
    protected void controlUpdate(float tpf) {
        if (position0 == null) {
            position0 = spatial.getLocalTranslation().clone();
        }
        float ratio = (System.currentTimeMillis() % duration) / ((float) duration);
        if (pingpong) {
            ratio = Math.abs(ratio - 0.5f) * 2.0f;
        }
        tmp0.set(offset).multLocal(ratio);
        spatial.getLocalRotation().multLocal(tmp0);
        tmp0.addLocal(position0);
        spatial.setLocalTranslation(tmp0);
        //System.out.println("ratio : " + ratio + " .. " + spatial.getLocalTranslation() + ".." + spatial.getName());
    }

    @Override
    protected void controlRender(RenderManager rm, ViewPort vp) {
    }

    @Override
    public Control cloneForSpatial(Spatial spatial) {
        ControlTranslationAnim control = new ControlTranslationAnim();
        control.setSpatial(spatial);
        control.duration = duration;
        control.offset = offset;
        control.pingpong = pingpong;
        control.position0 = position0;
        return control;
    }

    @Override
    public void read(JmeImporter im) throws IOException {
        super.read(im);
        InputCapsule in = im.getCapsule(this);
        this.enabled = in.readBoolean("enabled", true);
        //this.duration = in.readLong("duration", 2000);
        this.offset = (Vector3f) in.readSavable("offset", new Vector3f());
        this.pingpong = in.readBoolean("pingpong", false);
        this.position0 = (Vector3f) in.readSavable("position0", (Vector3f)null);
    }

    @Override
    public void write(JmeExporter ex) throws IOException {
        super.write(ex);
        OutputCapsule out = ex.getCapsule(this);
        out.write(this.enabled, "enabled", true);
        out.write(this.duration, "duration", 2000);
        out.write(this.offset, "offset", new Vector3f());
        out.write(this.pingpong, "pingpong", false);
        if (this.position0 != null) out.write(this.position0, "position0", new Vector3f());
    }

}
