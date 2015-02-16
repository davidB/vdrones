package vdrones_data

import java.util.LinkedList

/**
 * Functions to interact with VDroneInfo and its content.
 * The can be used as Extension via Xtend, or as static methods
 */
class VDroneInfoExt {
	public static val ProfileMaxName = "__max__"

	static def VDroneInfo newVDroneInfo() {
		val vdi = new VDroneInfo()
		vdi.vdronerName = "noname"
		vdi.itemsList = new LinkedList<Item>()
		vdi.runsList = new LinkedList<RunReport>()
		vdi.profilesList = new LinkedList<Profile>()
		val p = vdi.newProfile(ProfileMaxName)
		vdi.profileActive = p.name
		vdi
	}

	static def Profile activeProfile(VDroneInfo v) {
		val name = v.profileActive
		if (name == null) {
			v.profilesList.get(0)
		}else {
			v.profilesList.findFirst[it.name.equals(name)]
		}
	}

	static def Profile newProfile(VDroneInfo v, String name) {
		val p = new Profile()
		p.name = name
		p.lastModification = System.currentTimeMillis
		v.profilesList.add(p)
		p
	}
}