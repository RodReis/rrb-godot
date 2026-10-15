// Fundo do CTA da fila (prototipo Menu Principal, #btn-matchmaking): gradiente horizontal de
// tres paradas (from/via/to), cantos rounded-xl, borda 3D embaixo (shadow 0 6px 0) e o reflexo
// que atravessa no hover (div bg-white/20 skew-x-12, translate de -100 % a 300 % em 1 s).
// shine 0..1 e a posicao do reflexo (a tela anima por Tween); press afunda a borda (0..1).
shader_type canvas_item;

uniform vec2 rect_size = vec2(400.0, 120.0);
uniform vec4 color_from : source_color = vec4(0.961, 0.620, 0.043, 1.0);
uniform vec4 color_via : source_color = vec4(1.0, 0.757, 0.455, 1.0);
uniform vec4 color_to : source_color = vec4(0.961, 0.620, 0.043, 1.0);
uniform vec4 edge_color : source_color = vec4(0.576, 0.337, 0.0, 1.0);
uniform float radius = 8.0;
uniform float edge = 6.0;
uniform float press = 0.0;
uniform float brighten = 0.0;
uniform float shine = -1.0;

float rounded_box(vec2 p, vec2 half_size, float r) {
	vec2 q = abs(p) - half_size + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 px = UV * rect_size;
	float edge_now = mix(edge, edge / 3.0, press);
	// Face: retangulo de cima (altura - borda), deslocado para baixo ao apertar.
	float face_h = rect_size.y - edge;
	float face_top = edge - edge_now;
	vec2 face_center = vec2(rect_size.x * 0.5, face_top + face_h * 0.5);
	float face_d = rounded_box(px - face_center, vec2(rect_size.x, face_h) * 0.5, radius);
	vec2 base_center = vec2(rect_size.x * 0.5, face_top + edge_now + face_h * 0.5);
	float base_d = rounded_box(px - base_center, vec2(rect_size.x, face_h) * 0.5, radius);
	float face = clamp(0.5 - face_d, 0.0, 1.0);
	float base = clamp(0.5 - base_d, 0.0, 1.0);
	float x = UV.x;
	vec4 grad = x < 0.5 ? mix(color_from, color_via, x * 2.0) : mix(color_via, color_to, (x - 0.5) * 2.0);
	grad.rgb = grad.rgb * (1.0 + brighten);
	// Reflexo: faixa de meia largura inclinada 12 graus, branca a 20 %.
	float skew = (px.y - face_center.y) * tan(radians(12.0));
	float band_x = (px.x + skew) / rect_size.x;
	float in_band = step(shine, band_x) * step(band_x, shine + 0.5);
	grad.rgb = mix(grad.rgb, vec3(1.0), 0.2 * in_band);
	vec4 color = mix(vec4(edge_color.rgb, base), vec4(grad.rgb, 1.0), face);
	color.a = max(face, base);
	COLOR = color;
}
