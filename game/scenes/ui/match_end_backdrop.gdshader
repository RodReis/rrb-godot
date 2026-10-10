shader_type canvas_item;
// Fundo da tela de fim (F18, DV tela 7): a arena (frame ao vivo) atras, escurecida para o centro
// ficar legivel e mais escura nas bordas (gradiente radial); na derrota perde a cor.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(0.043, 0.075, 0.149, 1.0);
// Quanto do tint cobre o centro e as bordas.
uniform float center_cover : hint_range(0.0, 1.0) = 0.8;
uniform float edge_cover : hint_range(0.0, 1.0) = 0.95;
// 0 = cor da arena, 1 = cinza.
uniform float desaturate : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 scene = texture(screen_texture, SCREEN_UV).rgb;
	float gray = dot(scene, vec3(0.299, 0.587, 0.114));
	scene = mix(scene, vec3(gray), desaturate);
	float edge = smoothstep(0.2, 0.75, distance(UV, vec2(0.5)));
	COLOR = vec4(mix(scene, tint.rgb, mix(center_cover, edge_cover, edge)), 1.0);
}
