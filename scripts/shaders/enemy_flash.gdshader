shader_type spatial;
render_mode unshaded, cull_disabled; // Keeps 2D sprite lighting simple and visible on both sides

uniform sampler2D texture_albedo : source_color, filter_nearest;
uniform float flash_modifier : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	// Sample the original sprite texture and its alpha transparency
	vec4 color = texture(texture_albedo, UV);
	
	color.rgb = mix(color.rgb, flash_color.rgb, flash_modifier);
	
	ALBEDO = color.rgb;
	ALPHA = color.a; // Keeps sprite transparency intact
}