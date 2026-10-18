shader_type spatial;
// Corpo em chamas do Ragnarok (F75, pedido do PI em 2026-10-18): sobreposicao (material_overlay) em
// todas as malhas do Berserker, como a silhueta do mato, mas com teste de profundidade (nao vaza pela
// parede) e para todos. Vermelho por cima de tudo, borda (fresnel) mais quente e linguas de fogo
// subindo pelo corpo (ruido no espaco do mundo, rolando para cima com o tempo).
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled, cull_back;

uniform vec4 base_color : source_color = vec4(0.75, 0.03, 0.0, 1.0);
uniform vec4 hot_color : source_color = vec4(1.0, 0.62, 0.15, 1.0);
uniform float strength : hint_range(0.0, 2.0) = 1.0;
uniform float flame_scale = 2.6;
uniform float flame_speed = 2.2;

varying vec3 world_pos;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y),
		f.z);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	vec3 p = world_pos * flame_scale - vec3(0.0, TIME * flame_speed, 0.0);
	float flame = noise(p) * 0.65 + noise(p * 2.1) * 0.35;
	flame = smoothstep(0.42, 0.82, flame);
	float pulse = 0.85 + 0.15 * sin(TIME * 9.0);
	ALBEDO = mix(base_color.rgb, hot_color.rgb, clamp(flame * 0.9 + rim * 0.5, 0.0, 1.0));
	ALPHA = clamp((0.28 + 0.6 * flame + 0.45 * rim) * strength * pulse, 0.0, 1.0);
}
