package vdrones_data

import com.jme3.export.JmeExporter
import com.jme3.export.JmeImporter
import com.jme3.export.Savable
import io.protostuff.LinkedBuffer
import io.protostuff.ProtobufIOUtil
import java.io.IOException
import jme3tools.savegame.SaveGame

class VDroneInfoService {
	val Envelope envelope

	new() {
		val v = SaveGame.loadGame("vdrones/data", "VDroneInfo") as Envelope
		envelope = if (v == null) new Envelope().reset() else v
	}

	def VDroneInfo get() {
		envelope.data
	}

	def save() {
		SaveGame.saveGame("vdrones", "VDroneInfo", envelope)
	}

	def VDroneInfo reset() {
		envelope.reset()
		envelope.data
	}


	private static class Envelope implements Savable {
		val buffer = LinkedBuffer.allocate(512)
		var VDroneInfo data

		def reset() {
			this.data = VDroneInfoExt.newVDroneInfo()
			this
		}

		override read(JmeImporter im) throws IOException {
			val ic = im.getCapsule(this)
			val b = ic.readByteArray("data", null)
			data = if (b == null) {
				VDroneInfoExt.newVDroneInfo()
			} else {
				val d = new VDroneInfo()
				ProtobufIOUtil.mergeFrom(b, d, VDroneInfo.getSchema())
				d
			}
		}

		override write(JmeExporter ex) throws IOException {
			try {
				val b = ProtobufIOUtil.toByteArray(data, VDroneInfo.getSchema(), buffer)
				val oc = ex.getCapsule(this)
				oc.write(b, "data", null)
			} finally{
				buffer.clear()
			}
		}
	}
}