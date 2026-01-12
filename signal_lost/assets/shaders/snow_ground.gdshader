shader_type spatial;

// Snow ground shader with sparkle effect
// PBR-based with subsurface scattering approximation

uniform sampler2D albedo_texture : source_color, hint_default_white;
uniform sampler2D normal_texture : hint_normal;
uniform sampler2D roughness_texture : hint_default_white;
uniform sampler2D ao_texture : hint_default_white;

uniform float snow_sparkle : hint_range(0.0, 1.0) = 0.3;
uniform float sparkle_scale : hint_range(10.0, 500.0) = 100.0;
uniform float sparkle_threshold : hint_range(0.9, 0.999) = 0.98;

uniform vec3 snow_tint : source_color = vec3(0.95, 0.97, 1.0);
uniform float uv_scale : hint_range(0.1, 10.0) = 1.0;

// Subsurface scattering approximation
uniform float subsurface_strength : hint_range(0.0, 1.0) = 0.2;
uniform vec3 subsurface_color : source_color = vec3(0.6, 0.8, 1.0);

// Hash function for sparkle
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV * uv_scale;

    // Sample textures
    vec3 albedo = texture(albedo_texture, uv).rgb * snow_tint;
    vec3 normal_map = texture(normal_texture, uv).rgb;
    float roughness = texture(roughness_texture, uv).r;
    float ao = texture(ao_texture, uv).r;

    // Calculate sparkle effect (snow crystals catching light)
    float sparkle = hash(UV * sparkle_scale);
    sparkle = step(sparkle_threshold, sparkle) * snow_sparkle;

    // View-dependent sparkle (only visible at certain angles)
    float view_sparkle = sparkle * pow(max(0.0, dot(NORMAL, VIEW)), 2.0);

    // Apply materials
    ALBEDO = albedo;
    NORMAL_MAP = normal_map;
    ROUGHNESS = roughness;
    AO = ao;

    // Emission for sparkle effect
    EMISSION = vec3(view_sparkle) * 2.0;

    // Subsurface scattering approximation
    // This simulates light scattering through snow
    BACKLIGHT = subsurface_color * subsurface_strength;
}
