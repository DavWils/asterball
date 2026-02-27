shader_type sky;

/// Upper sky color.
uniform vec3 skyColor : source_color;
/// Horizon color.
uniform vec3 horizonColor : source_color;


float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.1, 0.1));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}


void sky() {
	float col = clamp(EYEDIR.y / 0.25, 0.0, 1.0);
	vec3 finalColor = mix(horizonColor, skyColor, col);
	
	// Star logic
	vec3 dir = normalize(EYEDIR);
	
	float starNoise = hash(floor(dir * 400.0)); // density control
	float stars = step(0.999, starNoise);       // rarity control
	
	// Fade stars near horizon
	stars *= smoothstep(0.0, 0.2, dir.y);
	
	finalColor += stars;
	
	COLOR = finalColor * LIGHT0_ENERGY;
}