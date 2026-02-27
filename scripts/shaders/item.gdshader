shader_type spatial;

// Albedo texture for this material
uniform sampler2D albedo_texture : source_color;


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Sample the texture using the built-in UV coordinates
	vec4 albedo_tex = texture(albedo_texture, UV);
	// Apply texture color to the material
	ALBEDO = albedo_tex.rgb;
	ALPHA = albedo_tex.a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
