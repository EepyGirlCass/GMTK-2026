shader_type canvas_item;

uniform float scroll_speed : hint_range(0, 2) = 0.08;
uniform float angle_degrees : hint_range(0, 360) = 45.0;
uniform float repeat_x : hint_range(1, 20) = 20;
uniform float repeat_y : hint_range(1, 20) = 12;
uniform float row_offset : hint_range(0, 1) = 1;
uniform sampler2D texture_to_scroll;

// --- Color Swap Uniforms ---
uniform vec4 original_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Default: White
uniform vec4 replace_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);  // Default: Red
uniform float tolerance : hint_range(0.0, 1.0) = 0.1;                   // Color detection sensitivity

void fragment() {
    float angle_rad = radians(angle_degrees);

    vec2 direction = vec2(cos(angle_rad), sin(angle_rad));

    vec2 offset_uv = UV - (TIME * scroll_speed * direction);

    float offset = fract(floor(offset_uv.y * repeat_y) * 0.5) > 0.0 ? (row_offset * 0.324) : 0.0;

    offset_uv.x += offset;

    vec2 scaled_uv = vec2(fract(offset_uv.x * repeat_x), 
                          fract(offset_uv.y * repeat_y));

    vec2 texelSize = vec2(1.0) / vec2(textureSize(texture_to_scroll, 0));
    vec2 snappedUV = round(scaled_uv / texelSize) * texelSize;

    // Fetch original pixel color
    vec4 tex_color = texture(texture_to_scroll, snappedUV);

    // Calculate how close the current texel color is to target original_color
    float color_diff = distance(tex_color.rgb, original_color.rgb);

    // Apply color swap if within tolerance distance
    if (color_diff <= tolerance) {
        // Preserves original alpha channel while applying new color
        tex_color.rgb = replace_color.rgb;
        tex_color.a *= replace_color.a; 
    }

    COLOR = tex_color;
}