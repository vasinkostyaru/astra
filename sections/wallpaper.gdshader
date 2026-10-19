shader_type spatial;
render_mode unshaded;
// Обои детской: вертикальные полоски и жёлтые звёздочки (по мировым координатам, без текстур).

uniform vec3 stripe_a : source_color = vec3(0.62, 0.78, 0.95);
uniform vec3 stripe_b : source_color = vec3(0.80, 0.90, 0.98);
uniform vec3 star_color : source_color = vec3(1.0, 0.86, 0.4);

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float stripe = step(0.5, fract(wpos.x / 1.6));
	vec3 col = mix(stripe_a, stripe_b, stripe);
	// звёздочки: ячейки 1.6 х 1.6, в части ячеек — маленький ромбик
	vec2 cell = floor(vec2(wpos.x, wpos.y) / 1.6);
	vec2 local = fract(vec2(wpos.x, wpos.y) / 1.6) - 0.5;
	vec2 offset = vec2(hash(cell) - 0.5, hash(cell + 7.3) - 0.5) * 0.5;
	float on = step(0.55, hash(cell + 3.1));
	float d = abs(local.x - offset.x) + abs(local.y - offset.y);
	float star = on * (1.0 - smoothstep(0.07, 0.1, d));
	col = mix(col, star_color, star);
	// плинтус и тень у пола
	col *= mix(0.78, 1.0, smoothstep(0.0, 1.5, wpos.y));
	ALBEDO = col;
}
