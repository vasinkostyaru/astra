shader_type spatial;
render_mode unshaded;
// Обои гостиной: бело-голубые с мягкими полосами и маленькими птичками.

uniform vec3 base_color : source_color = vec3(0.88, 0.93, 0.98);
uniform vec3 stripe_color : source_color = vec3(0.80, 0.88, 0.96);
uniform vec3 bird_color : source_color = vec3(0.5, 0.76, 0.97);
uniform vec3 bird_color2 : source_color = vec3(0.95, 0.75, 0.3);

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

void fragment() {
	vec3 col = mix(base_color, stripe_color, step(0.5, fract(wpos.x / 2.4)));
	float cell_size = 2.2;
	vec2 cell = floor(vec2(wpos.x, wpos.y) / cell_size);
	vec2 local = fract(vec2(wpos.x, wpos.y) / cell_size) - 0.5;
	float on = step(0.45, hash(cell + 11.0));
	vec2 off = (vec2(hash(cell), hash(cell + 5.0)) - 0.5) * 0.35;
	vec2 p = (local - off) * cell_size;
	// птичка: два крыла «галочкой» и тело-точка
	float d = min(seg(p, vec2(-0.3, 0.14), vec2(0.0, 0.0)), seg(p, vec2(0.0, 0.0), vec2(0.3, 0.14)));
	d = min(d, length(p - vec2(0.0, -0.02)) - 0.04);
	float bird = on * (1.0 - smoothstep(0.03, 0.05, d));
	vec3 bc = mix(bird_color, bird_color2, step(0.82, hash(cell + 2.0)));
	col = mix(col, bc, bird);
	col *= mix(0.85, 1.0, smoothstep(0.0, 1.5, wpos.y));
	ALBEDO = col;
}
