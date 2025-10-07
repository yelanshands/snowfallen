shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float alpha_strength : hint_range(0.0, 1.0) = 0.7;

void fragment() {
    vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
    vec4 crosshair_tex = texture(TEXTURE, UV);

    float final_alpha = crosshair_tex.a * alpha_strength;

    if (final_alpha < 0.01) {
        discard;
    }
    COLOR = vec4(vec3(1.0) - screen_color.rgb, final_alpha);
}
