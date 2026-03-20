shader_type canvas_item;

uniform sampler2D terrain_image: source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D lookup_image: source_color, filter_nearest;
uniform sampler2D color_map_image: source_color, filter_nearest;

void fragment() {
	float normalized_offset = 100.0 / float(textureSize(color_map_image,0).y);
	float texture_width = float(textureSize(lookup_image,0).x);
	float texture_height = float(textureSize(lookup_image,0).y);
	int checkers_pattern = int(mod(floor(UV.x*texture_width/10.0) + floor(UV.y*texture_height/10.0), 2.0));
	
	vec4 terrain_texture = texture(terrain_image, UV);
	vec3 lookup_texture = texture(lookup_image, UV).rgb;
	vec4 map_mode_primary = texture(color_map_image, vec2(lookup_texture.r, lookup_texture.g));
	
	vec4 final_color = mix(map_mode_primary, terrain_texture, 0.8);
	COLOR = final_color;
}