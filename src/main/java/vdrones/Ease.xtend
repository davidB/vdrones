package vdrones

import static java.lang.Math.*
//import static com.jme3.math.FastMath.*;
import org.eclipse.xtext.xbase.lib.Functions.Function1

class Ease {
	public static val identity = [float ratio| ratio]

	public static val inverse = [float ratio| 1.0f - ratio]

	public static def Function1<Float, Float> compose(Function1<Float, Float> op1, Function1<Float, Float> op2){
		return [v| op2.apply(op1.apply(v))]
	}

	public static val outElastic= [float ratio|
		return (if((ratio === 0.0 || ratio === 1.0)) ratio else pow(2.0, -10.0 * ratio) *
			sin((ratio - 0.3 / 4.0) * (2.0 * PI) / 0.3) + 1 ) as float
	]

	public static val inBounce = [float ratio|
		1.0f - outBounce.apply(1.0f - ratio)
	]

	public static val outBounce = [float ratio_finalParam|
		var ratio = ratio_finalParam
		if (ratio < 1 / 2.75) {
			ratio = 7.5625f * ratio * ratio
		} else if (ratio < 2f / 2.75f) {
			ratio = ratio - 1.5f / 2.75f
			ratio = 7.5625f * ratio * ratio + 0.75f
		} else if (ratio < 2.5f / 2.75f) {
			ratio = ratio - 2.25f / 2.75f
			ratio = 7.5625f * ratio * ratio + 0.9375f
		} else {
			ratio = ratio - 2.625f / 2.75f
			ratio = 7.5625f * ratio * ratio + 0.984375f
		}
		return ratio
	]

}
