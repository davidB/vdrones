package vdrones;

import static java.lang.Math.*;
//import static com.jme3.math.FastMath.*;

import java.util.function.Function;

public class Ease {
	public static float identity(float ratio) {
		return ratio;
	}

	public static float inverse(float ratio) {
		return 1.0f - ratio;
	}

	public static Function<Float, Float> compose(Function<Float, Float> op1, Function<Float, Float> op2) {
		return (v) -> { return op2.apply(op1.apply(v)); };
	}

	public static float outElastic(float ratio) {
		return (float)((ratio == 0.0 || ratio == 1.0) ? ratio
				: pow(2.0, - 10.0 * ratio) * sin((ratio - 0.3 / 4.0) * (2.0 * PI) / 0.3) + 1);
	}

	public static float inBounce(float ratio) {
		return 1.0f - outBounce(1.0f - ratio);
	}

	public static float outBounce(float ratio) {
		if (ratio < 1 / 2.75) {
			ratio = 7.5625f * ratio * ratio;
		} else if (ratio < 2f / 2.75f) {
			ratio = ratio - 1.5f / 2.75f;
			ratio = 7.5625f * ratio * ratio + 0.75f;
		} else if (ratio < 2.5f / 2.75f) {
			ratio = ratio - 2.25f / 2.75f;
			ratio = 7.5625f * ratio * ratio + 0.9375f;
		} else {
			ratio = ratio - 2.625f / 2.75f;
			ratio = 7.5625f * ratio * ratio + 0.984375f;
		}
		return ratio;
	}
}
