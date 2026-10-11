// Cenario fixo realista (F40, PI 2026-10-11: realista e sombrio): castelo, rochas, pontes,
// ilhotas. Textura PBR CC0 em triplanar de mundo (os kits tem UV de atlas e muralhas esticadas
// em x; o UV2 e do LightmapGI), musgo nas faces voltadas para cima e a cor da celula do atlas
// KayKit como matiz: madeira continua marrom e telhado continua escuro, com o detalhe da
// textura real por cima.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D base_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D base_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D base_rough : hint_roughness_gray, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float base_tile = 0.35;
uniform vec3 base_tint : source_color = vec3(1.0);
// Folhagem e fosca: piso da rugosidade e especular reduzido (sem brilho de "neve" no sol baixo).
uniform float min_roughness : hint_range(0.0, 1.0) = 0.0;
uniform float specular_amount : hint_range(0.0, 1.0) = 0.5;

group_uniforms moss;
uniform sampler2D moss_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D moss_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float moss_tile = 0.3;
uniform vec3 moss_tint : source_color = vec3(1.0);
// Faces com normal.y acima de moss_from ganham musgo; moss_amount 0 desliga.
uniform float moss_from : hint_range(0.0, 1.0) = 0.7;
uniform float moss_amount : hint_range(0.0, 1.0) = 0.8;

group_uniforms atlas;
// Atlas KayKit no UV do kit: a cor da celula entra como matiz (0 = so a textura).
uniform sampler2D atlas : source_color, filter_nearest, repeat_disable;
uniform float atlas_tint : hint_range(0.0, 1.0) = 0.0;
// Cor linear da celula que nao muda a textura (cinza da pedra do atlas).
uniform float atlas_reference = 0.3;

group_uniforms grade;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

vec3 unpack_normal(vec4 texel) {
	// So x/y: com import de normal map (BC5) o canal z nao vem; reconstroi.
	vec2 t = texel.rg * 2.0 - 1.0;
	return vec3(t.x, -t.y, sqrt(clamp(1.0 - dot(t, t), 0.0, 1.0)));
}

vec3 tri_color(sampler2D tex, vec2 ux, vec2 uy, vec2 uz, vec3 w) {
	return texture(tex, ux).rgb * w.x + texture(tex, uy).rgb * w.y + texture(tex, uz).rgb * w.z;
}

vec3 tri_normal(sampler2D tex, vec2 ux, vec2 uy, vec2 uz, vec3 w, vec3 n) {
	vec3 tx = unpack_normal(texture(tex, ux));
	vec3 ty = unpack_normal(texture(tex, uy));
	vec3 tz = unpack_normal(texture(tex, uz));
	tx = vec3(tx.xy + n.zy, abs(tx.z) * n.x);
	ty = vec3(ty.xy + n.xz, abs(ty.z) * n.y);
	tz = vec3(tz.xy + n.xy, abs(tz.z) * n.z);
	return normalize(tx.zyx * w.x + ty.xzy * w.y + tz.xyz * w.z);
}

void fragment() {
	vec3 pos = v_world_pos;
	vec3 n = normalize(v_world_normal);
	vec3 w = pow(abs(n), vec3(4.0));
	w /= w.x + w.y + w.z;
	vec2 ux = pos.zy * base_tile;
	vec2 uy = pos.xz * base_tile;
	vec2 uz = pos.xy * base_tile;
	vec3 albedo = tri_color(base_albedo, ux, uy, uz, w) * base_tint;
	float rough = (
		texture(base_rough, ux).r * w.x + texture(base_rough, uy).r * w.y
		+ texture(base_rough, uz).r * w.z
	);
	vec3 normal = tri_normal(base_normal, ux, uy, uz, w, n);
	if (atlas_tint > 0.0) {
		vec3 cell = texture(atlas, UV).rgb;
		// Relativo ao cinza da pedra: pedra fica como a textura, madeira escurece em marrom.
		albedo *= mix(vec3(1.0), cell / atlas_reference, atlas_tint);
	}
	// Faixa de 0,2 acima de moss_from (smoothstep com bordas iguais e indefinido no GLSL).
	float moss_w = moss_amount > 0.0 ? smoothstep(moss_from, moss_from + 0.2, n.y) * moss_amount : 0.0;
	if (moss_w > 0.001) {
		vec2 mx = pos.zy * moss_tile;
		vec2 my = pos.xz * moss_tile;
		vec2 mz = pos.xy * moss_tile;
		albedo = mix(albedo, tri_color(moss_albedo, mx, my, mz, w) * moss_tint, moss_w);
		normal = normalize(mix(normal, tri_normal(moss_normal, mx, my, mz, w, n), moss_w));
		rough = mix(rough, 0.9, moss_w);
	}
	float luma = dot(albedo, vec3(0.299, 0.587, 0.114));
	ALBEDO = mix(vec3(luma), albedo, saturation) * brightness;
	ROUGHNESS = max(rough, min_roughness);
	SPECULAR = specular_amount;
	NORMAL = normalize((VIEW_MATRIX * vec4(normal, 0.0)).xyz);
}
