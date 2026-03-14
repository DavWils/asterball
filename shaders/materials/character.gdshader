shader_type spatial;

/**
Albedo texture for this material
*/
uniform sampler2D albedo_texture : source_color, filter_nearest;

/**
Texture using the primary color.
*/
uniform sampler2D primary_texture : source_color, filter_nearest;
/**
Texture using the secondary color.
*/
uniform sampler2D secondary_texture : source_color, filter_nearest;

/**
The scale of the emission for the primary color
*/
uniform float primary_emission = 0.0;

/**
Primary color.
*/
uniform vec3 primary_color : source_color;

/**
Secondary color.
*/
uniform vec3 secondary_color : source_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 base = texture(albedo_texture, UV).rgb;
	float primary_mask = texture(primary_texture, UV).r;
	float secondary_mask = texture(secondary_texture, UV).r;

	vec3 color = base;
	color = mix(color, primary_color, primary_mask);
	color = mix(color, secondary_color, secondary_mask);

	ALBEDO = color;

	EMISSION = primary_color * primary_mask * primary_emission;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
