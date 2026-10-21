// Mato alto (F32, F40) com abertura para o heroi de quem joga (F72, ADR-0015 item 10). Mesma
// receita do triplanar_pbr (textura PBR em triplanar de mundo, matiz da celula do atlas KayKit),
// sem musgo nem preenchimento de ambiente (o mato nao usa), mais a abertura: dentro de
// reveal_radius do heroi a moita vira semitransparente, com borda macia. So o cliente liga a
// abertura (HeroVisual); com reveal_radius 0 a moita e opaca.
shader_type spatial;
// ALPHA joga o material no pipeline transparente. O prepasse escreve a profundidade so do que e
// opaco: fora da abertura os tufos continuam se ocultando entre si, sem ordenar por malha.
render_mode diffuse_burley, specular_schlick_ggx, depth_prepass_alpha;

uniform sampler2D base_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D base_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D base_rough : hint_roughness_gray, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float base_tile = 0.35;
uniform vec3 base_tint : source_color = vec3(1.0);
// Folhagem e fosca: piso da rugosidade e especular reduzido (sem brilho de "neve" no sol baixo).
uniform float min_roughness : hint_range(0.0, 1.0) = 0.0;
uniform float specular_amount : hint_range(0.0, 1.0) = 0.5;

group_uniforms atlas;
// Atlas KayKit no UV do kit: a cor da celula entra como matiz (0 = so a textura).
uniform sampler2D atlas : source_color, filter_nearest, repeat_disable;
uniform float atlas_tint : hint_range(0.0, 1.0) = 0.0;
// Cor linear da celula que nao muda a textura (cinza da pedra do atlas).
uniform float atlas_reference = 0.3;

group_uniforms grade;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;

group_uniforms abertura;
// Posicao do heroi (so x e z contam: a abertura e uma coluna do chao ao topo da moita).
uniform vec3 hero_pos = vec3(0.0);
// Raio da abertura em u; 0 = fechada.
uniform float reveal_radius : hint_range(0.0, 10.0) = 0.0;
// Alpha da moita no centro da abertura.
uniform float reveal_alpha : hint_range(0.0, 1.0) = 0.4;
// Largura da borda macia, de dentro do raio para o centro.
uniform float reveal_edge : hint_range(0.01, 5.0) = 1.0;

group_uniforms vento;
// Balanco de vento (PI 2026-10-20, F94): so o visual; a caixa da moita (SPEC-007), a abertura e a
// silhueta (SPEC-072) nao mudam. Mesma direcao e fase de mundo da folhagem (foliage_wind).
uniform vec2 wind_direction = vec2(0.8, 0.6);
// Deslocamento maximo no topo da moita (u).
uniform float wind_strength : hint_range(0.0, 0.5) = 0.12;
uniform float wind_speed = 1.1;
uniform float wind_scale = 0.25;
// Altura da moita (u) onde o peso do balanco chega a 1; o pe fica preso ao chao.
uniform float sway_height = 1.2;
// Ondulacao fina ao longo da moita (u) e a frequencia dela.
uniform float ripple : hint_range(0.0, 0.2) = 0.04;
uniform float ripple_speed = 3.0;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 origin = MODEL_MATRIX[3].xyz;
	float weight = clamp(VERTEX.y / sway_height, 0.0, 1.0);
	weight *= weight;
	vec2 dir = normalize(wind_direction);
	float phase = dot(origin.xz, dir) * wind_scale - TIME * wind_speed;
	float gust = 0.65 + 0.35 * sin(TIME * 0.37 + origin.x * 0.11);
	float sway = (sin(phase) * 0.7 + sin(phase * 2.1 + 1.3) * 0.3) * wind_strength * gust;
	float wave = sin(TIME * ripple_speed + dot(world.xz, vec2(2.3, 1.7))) * ripple;
	vec3 offset = vec3(dir.x * (sway + wave), -abs(sway) * 0.3, dir.y * (sway + wave)) * weight;
	VERTEX += (inverse(MODEL_MATRIX) * vec4(offset, 0.0)).xyz;
	v_world_pos = world + offset;
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
	float luma = dot(albedo, vec3(0.299, 0.587, 0.114));
	ALBEDO = mix(vec3(luma), albedo, saturation) * brightness;
	ROUGHNESS = max(rough, min_roughness);
	SPECULAR = specular_amount;
	NORMAL = normalize((VIEW_MATRIX * vec4(normal, 0.0)).xyz);
	// Com reveal_radius 0 a distancia (>= 0) nunca passa de edge1 = 0: alpha 1 em todo lugar.
	float d = distance(pos.xz, hero_pos.xz);
	ALPHA = mix(reveal_alpha, 1.0, smoothstep(reveal_radius - reveal_edge, reveal_radius, d));
}
