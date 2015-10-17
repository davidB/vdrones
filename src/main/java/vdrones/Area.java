package vdrones;

public enum Area {
	//A00(true, null, 360),
	//A01(true, null, 360),
	B00(true, null, 25),
	B01(true, null, 90),
	B02(false, null, 120),
	B04(false, null, 120),
	T01(false, null, 90)
	;
	public final boolean enable;
	public final String music;
	public final float time;
	
	Area(boolean enable, String music, float time) {
		this.enable = enable;
		this.music = music;
		this.time = time;
	}
}