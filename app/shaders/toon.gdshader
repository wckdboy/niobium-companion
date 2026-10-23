shader_type spatial;
// Niobium cel shader: banded (toon) diffuse + rim, matching the cyberpunk-manga art
// direction (flat cel shading, violet-black surfaces, cyan/acid rim). Engineering-grade.

uniform vec3 base_color : source_color = vec3(0.24, 0.14, 0.34);
uniform float band_steps : hint_range(1.0, 8.0) = 3.0;
uniform float ambient_floor : hint_range(0.0, 0.6) = 0.22;
uniform vec3 rim_color : source_color = vec3(0.25, 0.85, 0.9);
uniform float rim_power : hint_range(0.5, 8.0) = 2.5;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.55;

void light() {
	float ndotl = dot(NORMAL, LIGHT);
	float band = floor(clamp(ndotl, 0.0, 1.0) * band_steps) / band_steps;
	float lit = ambient_floor + (1.0 - ambient_floor) * band;
	DIFFUSE_LIGHT += base_color * lit * ATTENUATION * LIGHT_COLOR;
}

void fragment() {
	ALBEDO = base_color;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	float rim = 1.0 - dot(NORMAL, VIEW);
	rim = pow(clamp(rim, 0.0, 1.0), rim_power);
	EMISSION = rim_color * rim * rim_strength;
}
