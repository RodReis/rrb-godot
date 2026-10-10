// Vinheta da zona (PATTERNS P8, HudPhase2): bordas da tela na cor da zona, pulsando com periodo
// pulse_period; intensity (0-1) = dano atual / maior dano, so com o flag do servidor. Cor e
// periodo vem de UiTokens pelo script.
shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_period = 1.0;
// Raio (UV centrado, 0 = centro, 1 = meio da borda) onde a vinheta comeca e onde satura.
uniform float inner = 0.45;
uniform float outer = 1.3;
// Fracao do brilho que pulsa e opacidade maxima.
uniform float pulse_depth = 0.3;
uniform float max_alpha = 0.8;

void fragment() {
	float edge = smoothstep(inner, outer, length(UV * 2.0 - 1.0));
	float pulse = 1.0 - pulse_depth * (0.5 + 0.5 * sin(TIME * TAU / pulse_period));
	COLOR = vec4(color.rgb, edge * intensity * pulse * max_alpha);
}
