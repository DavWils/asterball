shader_type spatial;
render_mode diffuse_toon, specular_toon;

/**
Albedo texture for this material
*/
uniform sampler2D albedo_texture : source_color, filter_nearest;
/**
Emission texture for this material
*/
uniform sampler2D emission_texture : source_color, filter_nearest;

/**
Emission tint
*/
uniform vec3 emission_color : source_color = vec3(0.0,0.0,0.0);
/**
Strength of emission
*/
uniform float emission_strength = 1.0;
/**
Metallic value of item.
*/
uniform float metallic: hint_range(0.0,1.0) = 0.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Sample the texture using the built-in UV coordinates
	vec4 albedo_tex = texture(albedo_texture, UV);
	vec4 emission_tex = texture(emission_texture, UV);

	// Apply texture color to the material
	ALBEDO = albedo_tex.rgb;
	ROUGHNESS = 0.0;
	EMISSION = emission_tex.rgb * emission_color * emission_strength;
	METALLIC = metallic;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
