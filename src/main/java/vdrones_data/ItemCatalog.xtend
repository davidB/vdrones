package vdrones_data

enum Items {
	baseKit
}

class ItemsExt {
	static def on(Items i, Profile p, int qty) {
		switch(i) {
			case baseKit : {
				p.propulsionForward = p.propulsionForward + 150.0f
				p.rotationSpeed = p.rotationSpeed + 2.0f
				p.linearDamping = p.linearDamping + 0.5f
				p.energyProvider = p.energyProvider + 2f
				p.energyPropulsion = p.energyPropulsion + 4
			/*
	public float energyForwardSpeed = 4;
	public float energyShieldSpeed = 2;
	public float energyStoreInit = 50f;
	public float energyStoreMax = 100f;
	public float healthMax = 100f;
	public float wallCollisionHealthSpeed = -100.0f / 5.0f; //-100 points in 5 seconds,
	public float attractorRadius = 3.5f;//6.5f;
	public float attractorPower = 1.0f;
	public float grabRadius = 3.0f;
	public float exitRadius = 1.5f;
*/

			}

		}
	}
}