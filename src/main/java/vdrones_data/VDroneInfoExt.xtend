package vdrones_data

import java.util.LinkedList
import static extension vdrones_data.ItemsExt.*

/**
 * Functions to interact with VDroneInfo and its content.
 * The can be used as Extension via Xtend, or as static methods
 */
class VDroneInfoExt {
	public static val Profile0Name = "default"

	static def VDroneInfo newVDroneInfo() {
		val vdi = new VDroneInfo()
		vdi.vdronerName = "noname"
		vdi.itemsList = new LinkedList<Item>()
		vdi.runsList = new LinkedList<RunReport>()
		vdi.profilesList = new LinkedList<Profile>()
		val p = vdi.newProfile(Profile0Name)
		vdi.profileActive = p.name
		vdi
	}

	/**
	 * The max profile is not store "as is", it's computed from the base profile + items applied
	 */
	static def Profile maxProfile(VDroneInfo v) {
		val p = new Profile()
		p.name = "__max__"
		v.itemsList.forEach[item|
			val entry = Items.valueOf(item.name)
			entry.on(p, item.qty)
		]
		p
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

	static def int cubeTotal(VDroneInfo v) {
		v.cubeGain() - v.cubeSpend()
	}

	static def int cubeMaxOfArea(VDroneInfo v, String areaName) {
		v.runsList.filter[it.areaName == areaName].fold(0)[acc, x |  Math.max(acc, x.cubeCount)]
	}

	static def int cubeGain(VDroneInfo v) {
		v.runsList.groupBy[it.areaName].values.fold(0)[acc, x |  acc + x.fold(0)[acc2, x2| Math.max(acc2, x2.cubeCount)]]
	}

	static def int cubeSpend(VDroneInfo v) {
		v.itemsList.fold(0)[acc, x |  acc + x.price * x.qty]
	}

}