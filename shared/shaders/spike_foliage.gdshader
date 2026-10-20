// Folhagem do spike visual F84 (SPEC-084): cartoes de folha do atlas CC0 (ambientCG) com recorte
// por alpha scissor (fica no pipeline opaco, com sombra e sem ordenar), dupla face, luz atravessando
// a folha e balanco de vento suave. A malha (art/spike/f84/build_spike_f84.py, Foliage) traz no
// alpha da cor de vertice o peso do balanco: 0 no pe da touceira, 1 nas pontas. O vento e em
// espaco de mundo (todas as touceiras para o mesmo lado, fase pela posicao da touceira) mais um
// tremor por folha, mais rapido e menor.
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D leaf_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D leaf_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec3 tint : source_color = vec3(1.0);
uniform float alpha_cut : hint_range(0.0, 1.0) = 0.5;
uniform float roughness : hint_range(0.0, 1.0) = 0.75;
uniform float specular_amount : hint_range(0.0, 1.0) = 0.3;
// Luz que atravessa a folha no contraluz (fracao do albedo).
uniform float backlight_amount : hint_range(0.0, 1.0) = 0.35;

group_uniforms vento;
uniform vec2 wind_direction = vec2(0.8, 0.6);
// Deslocamento maximo do galho nas pontas (u).
uniform float wind_strength : hint_range(0.0, 0.5) = 0.06;
uniform float wind_speed = 1.1;
// Comprimento da onda de vento pelo patio (fase por u de mundo).
uniform float wind_scale = 0.25;
// Tremor de cada folha (u) e a frequencia dele.
uniform float flutter : hint_range(0.0, 0.1) = 0.018;
uniform float flutter_speed = 6.5;

void vertex() {
	float weight = COLOR.a;
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 dir = normalize(wind_direction);
	float phase = dot(origin.xz, dir) * wind_scale - TIME * wind_speed;
	float gust = 0.65 + 0.35 * sin(TIME * 0.37 + origin.x * 0.11);
	float sway = (sin(phase) * 0.7 + sin(phase * 2.1 + 1.3) * 0.3) * wind_strength * gust * weight;
	float leaf = sin(TIME * flutter_speed + dot(world, vec3(12.9, 7.3, 4.1))) * flutter * weight;
	vec3 offset = vec3(dir.x * sway + leaf, -abs(sway) * 0.25 + leaf * 0.5, dir.y * sway - leaf * 0.7);
	// Deslocamento de mundo para o espaco do objeto (a touceira pode estar girada e escalada).
	VERTEX += (inverse(MODEL_MATRIX) * vec4(offset, 0.0)).xyz;
}

void fragment() {
	vec4 texel = texture(leaf_albedo, UV);
	ALBEDO = texel.rgb * COLOR.rgb * tint;
	ALPHA = texel.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	NORMAL_MAP = texture(leaf_normal, UV).rgb;
	ROUGHNESS = roughness;
	SPECULAR = specular_amount;
	BACKLIGHT = ALBEDO * backlight_amount;
}
