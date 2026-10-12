shader_type canvas_item;
// Texto com gradiente horizontal de 3 paradas (F51: "DUELO 1v1" do prototipo, bg-clip-text).
// O contorno preto do Theme fica preto; so o preenchimento do glifo recebe o gradiente.

// Largura do Label em px, mantida pela HeroSelect.
uniform float width = 200.0;
uniform vec4 color_a : source_color = vec4(0.576, 0.8, 1.0, 1.0);
uniform vec4 color_b : source_color = vec4(1.0, 0.757, 0.455, 1.0);
uniform vec4 color_c : source_color = vec4(0.961, 0.62, 0.043, 1.0);

varying float local_x;

void vertex() {
	local_x = VERTEX.x;
}

void fragment() {
	vec4 glyph = texture(TEXTURE, UV) * COLOR;
	float t = clamp(local_x / width, 0.0, 1.0);
	vec3 grad = t < 0.5 ? mix(color_a.rgb, color_b.rgb, t * 2.0) : mix(color_b.rgb, color_c.rgb, t * 2.0 - 1.0);
	// Contorno: cor de vertice preta (UiTokens.OUTLINE); preenchimento: cor clara do Theme.
	float fill = step(0.05, max(COLOR.r, max(COLOR.g, COLOR.b)));
	COLOR = vec4(mix(glyph.rgb, grad, fill), glyph.a);
}
