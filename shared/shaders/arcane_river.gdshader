// Rio de mana da Ilha Flutuante Arcana (F40): fluido arcano emissivo que corre pelo anel, desce
// pelos canais N e S e cai no abismo. UV.x e a coordenada ao longo do fluxo (malha unica do
// Blender, art/arena/build_island.py); UV.y atravessa o rio. Espuma pela profundidade da cena
// (water_depth = profundidade linear da cena - profundidade do fragmento, ADR-0006 errata) nas
// margens e pedras; a cascata some aos poucos abaixo da ilha (world_y). Fica fora do toon (F39).
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, specular_schlick_ggx;

uniform vec4 core_color : source_color = vec4(0.0, 0.95, 0.85, 1.0);
uniform vec4 edge_color : source_color = vec4(0.05, 0.45, 0.75, 1.0);
uniform vec4 foam_color : source_color = vec4(0.85, 1.0, 0.95, 1.0);
uniform float flow_speed : hint_range(0.0, 2.0) = 0.5;
uniform float flow_repeat : hint_range(1.0, 16.0) = 6.0;
uniform float emission_strength : hint_range(0.0, 4.0) = 1.6;
uniform float foam_depth : hint_range(0.01, 1.0) = 0.35;
uniform float surface_alpha : hint_range(0.0, 1.0) = 0.92;
// Altura (mundo) em que a cascata comeca a sumir e em que ja sumiu.
uniform float fall_fade_start = -3.0;
uniform float fall_fade_end = -16.0;
uniform sampler2D flow_noise : hint_default_white, repeat_enable;
uniform sampler2D normal_noise : hint_normal, repeat_enable;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

varying float world_y;

void vertex() {
	world_y = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	vec2 flow_uv = UV * vec2(flow_repeat, 1.0) + vec2(-TIME * flow_speed, 0.0);
	float n1 = texture(flow_noise, flow_uv).r;
	float n2 = texture(flow_noise, flow_uv * 0.53 + vec2(TIME * flow_speed * 0.35, 0.17)).r;
	float streak = n1 * 0.6 + n2 * 0.4;

	// Profundidade da agua: cena atras do fragmento menos o proprio fragmento (espaco de vista).
	float raw_depth = texture(depth_texture, SCREEN_UV).r;
	vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, raw_depth, 1.0);
	view.xyz /= view.w;
	float water_depth = -view.z + VERTEX.z;
	float foam = (1.0 - smoothstep(0.0, foam_depth, water_depth)) * step(fall_fade_start, world_y);

	vec3 water = mix(edge_color.rgb, core_color.rgb, streak);
	ALBEDO = mix(water, foam_color.rgb, foam * 0.85);
	EMISSION = core_color.rgb * (streak * 0.6 + 0.4) * emission_strength + foam_color.rgb * foam * 0.6;
	NORMAL_MAP = texture(normal_noise, flow_uv * 2.0).rgb;
	NORMAL_MAP_DEPTH = 0.35;
	ROUGHNESS = 0.12;
	METALLIC = 0.0;
	SPECULAR = 0.6;
	ALPHA = surface_alpha * smoothstep(fall_fade_end, fall_fade_start, world_y);
}
