shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    // Get the color of the screen *behind* this UI element
    vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);

    // Invert the RGB, keep alpha from the texture
    vec4 crosshair_tex = texture(TEXTURE, UV);
    COLOR = vec4(vec3(1.0) - screen_color.rgb, crosshair_tex.a);
}