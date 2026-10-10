// Cristais arcanos (F40): fresnel emissivo com pulso lento; a cor vem do material (.tres por
// variante: magenta, ciano, verde). Fica fora do toon (F39).
shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;

uniform vec4 crystal_color : source_color = vec4(0.85, 0.15, 0.85, 1.0);
uniform float fresnel_power : hint_range(0.5, 6.0) = 2.5;
uniform float emission_mult : hint_range(0.0, 5.0) = 2.2;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.5;

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);
	float pulse = 0.85 + 0.15 * sin(TIME * pulse_speed);
	ALBEDO = crystal_color.rgb * 0.45;
	EMISSION = crystal_color.rgb * (0.35 + fresnel) * emission_mult * pulse;
	ROUGHNESS = 0.15;
	METALLIC = 0.1;
	SPECULAR = 0.8;
}
