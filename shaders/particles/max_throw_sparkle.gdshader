shader_type spatial;

render_mode unshaded, cull_disabled, depth_draw_always, blend_mix;

uniform vec4 color : source_color = vec4(1.0);
uniform float alpha : hint_range(-2.0,2.0) = -0.5;
uniform float shney_disperse : hint_range(0.01,10.0) = 1.0;
uniform float shney_speed : hint_range(0.0,1000.0) = 0.5;
uniform float twist_speed : hint_range(-2.0,2.0) = 1.0;
uniform float rota_speed : hint_range(-10.0,10.0) = 1.0;
uniform float curve_ci : hint_range(0.0,2.0) = 0.3;

void vertex() {
    // World positions
    vec3 cam_pos = CAMERA_POSITION_WORLD;
    vec3 obj_pos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;

    // Direction to camera (Y locked)
    vec3 dir = cam_pos - obj_pos;
    dir.y = 0.0;
    dir = normalize(dir);

    // Extract scale from MODEL_MATRIX
    vec3 scale;
    scale.x = length(MODEL_MATRIX[0].xyz);
    scale.y = length(MODEL_MATRIX[1].xyz);
    scale.z = length(MODEL_MATRIX[2].xyz);

    // Billboard basis (Y up)
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 right = normalize(cross(up, dir));
    vec3 forward = cross(right, up);

    // Apply original scale to local vertex
    vec3 local = VERTEX * scale;

    // Rebuild world position with billboard rotation
    vec3 world_pos = obj_pos
        + right * local.x
        + up * local.y
        + forward * local.z;

    // Back to local space
    VERTEX = (inverse(MODEL_MATRIX) * vec4(world_pos, 1.0)).xyz;
}

void fragment() {
    vec2 uv = (UV - 0.5) * 2.0;

    vec2 a = vec2(cos(TIME * rota_speed), -sin(TIME * rota_speed));
    vec2 b = vec2(sin(TIME * rota_speed), cos(TIME * rota_speed) * twist_speed);

    uv = vec2(uv.x * a.x + uv.y * a.y, uv.x * b.x + uv.y * b.y);

    float sig2 = sin(mod(TIME * shney_speed, PI));
    float L = (1.0 / (2.0 * PI * sig2)) *
              exp(-((uv.x * uv.x + uv.y * uv.y) / (2.0 * sig2 * shney_disperse))) + alpha;

    float visible = 0.0;

    if (uv.x > 0.0 && uv.y > 0.0) {
        if (uv.y <= pow(-(pow(uv.x, curve_ci) - 1.0), 1.0 / curve_ci)) visible = 1.0;
    } else if (uv.x > 0.0 && uv.y < 0.0) {
        if (uv.y >= -pow(-(pow(uv.x, curve_ci) - 1.0), 1.0 / curve_ci)) visible = 1.0;
    } else if (uv.x < 0.0 && uv.y > 0.0) {
        if (uv.y <= pow(-(pow(-uv.x, curve_ci) - 1.0), 1.0 / curve_ci)) visible = 1.0;
    } else {
        if (uv.y >= -pow(-(pow(-uv.x, curve_ci) - 1.0), 1.0 / curve_ci)) visible = 1.0;
    }

    ALBEDO = color.rgb;
    ALPHA = visible * L;
}