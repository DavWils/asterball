shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 1.0) = 1.0;
uniform vec4 smoke_color = vec4(0.1,0.1,0.1,1.0);

uniform sampler2D noise_texture;
uniform float noise_speed = 0.0;

void fragment() {
    vec2 animated_uv = fract(UV + vec2(0.0, TIME * noise_speed));
    
    float noise_value = texture(noise_texture, animated_uv).r;
    
	vec4 screen = texture(SCREEN_TEXTURE, SCREEN_UV);
    
	float smoke_strength = noise_value * intensity;

	vec3 smoke = smoke_color.rgb * smoke_strength;

	COLOR = vec4(smoke,COLOR.a *  max(smoke_strength, 1.0));
}