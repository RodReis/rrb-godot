// Degrade dourado vertical do wordmark "LOOT START" (F82, ADR-0022), o mesmo do site:
// linear-gradient(180deg, GOLD_BRIGHT 20%, GOLD 80%) recortado no texto.
shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(1.0, 0.757, 0.455, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.961, 0.62, 0.043, 1.0);
// Altura do Label em px (atualizada no resized); o degrade corre de 0 a height.
uniform float height = 1.0;

varying float local_y;

void vertex() {
	local_y = VERTEX.y;
}

void fragment() {
	float t = smoothstep(0.2, 0.8, local_y / max(height, 1.0));
	COLOR.rgb = mix(top_color.rgb, bottom_color.rgb, t);
}
