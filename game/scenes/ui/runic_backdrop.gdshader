shader_type canvas_item;
// Fundo runico da selecao de herois (F51, prototipo docs/prd/telas/Seleção de Heróis): gradiente
// de 3 paradas, ate 3 brilhos radiais, grade de pontos e, se pedido, cantos arredondados com borda.
// O CSS faz isso com background-image/border-radius; o Control nao, entao vai por shader (§8.2).

// Tamanho do retangulo em px, mantido pelo RunicBackdrop.
uniform vec2 rect_size = vec2(100.0);
uniform vec4 color_a : source_color = vec4(0.027, 0.047, 0.094, 1.0);
uniform vec4 color_b : source_color = vec4(0.027, 0.047, 0.094, 1.0);
uniform vec4 color_c : source_color = vec4(0.027, 0.047, 0.094, 1.0);
// false = de cima para baixo, true = da esquerda para a direita.
uniform bool horizontal = false;
// Brilho radial: centro em UV, raio em fracao do lado maior; alfa 0 = desligado.
uniform vec4 glow_color_1 : source_color = vec4(0.0);
uniform vec2 glow_center_1 = vec2(0.5, 0.0);
uniform float glow_radius_1 = 0.6;
uniform vec4 glow_color_2 : source_color = vec4(0.0);
uniform vec2 glow_center_2 = vec2(0.15, 0.5);
uniform float glow_radius_2 = 0.4;
uniform vec4 glow_color_3 : source_color = vec4(0.0);
uniform vec2 glow_center_3 = vec2(0.85, 0.5);
uniform float glow_radius_3 = 0.4;
// Grade de pontos (radial-gradient 1 px repetido).
uniform vec4 dot_color : source_color = vec4(1.0, 1.0, 1.0, 0.03);
uniform float dot_spacing = 24.0;
uniform float dot_radius = 1.0;
// Cantos em px; borda em px por dentro do retangulo (0 = sem borda).
uniform float corner_radius = 0.0;
uniform float border_width = 0.0;
uniform vec4 border_color : source_color = vec4(0.0);

varying vec2 local;

void vertex() {
	local = VERTEX;
}

vec4 over(vec4 base, vec4 top) {
	return vec4(mix(base.rgb, top.rgb, top.a), top.a + base.a * (1.0 - top.a));
}

float glow(vec2 uv, vec2 center, float radius) {
	vec2 d = (uv - center) * rect_size / max(rect_size.x, rect_size.y);
	return clamp(1.0 - length(d) / radius, 0.0, 1.0);
}

float rounded_box(vec2 p, vec2 half_size, float r) {
	vec2 q = abs(p) - half_size + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	float t = horizontal ? UV.x : UV.y;
	vec4 col = t < 0.5 ? mix(color_a, color_b, t * 2.0) : mix(color_b, color_c, t * 2.0 - 1.0);
	col = over(col, vec4(glow_color_1.rgb, glow_color_1.a * glow(UV, glow_center_1, glow_radius_1)));
	col = over(col, vec4(glow_color_2.rgb, glow_color_2.a * glow(UV, glow_center_2, glow_radius_2)));
	col = over(col, vec4(glow_color_3.rgb, glow_color_3.a * glow(UV, glow_center_3, glow_radius_3)));
	vec2 cell = mod(local, dot_spacing) - dot_spacing * 0.5;
	float dot_mask = 1.0 - smoothstep(dot_radius - 0.5, dot_radius + 0.5, length(cell));
	col = over(col, vec4(dot_color.rgb, dot_color.a * dot_mask));
	float d = rounded_box(local - rect_size * 0.5, rect_size * 0.5, corner_radius);
	if (border_width > 0.0) {
		float edge = smoothstep(-border_width - 0.5, -border_width + 0.5, d);
		col = over(col, vec4(border_color.rgb, border_color.a * edge));
	}
	col.a *= 1.0 - smoothstep(-0.5, 0.5, d);
	COLOR = col;
}
