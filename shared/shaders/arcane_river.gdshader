// Agua do rio e do riacho do vale (F63, ADR-0014; antes "rio de mana" emissivo do F40). Realista:
// duas camadas de normal ao longo do fluxo + uma em espaco de mundo (sem costura entre malhas),
// refracao do fundo pela tela, cor por absorcao na profundidade (raso esverdeado -> fundo azul),
// fresnel com a cor do ceu, brilho do sol (SPECULAR/ROUGHNESS) e espuma nas margens. UV.x e a
// coordenada ao longo do fluxo (malha unica do Blender, art/arena/build_island.py); UV.y
// atravessa o rio. Profundidade da agua = cena atras - fragmento (espaco de vista, ADR-0006
// errata). A queda abaixo da borda some aos poucos (world_y). Uniforms para o PI ajustar no
// arcane_river.tres: cores, velocidade, escala das ondas, refracao, espuma, transparencia.
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, specular_schlick_ggx;

// Cor da agua rasa e da funda; absorcao por u de profundidade (maior = escurece mais rapido).
uniform vec4 shallow_color : source_color = vec4(0.16, 0.42, 0.42, 1.0);
uniform vec4 deep_color : source_color = vec4(0.02, 0.10, 0.18, 1.0);
uniform float absorption : hint_range(0.0, 4.0) = 1.1;
// Reflexo do ceu no angulo rasante (fresnel) e o quanto ele aparece.
uniform vec4 sky_color : source_color = vec4(0.55, 0.66, 0.78, 1.0);
uniform float fresnel_strength : hint_range(0.0, 1.0) = 0.55;
uniform vec4 foam_color : source_color = vec4(0.88, 0.93, 0.95, 1.0);
// Correnteza (u/s em UV.x) e repeticao das ondas ao longo do fluxo.
uniform float flow_speed : hint_range(0.0, 2.0) = 0.35;
uniform float flow_repeat : hint_range(1.0, 32.0) = 10.0;
// Escala das ondas em espaco de mundo (1/u) e forca da normal.
uniform float world_wave_scale : hint_range(0.01, 2.0) = 0.18;
uniform float wave_strength : hint_range(0.0, 2.0) = 0.7;
// Distorcao da refracao (fracao da tela) e transparencia da superficie.
uniform float refraction : hint_range(0.0, 0.1) = 0.025;
uniform float clarity : hint_range(0.0, 1.0) = 0.55;
uniform float foam_depth : hint_range(0.01, 1.5) = 0.45;
uniform float roughness : hint_range(0.0, 1.0) = 0.06;
// F49: DayNight escala a emissao pelo ciclo (1 = noite). Agua realista quase nao emite: so um
// fio da cor rasa para o rio nao sumir no escuro.
uniform float day_night_emission : hint_range(0.0, 2.0) = 1.0;
uniform float night_glow : hint_range(0.0, 1.0) = 0.08;
// Altura (mundo) em que a queda comeca a sumir e em que ja sumiu.
uniform float fall_fade_start = -3.0;
uniform float fall_fade_end = -16.0;
uniform sampler2D flow_noise : hint_default_white, repeat_enable;
uniform sampler2D normal_noise : hint_normal, repeat_enable;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// Profundidade linear (espaco de vista, positiva) da cena opaca em [param uv].
float scene_depth(vec2 uv, mat4 inv_projection) {
	float raw = texture(depth_texture, uv).r;
	vec4 view = inv_projection * vec4(uv * 2.0 - 1.0, raw, 1.0);
	return -view.z / view.w;
}

void fragment() {
	// Ondas: duas ao longo do fluxo (velocidades diferentes) + uma em mundo, mais lenta.
	vec2 flow_uv = UV * vec2(flow_repeat, 1.0);
	vec3 n1 = texture(normal_noise, flow_uv + vec2(-TIME * flow_speed, 0.0)).rgb;
	vec3 n2 = texture(normal_noise, flow_uv * 0.61 + vec2(-TIME * flow_speed * 0.55, 0.37)).rgb;
	vec3 n3 = texture(normal_noise, world_pos.xz * world_wave_scale + vec2(TIME * 0.02, -TIME * 0.015)).rgb;
	vec3 wave = normalize((n1 + n2 + n3) / 3.0 * 2.0 - 1.0);
	NORMAL_MAP = wave * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = wave_strength;

	// Profundidade da agua e refracao: o fundo distorcido pela onda; sem refratar o que esta na
	// frente da agua (amostra mais perto que a superficie volta para o ponto sem distorcao).
	float surface = -VERTEX.z;
	vec2 offset = wave.xy * refraction;
	vec2 refracted_uv = clamp(SCREEN_UV + offset, vec2(0.001), vec2(0.999));
	float depth_at = scene_depth(refracted_uv, INV_PROJECTION_MATRIX);
	if (depth_at < surface) {
		refracted_uv = SCREEN_UV;
		depth_at = scene_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	}
	float water_depth = max(depth_at - surface, 0.0);
	float straight_depth = max(scene_depth(SCREEN_UV, INV_PROJECTION_MATRIX) - surface, 0.0);

	// Absorcao: quanto mais fundo, menos fundo se ve e mais cor de agua funda.
	float absorb = 1.0 - exp(-water_depth * absorption);
	vec3 bed = textureLod(screen_texture, refracted_uv, 1.5).rgb;
	vec3 water = mix(shallow_color.rgb, deep_color.rgb, absorb);
	vec3 color = mix(water, bed * shallow_color.rgb * 2.2, clarity * (1.0 - absorb));

	// Fresnel: rasante reflete o ceu.
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 4.0);
	color = mix(color, sky_color.rgb, fresnel * fresnel_strength);

	// Espuma na margem e nas pedras, recortada pelo ruido do fluxo.
	float foam_noise = texture(flow_noise, flow_uv * 1.7 + vec2(-TIME * flow_speed, 0.0)).r;
	float foam = (1.0 - smoothstep(0.0, foam_depth, straight_depth)) * smoothstep(0.35, 0.7, foam_noise + 0.25);
	foam *= step(fall_fade_start, world_pos.y);
	color = mix(color, foam_color.rgb, foam * 0.8);

	ALBEDO = color;
	EMISSION = shallow_color.rgb * night_glow * day_night_emission;
	ROUGHNESS = mix(roughness, 0.6, foam);
	METALLIC = 0.0;
	SPECULAR = 0.5;
	ALPHA = smoothstep(fall_fade_end, fall_fade_start, world_pos.y);
}
