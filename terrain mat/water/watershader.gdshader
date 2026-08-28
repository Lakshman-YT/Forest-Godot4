shader_type spatial; 
#include "res://$lib/funcs/normals.gdshaderinc"
#include "res://$lib/funcs/utils.gdshaderinc"
#include "res://$lib/funcs/colour.gdshaderinc"
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture,repeat_disable; 
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture,repeat_disable; 
uniform vec3 surface_color:source_color;
uniform vec3 depth_color:source_color;
uniform float opacity:hint_range(0.0, 1.0)=0.5; 
uniform sampler2D _foam:source_color; 
uniform sampler2D normal_map:source_color; 
uniform float normal_scale:hint_range(-16.0, 16.0)=1.0;
uniform float beer_factor:hint_range(0.0, 10.0)=0.1; 
uniform float _roughness:hint_range(0.0, 1.0); 
uniform float _refraction:hint_range(0.00, 0.20); 
uniform float _uv_scale:hint_range(0.0, 3.0)=1.0; 
uniform float _foam_strength: hint_range(0.0, 1.0); 
uniform float _foam_size: hint_range(0.0, 0.2); 


void fragment() {
	vec3 vw = (INV_VIEW_MATRIX * vec4(VERTEX,1.0)).xyz;

	vec2 uv_scale = vw.xz * _uv_scale;

	vec3 n  = texture(normal_map, uv_scale + TIME * 0.04).rgb;
	vec3 n2 = texture(normal_map, uv_scale - TIME * 0.06).rgb;
	vec3 n3 = texture(normal_map, uv_scale * 0.3 + vec2(TIME * 0.02, TIME * -0.04)).rgb;

	float scene_depth = depth_linear(DEPTH_TEXTURE, SCREEN_UV, INV_PROJECTION_MATRIX);

	float d  = depth_proximity_z(3.0, scene_depth, VERTEX);
	float d2 = depth_proximity_z(0.2, scene_depth, VERTEX);

	d2 = 1.0 - pow(d2, 0.07);

	// Beer absorption
	d = exp(-d * beer_factor);

	// Fresnel
	d += fresnel(4.0, NORMAL, VIEW);

	ROUGHNESS = _roughness;
	ALPHA = clamp(opacity + 1.0 - d - d2, 0.0, 1.0);

	// Normal maps
	vec3 n_out = normal_blend2(n3, normal_blend(n, n2));

	NORMAL_MAP = n_out;
	NORMAL_MAP_DEPTH = normal_scale;

	vec2 distortion =
		(mat3(TANGENT, BINORMAL, NORMAL) * n_out).rg * 2.0 - 1.0;

	//----------------------------------------------------------
	// Water colour
	//----------------------------------------------------------

	vec3 water_color = mix(depth_color, surface_color, d);

	//----------------------------------------------------------
	// 9-tap blur
	//----------------------------------------------------------

	vec2 refract_uv = SCREEN_UV + distortion * _refraction;

	vec2 blur = vec2(0.08);

	vec3 screen =
		  texture(SCREEN_TEXTURE, refract_uv).rgb

		+ texture(SCREEN_TEXTURE, refract_uv + vec2( blur.x, 0.0)).rgb
		+ texture(SCREEN_TEXTURE, refract_uv - vec2( blur.x, 0.0)).rgb
		+ texture(SCREEN_TEXTURE, refract_uv + vec2(0.0,  blur.y)).rgb
		+ texture(SCREEN_TEXTURE, refract_uv - vec2(0.0,  blur.y)).rgb

		+ texture(SCREEN_TEXTURE, refract_uv + blur).rgb
		+ texture(SCREEN_TEXTURE, refract_uv - blur).rgb
		+ texture(SCREEN_TEXTURE, refract_uv + vec2( blur.x,-blur.y)).rgb
		+ texture(SCREEN_TEXTURE, refract_uv + vec2(-blur.x, blur.y)).rgb;

	screen /= 9.0;

	//----------------------------------------------------------
	// Water depth (murkiness)
	//----------------------------------------------------------

	float water_depth = max(scene_depth - (-VERTEX.z), 0.0);

	// Increase this value for murkier water
	float visibility = exp(-water_depth * 2.5);

	vec3 underwater = mix(water_color, screen, visibility);

	//----------------------------------------------------------
	// Foam
	//----------------------------------------------------------

	float depthfoam = depth_proximity_z(
		abs(distortion.r + distortion.g) * _foam_size,
		scene_depth,
		VERTEX
	);

	depthfoam = pow(depthfoam, _foam_strength);

	vec3 foam = texture(_foam, uv_scale + distortion).rgb;

	//----------------------------------------------------------
	// Final output
	//----------------------------------------------------------

	ALBEDO = mix(foam, soft_light(underwater, water_color), depthfoam);
}
