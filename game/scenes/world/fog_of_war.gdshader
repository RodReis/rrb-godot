// Neblina de guerra (F37, CONVENTION 4.9): passe de tela num quad 2x2 (material_override do FogOfWar).
// Reconstroi a posicao de mundo pela profundidade e escurece o que esta fora do raio de visao do heroi:
// nunca visto = cor lisa; ja visto = cena dessaturada e escura; dentro do raio = cena intacta.
// Serve para a camera em perspectiva e para a ortografica do minimapa (so usa as matrizes inversas).
// Reversed-Z (Godot 4.3+, Forward+): profundidade 1 = plano proximo, 0 = infinito/sem geometria.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled, shadows_disabled, fog_disabled, blend_mix;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
// R8 quadrada: 0 nunca visto, 1 ja visto. UV (0,0) = mundo (-map_extent, -map_extent); u segue +x, v segue +z.
uniform sampler2D explored_mask : filter_linear, repeat_disable;
uniform float map_extent = 40.0;
uniform vec2 viewer_xz = vec2(0.0);
uniform float vision_radius = 12.0;
uniform float edge_softness = 1.5;
uniform vec4 unexplored_color : source_color = vec4(0.02, 0.025, 0.04, 1.0);
uniform float explored_saturation : hint_range(0.0, 1.0) = 0.0;
uniform float explored_brightness : hint_range(0.0, 1.0) = 0.55;

void vertex() {
	// Quad cobre a tela inteira, ignorando camera. z = 1.0 (plano proximo em reversed-Z).
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).r;

	// NDC -> view -> mundo. O /w serve a perspectiva (w variavel) e a ortografica (w = 1).
	vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	view.xyz /= view.w;
	vec2 world_xz = (INV_VIEW_MATRIX * vec4(view.xyz, 1.0)).xz;

	// 1 dentro do raio, caindo suave nos ultimos edge_softness u.
	float soft = max(edge_softness, 0.001);
	float visible = 1.0 - smoothstep(vision_radius - soft, vision_radius, distance(world_xz, viewer_xz));

	// Fora da mascara = nunca visto (a amostra com clamp repetiria a borda).
	vec2 uv = (world_xz + vec2(map_extent)) / (2.0 * map_extent);
	vec2 inside = step(vec2(0.0), uv) * step(uv, vec2(1.0));
	float explored = texture(explored_mask, uv).r * inside.x * inside.y;

	vec3 screen = texture(screen_texture, SCREEN_UV).rgb;
	float luma = dot(screen, vec3(0.2126, 0.7152, 0.0722));
	vec3 gray = mix(vec3(luma), screen, explored_saturation) * explored_brightness;

	ALBEDO = mix(unexplored_color.rgb, gray, explored);
	// Sem geometria (ceu/fundo): depth == 0 em reversed-Z -> alpha 0, nao mexe.
	ALPHA = (1.0 - visible) * step(0.0000001, depth);
}
