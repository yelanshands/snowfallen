shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float alpha_strength : hint_range(0.0, 1.0) = 0.7;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
    vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
    vec4 crosshair_tex = texture(TEXTURE, UV);

    // Use the crosshair texture alpha *and* your chosen strength
    float final_alpha = crosshair_tex.a * alpha_strength;

    // Only apply effect where crosshair has some alpha
    if (final_alpha < 0.01) {
        discard; // fully skip transparent parts
    }

    // Invert background but keep ~70% transparency
    COLOR = vec4(vec3(1.0) - screen_color.rgb, final_alpha);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
