shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 portal_color : source_color = vec4(0.05, 0.65, 1.0, 1.0);

void fragment() {
	vec2 uv = UV;
	vec2 center = vec2(0.5);
	vec2 offset = uv - center;
	
	float distance_from_center = length(offset);
	float angle = atan(offset.y, offset.x);
	
	float swirl = progress * 4.0 * (1.0 - distance_from_center);
	angle += swirl;
	
	float distorted_distance = distance_from_center * (1.0 + progress * 0.5);
	
	vec2 distorted_uv = center + vec2(cos(angle), sin(angle)) * distorted_distance;
	
	float radius = mix(0.85, 0.0, progress);
	float edge = smoothstep(radius - 0.08, radius + 0.08, distance_from_center);
	float glow = exp(-abs(distance_from_center - radius) * 35.0);
	vec4 color = mix(portal_color, vec4(0.0, 0.0, 0.0, 1.0), edge);
	
	color.rgb += portal_color.rgb * glow * (1.0 - progress) * 0.7;
	
	COLOR = vec4(color.rgb, progress);
}