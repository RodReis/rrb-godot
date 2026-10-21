// Mato alto por cartoes de lamina (F95, ADR-0030) com abertura para o heroi de quem joga (F72,
// ADR-0015 item 10). Cada lamina e um cartao (art/arena/build_world_kit.py, Blades): o formato
// (ponta afinando) e o degrade da raiz escura a ponta clara saem do UV, sem textura. A malha traz na
// cor de vertice a variacao de tom por touceira (rgb) e o peso do balanco no alpha (0 no pe, 1 na
// ponta). Dentro de reveal_radius do heroi a moita vira semitransparente, com borda macia: so o
// cliente liga a abertura (HeroVisual); com reveal_radius 0 a moita e opaca. O mesmo shader serve
// aos juncos da margem do rio (material proprio, sem abertura).
shader_type spatial;
// ALPHA joga o material no pipeline transparente. O prepasse escreve a profundidade so do que e
// opaco: fora da abertura as laminas continuam se ocultando entre si, sem ordenar por malha.
render_mode diffuse_burley, specular_schlick_ggx, cull_disabled, depth_prepass_alpha;

uniform vec3 root_color : source_color = vec3(0.07, 0.17, 0.05);
uniform vec3 tip_color : source_color = vec3(0.45, 0.6, 0.2);
// Expoente do degrade (menor = a ponta clara domina a lamina).
uniform float gradient_power : hint_range(0.2, 3.0) = 0.9;
uniform float roughness : hint_range(0.0, 1.0) = 0.8;
uniform float specular_amount : hint_range(0.0, 1.0) = 0.2;
// Luz que atravessa a lamina no contraluz (fracao do albedo).
uniform float backlight_amount : hint_range(0.0, 1.0) = 0.3;

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
// Mesma direcao e fase de mundo da folhagem (foliage_wind); so o visual: a caixa da moita
// (SPEC-007), a abertura e a silhueta (SPEC-072) nao mudam.
uniform vec2 wind_direction = vec2(0.8, 0.6);
// Deslocamento maximo na ponta (u).
uniform float wind_strength : hint_range(0.0, 0.5) = 0.12;
uniform float wind_speed = 1.1;
uniform float wind_scale = 0.25;
// Altura (u) onde o peso do balanco chega a 1 (a malha ja traz o peso no alpha; vale so sem ele).
uniform float sway_height = 1.2;
// Ondulacao fina ao longo da moita (u) e a frequencia dela.
uniform float ripple : hint_range(0.0, 0.2) = 0.04;
uniform float ripple_speed = 3.0;

varying vec3 v_world_pos;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 origin = MODEL_MATRIX[3].xyz;
	float weight = COLOR.a;
	vec2 dir = normalize(wind_direction);
	float phase = dot(origin.xz, dir) * wind_scale - TIME * wind_speed;
	float gust = 0.65 + 0.35 * sin(TIME * 0.37 + origin.x * 0.11);
	float sway = (sin(phase) * 0.7 + sin(phase * 2.1 + 1.3) * 0.3) * wind_strength * gust;
	float wave = sin(TIME * ripple_speed + dot(world.xz, vec2(2.3, 1.7))) * ripple;
	vec3 offset = vec3(dir.x * (sway + wave), -abs(sway) * 0.3, dir.y * (sway + wave)) * weight;
	VERTEX += (inverse(MODEL_MATRIX) * vec4(offset, 0.0)).xyz;
	v_world_pos = world + offset;
}

void fragment() {
	float v = clamp(UV.y, 0.0, 1.0);
	float u = abs(UV.x * 2.0 - 1.0);
	// Lamina: larga no pe, afinando ate a ponta (borda suavizada para o recorte nao serrilhar).
	float half_width = 1.0 - pow(v, 1.5) * 0.97;
	float mask = 1.0 - smoothstep(half_width - 0.16, half_width, u);
	if (mask < 0.04) {
		discard;
	}
	// Nervura central mais escura.
	float rib = 1.0 - 0.22 * exp(-u * u * 18.0);
	vec3 base = mix(root_color, tip_color, pow(v, gradient_power));
	ALBEDO = base * COLOR.rgb * rib;
	ROUGHNESS = roughness;
	SPECULAR = specular_amount;
	BACKLIGHT = ALBEDO * backlight_amount;
	// Cartao dos dois lados: devolve a normal de cima (o Godot a inverte nas costas).
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	// Com reveal_radius 0 a distancia (>= 0) nunca passa de edge1 = 0: alpha 1 em todo lugar.
	float d = distance(v_world_pos.xz, hero_pos.xz);
	float reveal = mix(reveal_alpha, 1.0, smoothstep(reveal_radius - reveal_edge, reveal_radius, d));
	ALPHA = mask * reveal;
}
