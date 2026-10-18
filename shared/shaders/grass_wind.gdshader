shader_type spatial;
// Grama decorativa (F42): tufos de MultiMesh com vento. A fase vem da posicao de mundo do tufo
// (origem da instancia em MODEL_MATRIX[3]); fase por VERTEX local deixaria todos os tufos em
// sincronia (errata do guia). UV.y = altura na folha (0 base, 1 ponta): peso da curva e da cor.
render_mode cull_disabled;

// Base no tom do chao de grama do terreno; ponta um pouco mais clara. O mato alto (F32) e mais
// claro e amarelado e 3x mais alto: a grama nunca chega nele.
uniform vec3 base_color : source_color = vec3(0.11, 0.16, 0.07);
uniform vec3 tip_color : source_color = vec3(0.3, 0.4, 0.17);
// Tufos secos espalhados (fracao das instancias) quebram o verde uniforme.
uniform vec3 dry_color : source_color = vec3(0.36, 0.33, 0.16);
uniform float dry_amount : hint_range(0.0, 1.0) = 0.2;
uniform vec2 wind_direction = vec2(0.8, 0.6);
// Deslocamento da ponta (u) e ondas por unidade de mundo.
uniform float wind_strength = 0.09;
uniform float wind_speed = 1.6;
uniform float wind_scale = 0.35;
// Rajadas: faixas lentas atravessadas ao vento.
uniform float gust_scale = 0.05;
// Fade por distancia da camera (F73): o tufo encolhe ate sumir entre fade_start e fade_end (u).
// Escala em vez de alpha: sem transparencia, sem ordenacao e o vertice degenerado nao rasteriza.
uniform float fade_start = 30.0;
uniform float fade_end = 38.0;

varying float tip;
varying float tint;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	VERTEX *= 1.0 - smoothstep(fade_start, fade_end, distance(origin, CAMERA_POSITION_WORLD));
	tip = UV.y;
	tint = hash(origin.xz);
	vec2 dir = normalize(wind_direction);
	float phase = dot(origin.xz, dir) * wind_scale - TIME * wind_speed + tint * 1.3;
	float across = dot(origin.xz, vec2(-dir.y, dir.x));
	float gust = 0.6 + 0.4 * sin(across * gust_scale + TIME * 0.4);
	float sway = (sin(phase) * 0.7 + sin(phase * 2.3 + tint * 6.28) * 0.3) * wind_strength * gust;
	float bend = UV.y * UV.y;
	vec3 offset = vec3(dir.x * sway, -abs(sway) * 0.3, dir.y * sway) * bend;
	// Vento em mundo -> espaco do tufo (rotacao + escala uniforme: inversa = transposta / s^2).
	mat3 basis = mat3(MODEL_MATRIX);
	VERTEX += transpose(basis) * offset / dot(basis[0], basis[0]);
}

void fragment() {
	vec3 top = mix(tip_color, dry_color, step(1.0 - dry_amount, tint) * 0.7);
	ALBEDO = mix(base_color, top, smoothstep(0.0, 1.0, tip)) * (0.85 + 0.3 * tint);
	ROUGHNESS = 0.9;
	SPECULAR = 0.1;
	AO = mix(0.6, 1.0, tip);
	// Normal para cima nas duas faces: com cull_disabled a face de tras viria invertida (escura).
	NORMAL = (VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
}
