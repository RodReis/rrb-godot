// Terreno da Ilha (F40, PI 2026-10-11: realista e sombrio). Cinco camadas PBR CC0 misturadas
// por uma mascara em espaco de mundo gerada pelo builder da arena (splat_map: R terra das
// trilhas, G pedra das bases, B musgo, A rocha forcada); grama onde a mascara e zero. Rocha
// tambem por inclinacao (penhascos, bolsoes) e no leito do rio, mais escura perto da agua.
// Projecao planar xz no chao e triplanar na rocha: a malha nao tem UV util (o UV2 e do
// LightmapGI do F38), entao a normal e composta em mundo (whiteout) e escrita em NORMAL.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D splat_map : hint_default_black, filter_linear, repeat_disable;
// Retangulo (x0, z0, largura, profundidade) do mundo coberto pela mascara.
uniform vec4 splat_rect = vec4(-50.0, -50.0, 100.0, 100.0);

group_uniforms grass;
uniform sampler2D grass_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_rough : hint_roughness_gray, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float grass_tile = 0.3;
uniform vec3 grass_tint : source_color = vec3(1.0);

group_uniforms moss;
uniform sampler2D moss_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D moss_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D moss_rough : hint_roughness_gray, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float moss_tile = 0.25;
uniform vec3 moss_tint : source_color = vec3(1.0);

group_uniforms dirt;
uniform sampler2D dirt_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_rough : hint_roughness_gray, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float dirt_tile = 0.25;
uniform vec3 dirt_tint : source_color = vec3(1.0);

group_uniforms paving;
uniform sampler2D paving_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D paving_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D paving_rough : hint_roughness_gray, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float paving_tile = 0.3;
uniform vec3 paving_tint : source_color = vec3(1.0);

group_uniforms rock;
uniform sampler2D rock_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_rough : hint_roughness_gray, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float rock_tile = 0.15;
uniform vec3 rock_tint : source_color = vec3(1.0);
// Normal da superficie (y) a partir da qual vira rocha: penhasco abaixo de slope_end.
uniform float slope_start : hint_range(0.0, 1.0) = 0.85;
uniform float slope_end : hint_range(0.0, 1.0) = 0.6;

group_uniforms blend;
// Ruido continuo (NoiseTexture2D seamless): quebra a borda da mascara e a repeticao do tile.
uniform sampler2D macro_noise : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float edge_noise : hint_range(0.0, 1.0) = 0.45;
uniform float edge_sharpness : hint_range(1.0, 10.0) = 3.5;
uniform float macro_scale = 0.03;
uniform float macro_strength : hint_range(0.0, 1.0) = 0.3;
// Leito do rio: abaixo de bed_top vira rocha molhada, ate bed_bottom.
uniform float bed_top = -0.15;
uniform float bed_bottom = -0.55;
uniform float wet_darken : hint_range(0.0, 1.0) = 0.55;

group_uniforms grade;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// Normal map (convencao GL) com o eixo v do Godot (para baixo na imagem) desvirado.
vec3 unpack_normal(vec4 texel) {
	// So x/y: com import de normal map (BC5) o canal z nao vem; reconstroi.
	vec2 t = texel.rg * 2.0 - 1.0;
	return vec3(t.x, -t.y, sqrt(clamp(1.0 - dot(t, t), 0.0, 1.0)));
}

// Camada projetada de cima (xz): albedo, rugosidade e normal em mundo (whiteout).
void planar(
	sampler2D albedo_tex, sampler2D normal_tex, sampler2D rough_tex, float tile, vec3 tint,
	vec3 pos, vec3 n, out vec3 albedo, out float rough, out vec3 normal
) {
	vec2 uv = pos.xz * tile;
	albedo = texture(albedo_tex, uv).rgb * tint;
	rough = texture(rough_tex, uv).r;
	vec3 t = unpack_normal(texture(normal_tex, uv));
	normal = normalize(vec3(t.xy + n.xz, abs(t.z) * n.y).xzy);
}

// Camada triplanar (penhasco): pesos pela normal, normal por projecao (whiteout).
void triplanar(
	sampler2D albedo_tex, sampler2D normal_tex, sampler2D rough_tex, float tile, vec3 tint,
	vec3 pos, vec3 n, out vec3 albedo, out float rough, out vec3 normal
) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= w.x + w.y + w.z;
	vec2 uv_x = pos.zy * tile;
	vec2 uv_y = pos.xz * tile;
	vec2 uv_z = pos.xy * tile;
	albedo = (
		texture(albedo_tex, uv_x).rgb * w.x
		+ texture(albedo_tex, uv_y).rgb * w.y
		+ texture(albedo_tex, uv_z).rgb * w.z
	) * tint;
	rough = (
		texture(rough_tex, uv_x).r * w.x
		+ texture(rough_tex, uv_y).r * w.y
		+ texture(rough_tex, uv_z).r * w.z
	);
	vec3 tx = unpack_normal(texture(normal_tex, uv_x));
	vec3 ty = unpack_normal(texture(normal_tex, uv_y));
	vec3 tz = unpack_normal(texture(normal_tex, uv_z));
	tx = vec3(tx.xy + n.zy, abs(tx.z) * n.x);
	ty = vec3(ty.xy + n.xz, abs(ty.z) * n.y);
	tz = vec3(tz.xy + n.xy, abs(tz.z) * n.z);
	normal = normalize(tx.zyx * w.x + ty.xzy * w.y + tz.xyz * w.z);
}

// Peso de uma camada da mascara com a borda quebrada pelo ruido.
float edge(float mask, float noise) {
	return clamp((mask - 0.5 + noise * edge_noise) * edge_sharpness + 0.5, 0.0, 1.0);
}

void fragment() {
	vec3 pos = v_world_pos;
	vec3 n = normalize(v_world_normal);
	vec4 mask = texture(splat_map, (pos.xz - splat_rect.xy) / splat_rect.zw);
	float fine = texture(macro_noise, pos.xz * 0.21).r - 0.5;
	float macro = texture(macro_noise, pos.xz * macro_scale).r;

	vec3 albedo;
	float rough;
	vec3 normal;
	planar(grass_albedo, grass_normal, grass_rough, grass_tile, grass_tint, pos, n, albedo, rough, normal);

	vec3 a;
	float r;
	vec3 nn;
	float w_moss = edge(mask.b, fine);
	if (w_moss > 0.001) {
		planar(moss_albedo, moss_normal, moss_rough, moss_tile, moss_tint, pos, n, a, r, nn);
		albedo = mix(albedo, a, w_moss);
		rough = mix(rough, r, w_moss);
		normal = normalize(mix(normal, nn, w_moss));
	}
	float w_dirt = edge(mask.r, fine);
	if (w_dirt > 0.001) {
		planar(dirt_albedo, dirt_normal, dirt_rough, dirt_tile, dirt_tint, pos, n, a, r, nn);
		albedo = mix(albedo, a, w_dirt);
		rough = mix(rough, r, w_dirt);
		normal = normalize(mix(normal, nn, w_dirt));
	}
	float w_paving = edge(mask.g, fine * 0.5);
	if (w_paving > 0.001) {
		planar(paving_albedo, paving_normal, paving_rough, paving_tile, paving_tint, pos, n, a, r, nn);
		albedo = mix(albedo, a, w_paving);
		rough = mix(rough, r, w_paving);
		normal = normalize(mix(normal, nn, w_paving));
	}
	float bed = smoothstep(bed_top, bed_bottom, pos.y);
	float slope = smoothstep(slope_start, slope_end, n.y);
	float w_rock = max(max(edge(mask.a, fine), slope), bed);
	if (w_rock > 0.001) {
		triplanar(rock_albedo, rock_normal, rock_rough, rock_tile, rock_tint, pos, n, a, r, nn);
		albedo = mix(albedo, a, w_rock);
		rough = mix(rough, r, w_rock);
		normal = normalize(mix(normal, nn, w_rock));
	}

	albedo *= mix(1.0 - macro_strength, 1.0 + macro_strength * 0.5, macro);
	albedo *= 1.0 - wet_darken * bed;
	float luma = dot(albedo, vec3(0.299, 0.587, 0.114));
	ALBEDO = mix(vec3(luma), albedo, saturation) * brightness;
	ROUGHNESS = mix(rough, 0.25, bed * 0.6);
	NORMAL = normalize((VIEW_MATRIX * vec4(normal, 0.0)).xyz);
}
