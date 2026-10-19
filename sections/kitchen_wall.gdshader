shader_type spatial;
render_mode unshaded;
// Фисташковые обои кухни: спокойный зелёный с мелким ромбиковым узором и тенью у пола.

uniform vec3 base_color : source_color = vec3(0.30, 0.37, 0.22);
uniform vec3 pattern_color : source_color = vec3(0.33, 0.40, 0.25);

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xy / 0.9;
	vec2 local = fract(p) - 0.5;
	float d = abs(local.x) + abs(local.y);
	float diamond = 1.0 - smoothstep(0.1, 0.16, d);
	vec3 col = mix(base_color, pattern_color, diamond * 0.8);
	col *= mix(0.82, 1.0, smoothstep(0.0, 1.8, wpos.y));
	ALBEDO = col;
}
