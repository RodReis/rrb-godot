// Ceu do abismo cosmico (F40): espaco profundo com nebulosas (fbm de value noise sobre a
// direcao do olhar) e estrelas em grade por hash, com cintilacao leve. O degrade sozinho nao
// entrega a imagem de referencia (errata do bloco visual).
// F49 (ciclo dia/noite): day_amount mistura esse ceu da noite (0, identico ao do F40) com o do
// dia (1): gradiente azul, disco do sol na direcao sun_direction, bruma clara no horizonte e o
// abismo clareado. DayNight (cliente) anima os dois uniforms pelo relogio da partida.
shader_type sky;

uniform vec3 space_color : source_color = vec3(0.02, 0.015, 0.06);
uniform vec3 nebula_purple : source_color = vec3(0.28, 0.08, 0.4);
uniform vec3 nebula_cyan : source_color = vec3(0.05, 0.25, 0.35);
uniform vec3 abyss_glow : source_color = vec3(0.12, 0.04, 0.18);
uniform float star_density : hint_range(0.9, 1.0) = 0.994;
uniform float star_brightness : hint_range(0.0, 4.0) = 1.6;
uniform float star_grid = 160.0;

// Dia (F49). day_amount: 0 = noite, 1 = dia. sun_direction: para onde olhar para ver o sol.
uniform float day_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 sun_direction = vec3(0.4, 0.6, 0.3);
uniform vec3 day_zenith : source_color = vec3(0.08, 0.3, 0.78);
uniform vec3 day_horizon : source_color = vec3(0.62, 0.78, 0.95);
uniform vec3 day_abyss : source_color = vec3(0.3, 0.4, 0.62);
uniform vec3 sun_disc_color : source_color = vec3(1.0, 0.93, 0.78);
uniform vec3 dusk_tint : source_color = vec3(1.0, 0.45, 0.2);
// Cosseno do raio angular do disco (nucleo e borda) e expoente do brilho em volta.
uniform float sun_disc_inner = 0.99975;
uniform float sun_disc_outer = 0.9993;
uniform float sun_halo_power = 48.0;

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

vec3 night_sky(vec3 dir) {
	float neb1 = fbm(dir * 3.0 + vec3(1.7, 0.3, 4.1));
	float neb2 = fbm(dir * 5.0 + vec3(9.2, 3.3, 0.7));
	vec3 color = space_color;
	color += nebula_purple * smoothstep(0.42, 0.78, neb1) * 0.9;
	color += nebula_cyan * smoothstep(0.48, 0.85, neb2) * 0.8;
	// Brilho difuso vindo de baixo: o abismo sob a ilha nao e preto chapado.
	color += abyss_glow * smoothstep(-0.1, -0.9, dir.y);

	// Estrelas em grade por face de cubo (projecao pelo eixo dominante): celulas uniformes em
	// toda direcao; a grade direta sobre dir vira riscos perto do horizonte.
	vec3 a = abs(dir);
	vec2 face_uv;
	float face_id;
	if (a.x >= a.y && a.x >= a.z) {
		face_uv = dir.yz / a.x;
		face_id = dir.x > 0.0 ? 0.0 : 1.0;
	} else if (a.y >= a.z) {
		face_uv = dir.xz / a.y;
		face_id = dir.y > 0.0 ? 2.0 : 3.0;
	} else {
		face_uv = dir.xy / a.z;
		face_id = dir.z > 0.0 ? 4.0 : 5.0;
	}
	vec2 grid_uv = face_uv * star_grid * 0.5;
	float h = hash3(vec3(floor(grid_uv), face_id));
	float dist = length(fract(grid_uv) - 0.5);
	float star = step(star_density, h) * smoothstep(0.32, 0.04, dist);
	float twinkle = 0.7 + 0.3 * sin(TIME * 2.0 + h * 50.0);
	color += vec3(star * star_brightness * twinkle * (0.6 + 0.4 * h));
	return color;
}

vec3 day_sky(vec3 dir) {
	// Gradiente: horizonte claro -> zenite azul; abaixo do horizonte, o abismo clareado.
	float above = smoothstep(-0.04, 0.04, dir.y);
	vec3 up_color = mix(day_horizon, day_zenith, pow(clamp(dir.y, 0.0, 1.0), 0.5));
	vec3 down_color = mix(day_horizon, day_abyss, smoothstep(0.0, -0.8, dir.y));
	vec3 color = mix(down_color, up_color, above);

	vec3 sun_dir = normalize(sun_direction);
	float cos_sun = dot(dir, sun_dir);
	// Halo, disco (acima do horizonte) e luz quente do entardecer perto do sol.
	float dusk = 4.0 * day_amount * (1.0 - day_amount);
	color += sun_disc_color * pow(max(cos_sun, 0.0), sun_halo_power) * 0.35;
	color += dusk_tint * dusk * pow(max(cos_sun, 0.0), 4.0) * 0.6;
	color = mix(color, sun_disc_color * 6.0, smoothstep(sun_disc_outer, sun_disc_inner, cos_sun) * above);
	return color;
}

void sky() {
	vec3 dir = EYEDIR;
	vec3 color = vec3(0.0);
	if (day_amount < 1.0) {
		color = night_sky(dir);
	}
	if (day_amount > 0.0) {
		color = mix(color, day_sky(dir), day_amount);
	}
	COLOR = color;
}
