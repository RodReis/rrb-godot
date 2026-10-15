// Vidro (backdrop-blur do prototipo, FRONTEND-LAUNCHER §8.2): desenha o que esta atras do
// retangulo, desfocado pelo mipmap da tela, recortado com cantos arredondados. Fica atras do
// fundo semitransparente do cartao (GlassPanel), que tinge o desfoque com a cor do token.
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec2 rect_size = vec2(100.0);
uniform float radius = 8.0;
// Nivel do mipmap: 2 ~ backdrop-blur-md, 3 ~ xl, 4 ~ 2xl.
uniform float blur_lod = 3.0;

float rounded_box(vec2 p, vec2 half_size, float r) {
	vec2 q = abs(p) - half_size + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 p = UV * rect_size - rect_size * 0.5;
	float d = rounded_box(p, rect_size * 0.5, radius);
	float mask = clamp(0.5 - d, 0.0, 1.0);
	COLOR = vec4(textureLod(screen_texture, SCREEN_UV, blur_lod).rgb, mask);
}
