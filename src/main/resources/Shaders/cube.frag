#import "ShaderLib/DeferredUtils.glsllib"

uniform float m_AlphaDiscardThreshold;
uniform sampler2D m_AlphaMap;
uniform sampler2D m_NormalMap;

uniform vec4 m_ColorM;
uniform vec4 m_ColorA;

uniform mat3 g_NormalMatrixInverse;
uniform mat4 g_WorldMatrixInverse;

in vec3 vNormal;
in vec3 vNormal0;
in vec2 vTexCoord;

out vec4 out_FragData[ 3 ];

void main(){
	vec2 texCoord = vTexCoord;

	#ifdef ALPHAMAP
		float alpha = texture2D(m_AlphaMap, texCoord).r;
		if(alpha < m_AlphaDiscardThreshold){
			discard;
		}
	#endif
	#if defined(NORMALMAP)
		vec4 normalHeight = texture2D(m_NormalMap, texCoord);
		//Note the -2.0 and -1.0. We invert the green channel of the normal map,
		//as it's complient with normal maps generated with blender.
		//see http://hub.jmonkeyengine.org/forum/topic/parallax-mapping-fundamental-bug/#post-256898
		//for more explanation.
		vec3 normal = normalize((normalHeight.xyz * vec3(2.0,-2.0,2.0) - vec3(1.0,-1.0,1.0)));
		#ifdef LATC
			normal.z = sqrt(1.0 - (normal.x * normal.x) - (normal.y * normal.y));
		#endif
	#else
		vec3 normal = vNormal;
		#if !defined(LOW_QUALITY) && !defined(V_TANGENT)
			normal = normalize(normal);
		#endif
	#endif
    vec3 n = normalize(normal);
    out_FragData[0] = vec4(encodeNormal(normal), 0.0);

	//vec4 color = mix(vec4(vNormal0, 1.0), m_ColorM, 0.5);
	vec4 color = vec4(vNormal0, 1.0) * m_ColorM;
	color = color + m_ColorA;

	float dx = min( vTexCoord.x, 1.0 - vTexCoord.x );
    float dy = min( vTexCoord.y, 1.0 - vTexCoord.y );
    float d = min( dx, dy );
    float v = 1 - clamp( d*10, 0, 1.0);
    out_FragData[1] = mix(color, vec4(1.0), v);
    out_FragData[2] = vec4(1.0);
}
