shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 center = vec2(0.5, 0.5);
	
	if (progress <= 0.001) {
		COLOR = texture(screen_texture, uv);
	}else {
		vec2 offset = uv - center;
		
		float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
		offset.x *= aspect;
		
		float dist = length(offset);
		
		float max_radius = length(vec2(aspect * 0.5, 0.5));
		
		float distortion = progress * 0.12 / max(dist, 0.04);
		vec2 warped_uv = uv - normalize(offset + vec2(0.00001)) * distortion;
		
		vec4 scene = texture(
			screen_texture,
			clamp(warped_uv, vec2(0.0), vec2(1.0))
		);
		
		float hole_radius = mix(0.13, max_radius + 0.1, progress);
		float hole = smoothstep(hole_radius - 0.025, hole_radius + 0.025, dist);
		
		float ring_radius = mix(0.19, max_radius + 0.08, progress);
		float ring = exp(-pow((dist - ring_radius) / 0.035, 2.0));
		
		vec3 glow = vec3(0.12, 0.55, 1.0) * ring;
		glow += vec3(0.55, 0.12, 1.0) * ring * 0.65;
		
		vec3 result = scene.rgb * hole;
		result += glow * progress;
		
		COLOR = vec4(result, 1.0);
	}
}