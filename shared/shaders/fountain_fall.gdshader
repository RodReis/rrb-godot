// Agua que transborda da taca da fonte de cura (F95, PI 2026-10-21: "movimento suave da agua
// caindo"). A malha (art/arena/build_world_kit.py, kit_fountain_fall) e uma cortina em anel com
// UV.x em volta e UV.y da borda da taca (0) a bacia (1). Dois ruidos esticados na vertical descem
// em velocidades diferentes e viram fios de agua; a cortina some suave na borda e no pe.
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, specular_schlick_ggx;

uniform vec3 water_color : source_color = vec3(0.78, 0.92, 0.97);
uniform vec3 deep_color : source_color = vec3(0.18, 0.42, 0.48);
uniform sampler2D streak_noise : hint_default_white, repeat_enable, filter_linear_mipmap;
// Quantos fios em volta da taca e velocidade da queda (repeticoes de UV por segundo).
uniform float streaks = 5.0;
uniform float fall_speed = 1.1;
uniform float opacity : hint_range(0.0, 1.0) = 0.7;
uniform float glow : hint_range(0.0, 1.0) = 0.1;

void fragment() {
	vec2 uv_a = vec2(UV.x * streaks, UV.y * 0.7 - TIME * fall_speed);
	vec2 uv_b = vec2(UV.x * streaks * 2.3 + 0.37, UV.y * 1.1 - TIME * fall_speed * 1.4);
	float n = texture(streak_noise, uv_a).r * 0.6 + texture(streak_noise, uv_b).r * 0.4;
	float sheet = smoothstep(0.32, 0.72, n);
	float fade = smoothstep(0.0, 0.1, UV.y) * (1.0 - smoothstep(0.82, 1.0, UV.y));
	ALBEDO = mix(deep_color, water_color, sheet);
	ALPHA = (0.2 + 0.8 * sheet) * opacity * fade;
	ROUGHNESS = 0.05;
	SPECULAR = 0.6;
	EMISSION = water_color * glow * sheet;
}
