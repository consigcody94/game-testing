shader_type canvas_item;

// Frost overlay effect for cold/temperature anomalies
// Creates ice crystals around screen edges

uniform float frost_amount : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D frost_texture : hint_default_white;
uniform sampler2D screen_texture : hint_screen_texture;
uniform vec3 frost_color : source_color = vec3(0.8, 0.85, 0.95);
uniform float edge_softness : hint_range(0.0, 1.0) = 0.3;

// Noise function for organic frost patterns
float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void fragment() {
    vec4 screen = texture(screen_texture, SCREEN_UV);

    // Distance from center (for edge frost effect)
    vec2 center_offset = UV - 0.5;
    float edge_dist = length(center_offset) * 1.5;

    // Create organic frost pattern
    float frost_pattern = fbm(UV * 10.0 + TIME * 0.1);

    // Edge-based frost mask (thicker at edges)
    float edge_frost = pow(edge_dist, 2.0 - frost_amount);

    // Sample frost texture if available
    float texture_frost = texture(frost_texture, UV * 3.0).r;

    // Combine frost effects
    float frost_mask = clamp(
        edge_frost * frost_amount +
        frost_pattern * frost_amount * 0.3 +
        texture_frost * frost_amount * 0.4,
        0.0, 1.0
    );

    // Add some sparkle/crystalline effect
    float sparkle = step(0.95, noise(UV * 500.0 + TIME)) * frost_amount * 0.3;

    // Blend frost with screen
    vec3 final_color = mix(screen.rgb, frost_color, frost_mask);
    final_color += vec3(sparkle);

    COLOR.rgb = final_color;
    COLOR.a = 1.0;
}
