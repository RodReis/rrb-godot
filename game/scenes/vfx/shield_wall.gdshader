shader_type spatial;
// Muralha do Cavaleiro (F41): borda em fresnel na cor da spec (0.2, 0.6, 1.0, 0.7) e favo sutil.
// Malha = esfera de raio 0,5 achatada no tamanho do ShieldBlocker (KnightVfx). Aditivo: brilha
// pelo glow do F38 (threshold 1,05) com energy > 1.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 rim_color : source_color = vec4(0.2, 0.6, 1.0, 0.7);
uniform float rim_power = 2.2;
uniform float energy = 2.4;
uniform float hex_scale = 7.0;
uniform float hex_strength = 0.22;
uniform float pulse_speed = 4.0;

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

// Distancia ao centro da celula hexagonal (0 no centro, 0,5 na borda).
float hex_edge(vec2 p) {
	const vec2 s = vec2(1.0, 1.7320508);
	vec4 cells = floor(vec4(p, p - vec2(0.5, 1.0)) / s.xyxy) + 0.5;
	vec4 offs = vec4(p - cells.xy * s, p - (cells.zw + 0.5) * s);
	vec2 h = dot(offs.xy, offs.xy) < dot(offs.zw, offs.zw) ? offs.xy : offs.zw;
	h = abs(h);
	return max(dot(h, s * 0.5), h.x);
}

void fragment() {
	float fresnel = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), rim_power);
	float hex = smoothstep(0.42, 0.5, hex_edge(local_pos.xy * hex_scale)) * hex_strength;
	float pulse = 0.85 + 0.15 * sin(TIME * pulse_speed + local_pos.y * 6.0);
	float a = clamp(fresnel + hex, 0.0, 1.0) * rim_color.a * pulse;
	ALBEDO = rim_color.rgb * energy * a;
	ALPHA = a;
}
