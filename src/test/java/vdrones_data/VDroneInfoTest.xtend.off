package vdrones_data

import org.junit.Test
import org.junit.Assert

class VDroneInfoTest {
	@Test
	def load_save_withoutException() {
		val sut = new VDroneInfoService()
		val vi = sut.get()
		sut.save()
		Assert.assertEquals(vi, sut.get())
		Assert.assertEquals(VDroneInfoExt.Profile0Name, vi.profileActive)
		Assert.assertEquals(1, vi.profilesList.size)
		Assert.assertEquals(0, vi.itemsList.size)
		Assert.assertEquals(0, vi.runsList.size)
	}
}