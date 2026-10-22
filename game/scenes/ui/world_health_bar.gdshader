// Placa de HP sobre a cabeca (WorldHealthBar, PI 2026-10-22): selo do nivel a esquerda (o numero
// e um Label3D por cima; o chefe ganha coroa) e a barra dividida a cada tick_hp de HP (traco
// inteiro a cada 10), com rastro do dano que escorre (trail), escudo em branco depois do HP e
// moldura. Quad sempre de frente para a camera; um material para todas, o resto por instancia.
// Linhas em pixels de tela (fwidth): nitidas em qualquer distancia. Sem teste de profundidade (passe
// transparente): a placa nao some atras de muro; o numero (Label3D) desenha por cima.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_test_disabled;

instance uniform float ratio : hint_range(0.0, 1.0) = 1.0;
instance uniform float trail : hint_range(0.0, 1.0) = 1.0;
instance uniform float shield = 0.0;
instance uniform float max_hp = 100.0;
instance uniform vec4 fill_color : source_color = vec4(1.0);
instance uniform vec4 badge_color : source_color = vec4(1.0);
// Largura do selo e altura da barra em fracao do quad; 0 = sem selo. crown = 1 desenha a coroa.
instance uniform float badge_frac = 0.0;
instance uniform float bar_height = 0.6;
instance uniform float crown = 0.0;
// Espaco entre o selo e a barra (fracao do quad).
instance uniform float gap_frac = 0.0;

uniform vec4 back_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 frame_color : source_color = vec4(0.02, 0.03, 0.06, 1.0);
uniform vec4 trail_color : source_color = vec4(1.0, 0.93, 0.78, 1.0);
uniform vec4 shield_color : source_color = vec4(0.95, 0.97, 1.0, 1.0);
uniform float tick_hp = 100.0;
// Espessuras em pixels de tela.
uniform float frame_px = 1.5;
uniform float tick_px = 1.0;
uniform float badge_border_px = 2.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]
	);
}

// Coroa do chefe no selo (b em 0..1): faixa na base e tres pontas.
float crown_mask(vec2 b) {
	float band = step(0.2, b.x) * step(b.x, 0.8) * step(0.58, b.y) * step(b.y, 0.74);
	float spikes = 0.0;
	for (int i = 0; i < 3; i++) {
		float cx = 0.25 + 0.25 * float(i);
		float h = clamp((b.y - 0.24) / 0.34, 0.0, 1.0);
		spikes += step(abs(b.x - cx), 0.13 * h) * step(0.24, b.y) * step(b.y, 0.6);
	}
	return clamp(band + spikes, 0.0, 1.0);
}

void fragment() {
	vec2 px = fwidth(UV);
	vec3 color;
	if (badge_frac > 0.0 && UV.x < badge_frac) {
		vec2 b = vec2(UV.x / badge_frac, UV.y);
		vec2 bpx = px / vec2(badge_frac, 1.0);
		vec2 edge = min(b, 1.0 - b) / bpx;
		bool border = min(edge.x, edge.y) < badge_border_px;
		color = border ? badge_color.rgb : mix(back_color.rgb, badge_color.rgb, 0.18 * (1.0 - b.y));
		if (crown > 0.5 && !border) {
			color = mix(color, badge_color.rgb, crown_mask(b));
		}
	} else {
		float start = badge_frac > 0.0 ? badge_frac + gap_frac : 0.0;
		float top = 0.5 - bar_height * 0.5;
		if (UV.y < top || UV.y > 1.0 - top || UV.x < start) {
			discard;
		}
		vec2 local = vec2((UV.x - start) / (1.0 - start), (UV.y - top) / bar_height);
		vec2 lpx = px / vec2(1.0 - start, bar_height);
		vec2 edge = min(local, 1.0 - local) / lpx;
		// HP + escudo acima do maximo encolhe a escala (o escudo nunca some da barra).
		float total = max(1.0, ratio + shield);
		float hp_end = ratio / total;
		float shield_end = (ratio + shield) / total;
		float trail_end = max(trail / total, hp_end);
		if (local.x < hp_end) {
			color = fill_color.rgb * (1.2 - 0.45 * local.y);
		} else if (local.x < shield_end) {
			color = shield_color.rgb;
		} else if (local.x < trail_end) {
			color = trail_color.rgb;
		} else {
			color = back_color.rgb;
		}
		// Divisoes: a cada tick_hp na metade de baixo, a cada 10 de cima a baixo.
		float spacing = tick_hp / max(max_hp, 1.0) / total;
		if (spacing > 0.0 && local.x < shield_end) {
			float at = local.x / spacing;
			float near = min(fract(at), 1.0 - fract(at)) * spacing / lpx.x;
			bool major = abs(round(at) - 10.0 * round(at / 10.0)) < 0.5;
			bool reach = major || local.y > 0.45;
			if (near < tick_px * 0.5 && reach && round(at) > 0.0) {
				color = mix(color, frame_color.rgb, 0.85);
			}
		}
		if (min(edge.x, edge.y) < frame_px) {
			color = frame_color.rgb;
		}
	}
	ALBEDO = color;
	ALPHA = 1.0; // passe transparente: desenha depois do cenario
}
