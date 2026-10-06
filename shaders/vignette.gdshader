shader_type canvas_item;
// Assombrit doucement les bords de l'écran, pour une ambiance plus cinématographique.

uniform float strength = 0.5;

void fragment() {
	float distance_to_center = length((UV - 0.5) * vec2(1.6, 1.0));
	COLOR = vec4(0.06, 0.04, 0.02, smoothstep(0.55, 1.15, distance_to_center) * strength);
}
