shader_type canvas_item;
// Sol « peint » façon Albion : pas de quadrillage, transitions douces entre terrains,
// rivages, eau animée et ombres de nuages. Une texture minuscule (1 pixel par tuile)
// donne le terrain de chaque case ; tout le reste est calculé ici.

uniform sampler2D terrain_map : filter_linear, repeat_disable; // r = herbe, g = pierre, b = eau
uniform vec2 map_size;
uniform vec2 origin;   // centre de la case (0, 0)
uniform vec2 inv_x;    // inverse de la projection isométrique (colonnes)
uniform vec2 inv_y;

varying vec2 world_pos;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amplitude * noise(p);
		p *= 2.03;
		amplitude *= 0.5;
	}
	return value;
}

void vertex() {
	world_pos = VERTEX;
}

void fragment() {
	vec2 p = world_pos;
	// Position en cases, légèrement déformée pour des bords organiques.
	vec2 cell = mat2(inv_x, inv_y) * (p - origin);
	vec2 warp = vec2(fbm(p * 0.012), fbm(p * 0.012 + 17.3)) - 0.5;
	vec2 uv = (cell + 0.5 + warp * 0.55) / map_size;
	vec3 weights = texture(terrain_map, uv).rgb;
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		weights = vec3(0.0, 0.0, 1.0);
	}

	float broad = fbm(p * 0.004);
	float medium = fbm(p * 0.03);
	float fine = noise(p * 0.35);

	// Herbe : plusieurs verts désaturés, plaques sèches, brins.
	vec3 grass = mix(vec3(0.33, 0.45, 0.22), vec3(0.45, 0.55, 0.26), broad);
	grass = mix(grass, vec3(0.27, 0.38, 0.19), smoothstep(0.55, 0.75, medium) * 0.6);
	grass = mix(grass, vec3(0.56, 0.54, 0.31), smoothstep(0.62, 0.8, fbm(p * 0.008 + 5.0)) * 0.55);
	grass *= 0.94 + fine * 0.12;

	// Pierre : dalles beiges avec fissures sombres.
	float cracks = smoothstep(0.02, 0.06, abs(fbm(p * 0.045) - 0.5));
	vec3 stone = mix(vec3(0.47, 0.44, 0.40), vec3(0.62, 0.58, 0.51), medium);
	stone *= 0.84 + 0.16 * cracks;
	stone *= 0.95 + fine * 0.1;

	// Terre battue entre l'herbe et la pierre.
	vec3 dirt = mix(vec3(0.42, 0.34, 0.24), vec3(0.52, 0.43, 0.30), medium) * (0.93 + fine * 0.12);

	// Eau : profonde au large, plus claire près du bord, reflets animés.
	float depth = smoothstep(0.5, 0.95, weights.b);
	vec3 water = mix(vec3(0.27, 0.48, 0.50), vec3(0.15, 0.30, 0.37), depth);
	float ripple = fbm(p * 0.04 + vec2(TIME * 0.15, TIME * 0.08));
	water += vec3(0.08, 0.1, 0.1) * smoothstep(0.62, 0.75, ripple);

	// Assemblage des terrains.
	float stone_amount = smoothstep(0.35, 0.65, weights.g + (medium - 0.5) * 0.3);
	vec3 land = mix(grass, stone, stone_amount);
	float dirt_band = (1.0 - abs(stone_amount - 0.5) * 2.0) * 0.8;
	land = mix(land, dirt, dirt_band * 0.7);

	float water_amount = smoothstep(0.45, 0.55, weights.b + (medium - 0.5) * 0.15);
	float sand_band = smoothstep(0.25, 0.45, weights.b) * (1.0 - water_amount);
	land = mix(land, vec3(0.66, 0.60, 0.44) * (0.95 + fine * 0.1), sand_band * 0.85);
	vec3 color = mix(land, water, water_amount);

	// Écume le long du rivage.
	float foam = (1.0 - abs(water_amount - 0.6) * 4.0) * step(0.05, water_amount);
	color = mix(color, vec3(0.85, 0.9, 0.86), clamp(foam, 0.0, 1.0) * smoothstep(0.4, 0.7, noise(p * 0.15 + TIME * 0.6)) * 0.6);

	// Ombres de nuages qui passent lentement, lumière chaude.
	float clouds = smoothstep(0.45, 0.75, fbm(p * 0.0015 + vec2(TIME * 0.006, TIME * 0.003)));
	color *= 1.0 - clouds * 0.18;
	color *= vec3(1.04, 1.0, 0.94);

	COLOR = vec4(color, 1.0);
}
