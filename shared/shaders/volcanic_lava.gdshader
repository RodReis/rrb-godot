// Lago de magma da cratera (F40): disco plano no chao do covil do boss (ADR-0007: sem fosso).
// Placas de rocha fria com fissuras de lava viva (voronoi DISTANCE2_SUB: 0 nas bordas das
// celulas) e uma poca incandescente no centro, com pulso lento. Fica fora do toon (F39).
shader_type spatial;

uniform vec4 magma_bright : source_color = vec4(1.0, 0.75, 0.2, 1.0);
uniform vec4 magma_dark : source_color = vec4(0.9, 0.2, 0.05, 1.0);
uniform vec4 rock_crust : source_color = vec4(0.12, 0.1, 0.1, 1.0);
uniform float pulse_speed : hint_range(0.0, 3.0) = 1.2;
uniform float emission_energy : hint_range(0.0, 5.0) = 3.0;
uniform float crack_width : hint_range(0.02, 0.5) = 0.16;
uniform float pool_radius : hint_range(0.0, 0.5) = 0.14;
uniform float tiles : hint_range(1.0, 8.0) = 3.0;
uniform sampler2D voronoi_cracks : hint_default_white, repeat_enable;
uniform sampler2D flow_noise : hint_default_white, repeat_enable;

void fragment() {
	vec2 uv = UV * tiles;
	float drift = texture(flow_noise, uv * 0.5 + vec2(TIME * 0.03, -TIME * 0.02)).r;
	float cell = texture(voronoi_cracks, uv + drift * 0.08).r;
	float cracks = 1.0 - smoothstep(crack_width * 0.6, crack_width, cell);
	float pool = 1.0 - smoothstep(pool_radius * 0.7, pool_radius, distance(UV, vec2(0.5)));
	float is_lava = max(cracks, pool);

	float pulse = (sin(TIME * pulse_speed + drift * 6.0) + 1.0) * 0.5;
	vec3 lava = mix(magma_dark.rgb, magma_bright.rgb, pulse * 0.5 + drift * 0.5);

	ALBEDO = mix(rock_crust.rgb, lava, is_lava);
	EMISSION = lava * is_lava * emission_energy;
	ROUGHNESS = mix(0.95, 0.3, is_lava);
}
