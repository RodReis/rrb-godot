shader_type spatial;
// Fantasma do Rolamento (F41): silhueta translucida com borda em fresnel. O GhostVfx apaga pela
// transparency do GeometryInstance3D em 0,2 s.
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled;

uniform vec4 color : source_color = vec4(0.45, 0.85, 1.0, 1.0);
uniform float energy = 1.6;
uniform float rim_power = 1.5;

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	ALBEDO = color.rgb * energy * (0.25 + fresnel);
	ALPHA = color.a * (0.35 + 0.65 * fresnel);
}
