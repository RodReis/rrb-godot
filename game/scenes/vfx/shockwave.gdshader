shader_type spatial;
// Onda de choque do Terremoto (F41): anel deitado que distorce o que esta atras dele (refracao pela
// textura de tela). Particula unica do GPUParticles3D: a escala cresce pela curva ate o diametro
// da area e COLOR.a (rampa de cor da particula) apaga o anel.
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float strength = 0.035;
uniform float ring_width = 0.1;
uniform vec4 tint : source_color = vec4(1.0, 0.75, 0.45, 1.0);
uniform float tint_amount = 0.25;

void fragment() {
	vec2 c = UV - 0.5;
	float d = length(c) * 2.0;
	float inner = smoothstep(1.0 - ring_width * 2.0, 1.0 - ring_width, d);
	float outer = 1.0 - smoothstep(1.0 - ring_width, 1.0, d);
	float ring = inner * outer * COLOR.a;
	vec2 dir = d > 0.0001 ? c / (d * 0.5) : vec2(0.0);
	vec3 behind = textureLod(screen_tex, SCREEN_UV + dir * ring * strength, 0.0).rgb;
	ALBEDO = behind + tint.rgb * ring * tint_amount;
	ALPHA = ring;
}
