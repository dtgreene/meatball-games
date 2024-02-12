shader_type spatial;

uniform sampler2D look_noise;

void fragment() {
	vec2 look_position = vec2(0.5, 0.5 + sin(TIME * 2.0) * 0.1);
	float dist = distance(UV, look_position);
	
	ALBEDO = dist > 0.1 ? vec3(1.0) : vec3(0.0);
}
