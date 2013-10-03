precision mediump float;

varying vec2 vTexCoord0;

uniform sampler2D _Tex0;

void main(void) {
  vec4 texelColor = texture2D(_Tex0, vec2(vTexCoord0.s, vTexCoord0.t));
  //vec4 texelColor = vec4(0.5, 1.0, 1.0, 0.5);
  gl_FragColor = texelColor;
}