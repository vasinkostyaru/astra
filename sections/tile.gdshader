shader_type spatial;
render_mode unshaded;
// Плитка с швами по мировым координатам: на стене (xy) и на полу (xz).

uniform vec3 tile_a : source_color = vec3(0.93, 0.42, 0.38);
uniform vec3 tile_b : source_color = vec3(0.89, 0.37, 0.34);
uniform vec3 grout : source_color = vec3(0.97, 0.94, 0.92);
uniform float tile_size = 1.0;
uniform bool floor_mode = false;
uniform float fade_floor = 0.0;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 p = floor_mode ? wpos.xz : wpos.xy;
	vec2 cell = floor(p / tile_size);
	vec2 local = fract(p / tile_size);
	vec3 col = mix(tile_a, tile_b, step(0.5, hash(cell)));
	float edge = min(min(local.x, 1.0 - local.x), min(local.y, 1.0 - local.y));
	col = mix(grout, col, smoothstep(0.02, 0.045, edge));
	// мягкий блик по плитке
	col += vec3(0.05) * smoothstep(0.7, 0.2, distance(local, vec2(0.3, 0.7)));
	if (!floor_mode) {
		col *= mix(0.8, 1.0, smoothstep(0.0, 1.5, wpos.y));
	}
	ALBEDO = col;
}
