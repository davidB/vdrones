attribute vec3 _Vertex;
attribute vec2 _TexCoord0;

uniform mat4 _ProjectionViewMatrix;
  
varying vec2 vTexCoord0;
  
void main(void) {
  vTexCoord0 = _TexCoord0;
  gl_Position = _ProjectionViewMatrix * _ModelMatrix * vec4(_Vertex, 1.0);
}