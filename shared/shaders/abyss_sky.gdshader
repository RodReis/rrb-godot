// Ceu do abismo cosmico (F40): espaco profundo com nebulosas (fbm de value noise sobre a
// direcao do olhar) e estrelas em grade por hash, com cintilacao leve. O degrade sozinho nao
// entrega a imagem de referencia (errata do bloco visual).
shader_type sky;

uniform vec3 space_color : source_color = vec3(0.02, 0.015, 0.06);
uniform vec3 nebula_purple : source_color = vec3(0.28, 0.08, 0.4);
uniform vec3 nebula_cyan : source_color = vec3(0.05, 0.25, 0.35);
uniform vec3 abyss_glow : source_color = vec3(0.12, 0.04, 0.18);
uniform float star_density : hint_range(0.9, 1.0) = 0.994;
uniform float star_brightness : hint_range(0.0, 4.0) = 1.6;
uniform float star_grid = 160.0;

float hash3(vec3 p) {
	p = fract(p * vec3(443.897, 441.423, 437.195));
	p += dot(p, p.yzx + 19.19);
	return fract((p.x + p.y) * p.z);
}

float value_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash3(i);
	float n100 = hash3(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash3(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash3(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash3(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash3(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash3(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash3(i + vec3(1.0, 1.0, 1.0));
	float x00 = mix(n000, n100, f.x);
	float x10 = mix(n010, n110, f.x);
	float x01 = mix(n001, n101, f.x);
	float x11 = mix(n011, n111, f.x);
	return mix(mix(x00, x10, f.y), mix(x01, x11, f.y), f.z);
}

float fbm(vec3 p) {
	float total = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		total += value_noise(p) * amplitude;
		p = p * 2.1 + vec3(3.7, 1.3, 5.9);
		amplitude *= 0.5;
	}
	return total;
}

void sky() {
	vec3 dir = EYEDIR;
	float neb1 = fbm(dir * 3.0 + vec3(1.7, 0.3, 4.1));
	float neb2 = fbm(dir * 5.0 + vec3(9.2, 3.3, 0.7));
	vec3 color = space_color;
	color += nebula_purple * smoothstep(0.42, 0.78, neb1) * 0.9;
	color += nebula_cyan * smoothstep(0.48, 0.85, neb2) * 0.8;
	// Brilho difuso vindo de baixo: o abismo sob a ilha nao e preto chapado.
	color += abyss_glow * smoothstep(-0.1, -0.9, dir.y);

	vec3 cell = floor(dir * star_grid);
	float h = hash3(cell);
	float dist = length(fract(dir * star_grid) - 0.5);
	float star = step(star_density, h) * smoothstep(0.32, 0.04, dist);
	float twinkle = 0.7 + 0.3 * sin(TIME * 2.0 + h * 50.0);
	color += vec3(star * star_brightness * twinkle * (0.6 + 0.4 * h));
	COLOR = color;
}
