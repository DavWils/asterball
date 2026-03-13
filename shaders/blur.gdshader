shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform float blur_amount : hint_range(0.0, 10.0) = 100.0;

void fragment() {
    vec2 screen_size = vec2(textureSize(SCREEN_TEXTURE, 0));
    vec2 blur = blur_amount / screen_size;

    vec4 col = vec4(0.0);

    col += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(-blur.x, 0.0));
    col += texture(SCREEN_TEXTURE, SCREEN_UV + vec2( blur.x, 0.0));
    col += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, -blur.y));
    col += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0,  blur.y));
    col += texture(SCREEN_TEXTURE, SCREEN_UV);

    COLOR = col / 5.0;
}
