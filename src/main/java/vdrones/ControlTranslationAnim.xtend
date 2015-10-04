package vdrones

import com.jme3.export.JmeExporter
import com.jme3.export.JmeImporter
import com.jme3.math.Vector3f
import com.jme3.renderer.RenderManager
import com.jme3.renderer.ViewPort
import com.jme3.scene.Spatial
import com.jme3.scene.control.AbstractControl
import com.jme3.scene.control.Control
import java.io.IOException

class ControlTranslationAnim extends AbstractControl {

    public var offset = new Vector3f()
    public var duration = 2000l
    public var boolean pingpong = true
    public var Vector3f position0 = null

    val tmp0 = new Vector3f();

    override setEnabled(boolean v) {
        super.setEnabled(v)
        if (!isEnabled() && position0 != null) {
            spatial.setLocalTranslation(position0)
            position0 = null
        }
    }

    override controlUpdate(float tpf) {
        if (position0 == null) {
            position0 = spatial.getLocalTranslation().clone()
        }
        var ratio = (System.currentTimeMillis() % duration) / (duration as float)
        if (pingpong) {
            ratio = Math.abs(ratio - 0.5f) * 2.0f
        }
        tmp0.set(offset).multLocal(ratio)
        spatial.getLocalRotation().multLocal(tmp0)
        tmp0.addLocal(position0)
        spatial.setLocalTranslation(tmp0)
    }

    override controlRender(RenderManager rm, ViewPort vp) {
    }

    override Control cloneForSpatial(Spatial spatial) {
        val control = new ControlTranslationAnim()
        control.setSpatial(spatial)
        control.duration = duration
        control.offset = offset
        control.pingpong = pingpong
        control.position0 = position0
        control
    }

    override read(JmeImporter im) throws IOException {
        super.read(im);
        val in = im.getCapsule(this)
        this.enabled = in.readBoolean("enabled", true)
        //this.duration = in.readLong("duration", 2000);
        this.offset = in.readSavable("offset", new Vector3f()) as Vector3f
        this.pingpong = in.readBoolean("pingpong", false)
        this.position0 = in.readSavable("position0", null as Vector3f) as Vector3f
    }

    override write(JmeExporter ex) throws IOException {
        super.write(ex)
        val out = ex.getCapsule(this)
        out.write(this.enabled, "enabled", true)
        out.write(this.duration, "duration", 2000)
        out.write(this.offset, "offset", new Vector3f())
        out.write(this.pingpong, "pingpong", false)
        if (this.position0 != null) out.write(this.position0, "position0", new Vector3f())
    }

}
