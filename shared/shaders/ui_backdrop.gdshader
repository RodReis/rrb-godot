// Fundo das telas do Launcher (F25, FRONTEND-LAUNCHER §8.2): o que o CSS do prototipo faz com
// gradiente e blur-3xl. Tres camadas, de baixo para cima:
//   1. gradiente vertical (bg-gradient-to-t: bottom -> mid -> top), cores com alfa;
//   2. vinheta radial (radial-gradient ellipse: centro -> borda);
//   3. ate 3 brilhos redondos e suaves (div rounded-full blur-3xl / circle animate-pulse), com
//      pulso opcional (periodo em s; 0 = parado).
// Posicoes em UV do retangulo; raio em px. Alfa 0 desliga a camada.
shader_type canvas_item;

uniform vec2 rect_size = vec2(1920.0, 1080.0);
uniform vec4 bottom_color : source_color = vec4(0.0);
uniform vec4 mid_color : source_color = vec4(0.0);
uniform vec4 top_color : source_color = vec4(0.0);
uniform vec4 vignette_center : source_color = vec4(0.0);
uniform vec4 vignette_edge : source_color = vec4(0.0);
uniform vec4 glow_color[3];
uniform vec2 glow_center[3];
uniform float glow_radius[3];
uniform float glow_period[3];

vec4 over(vec4 base, vec4 top) {
	float a = top.a + base.a * (1.0 - top.a);
	if (a <= 0.0) {
		return vec4(0.0);
	}
	return vec4((top.rgb * top.a + base.rgb * base.a * (1.0 - top.a)) / a, a);
}

void fragment() {
	float t = 1.0 - UV.y;  // 0 embaixo, 1 em cima (to-t)
	vec4 grad = t < 0.5
		? mix(bottom_color, mid_color, t * 2.0)
		: mix(mid_color, top_color, (t - 0.5) * 2.0);
	vec2 centered = (UV - 0.5) * 2.0;
	vec4 vignette = mix(vignette_center, vignette_edge, clamp(length(centered), 0.0, 1.0));
	vec4 color = over(grad, vignette);
	for (int i = 0; i < 3; i++) {
		if (glow_color[i].a <= 0.0 || glow_radius[i] <= 0.0) {
			continue;
		}
		float d = length((UV - glow_center[i]) * rect_size) / glow_radius[i];
		float soft = exp(-d * d * 2.5);  // gaussiana ~ blur-3xl de um circulo
		float pulse = 1.0;
		if (glow_period[i] > 0.0) {
			// animate-pulse: opacidade 1 -> 0,5 -> 1
			pulse = 0.75 + 0.25 * cos(TIME * TAU / glow_period[i]);
		}
		color = over(color, vec4(glow_color[i].rgb, glow_color[i].a * soft * pulse));
	}
	COLOR = color;
}
