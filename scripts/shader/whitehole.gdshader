shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment(){
	vec2 uv = SCREEN_UV;
	
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 centered = uv - vec2(0.5, 0.5);
	vec2 aspect_centered = vec2(centered.x * aspect, centered.y);
	
	float dist = length(aspect_centered);
	float max_radius = length(vec2(aspect * 0.5, 0.5));
	float hole_radius = progress * max_radius * 1.15;
	float ring_radius = hole_radius + 0.035;
	float angle = atan(aspect_centered.y, aspect_centered.x);
	float swirl = sin(angle * 8.0 + dist * 35.0 - progress * 15.0);
	float distortion = swirl * 0.012 * progress;
	
	vec2 direction = normalize(centered + vec2(0.0001));
	vec2 warped_uv = uv - direction * distortion;
	
	vec4 screen = textureLod(screen_texture, warped_uv, progress * 2.0);
	
	float hole = 1.0 - smoothstep(hole_radius, hole_radius + 0.015, dist);
	float ring = exp(-pow((dist - ring_radius) * 90.0, 2.0));
	float outer_glow = exp(-pow((dist - ring_radius * 1.5) * 22.0, 2.0));
	
	vec3 white_glow = vec3(1.0);
	vec3 silver_glow = vec3(0.75, 0.82, 0.95);
	vec3 glow = white_glow * ring * 1.8;
	glow += silver_glow * outer_glow * 0.8;
	
	float vignette = smoothstep(max_radius, max_radius * 0.5, dist);
	
	vec3 final_color = screen.rgb;
	final_color = mix(final_color, vec3(0.0), hole);
	final_color += glow * progress;
	final_color = mix(final_color, vec3(0.0), progress * vignette * 0.15);
	
	COLOR = vec4(final_color, 1.0);
}
