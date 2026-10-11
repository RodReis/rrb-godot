shader_type spatial;
// Indicador da Chuva de Flechas (F41): preenchimento leve, aro fino continuo e borda tracejada que
// gira, legivel sobre qualquer chao (bloco visual regra 6). Malha plana de raio 1 (PlaneMesh 2x2);
// o RainArea escala pelo raio do GDB.
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 fill_color : source_color = vec4(0.36, 0.62, 1.0, 0.07);
uniform vec4 rim_color : source_color = vec4(0.6, 0.85, 1.0, 0.95);
uniform float rim_width = 0.05;
uniform float dashes = 28.0;
// Voltas por segundo da borda tracejada.
uniform float spin = 0.12;

varying vec2 local;

void vertex() {
	local = VERTEX.xz;
}

void fragment() {
	float d = length(local);
	if (d > 1.0) {
		discard;
	}
	float band = smoothstep(1.0 - rim_width * 2.0, 1.0 - rim_width, d);
	float angle = atan(local.y, local.x) / TAU;
	float dash = step(0.5, fract((angle + TIME * spin) * dashes));
	float line = smoothstep(0.86, 0.87, d) * (1.0 - smoothstep(0.88, 0.89, d));
	float rim = max(band * dash, line);
	vec4 col = mix(fill_color, rim_color, rim);
	ALBEDO = col.rgb;
	ALPHA = col.a;
}
