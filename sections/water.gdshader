shader_type spatial;
render_mode unshaded, depth_draw_never;
// Вода в поддоне: голубая, полупрозрачная, с бегущими светлыми бликами.

uniform vec4 water_color : source_color = vec4(0.35, 0.7, 0.95, 0.62);

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float w = sin(wpos.x * 3.0 + TIME * 1.6) * 0.5 + sin(wpos.z * 4.0 - TIME * 1.1) * 0.5;
	vec3 col = water_color.rgb + vec3(0.08) * w;
	ALBEDO = col;
	ALPHA = water_color.a;
}
