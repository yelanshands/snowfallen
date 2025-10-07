shader_type spatial;
render_mode blend_mix;

// This uniform controls the amount of snow. A higher value means more steep surfaces will also get snow.
uniform float snow_amount : hint_range(0.0, 1.0) = 0.5;

// The color and texture of the snow itself.
uniform sampler2D snow_texture : source_color;
uniform vec4 snow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// The color and texture of the base material.
uniform sampler2D base_texture : source_color;
uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// The sharpness of the snow-to-base material transition.
uniform float sharpness : hint_range(0.0, 10.0) = 2.0;

void fragment() {
    // Get the world space normal of the surface.
    vec3 world_normal = NORMAL;
    
    // The `dot` product of the world normal and an upward vector determines how "up" a surface is facing.
    // A value of 1.0 is perfectly flat and facing up, 0.0 is vertical, and -1.0 is flat and facing down.
    float dot_product = dot(world_normal, vec3(0.0, 1.0, 0.0));
    
    // Use `pow` to control the "falloff" and sharpness of the snow.
    float snow_level = pow(dot_product, sharpness);
    
    // Use the `snow_amount` to control how much of the surface is covered.
    float final_snow_factor = smoothstep(1.0 - snow_amount, 1.0, snow_level);

    // Sample the textures.
    vec4 base_tex_color = texture(base_texture, UV) * base_color;
    vec4 snow_tex_color = texture(snow_texture, UV) * snow_color;

    // Mix the base material and the snow based on the calculated factor.
    ALBEDO = mix(base_tex_color, snow_tex_color, final_snow_factor).rgb;
}
