shader_type spatial;
render_mode unshaded;

// CRT screen static effect shader
// Creates animated noise with scanlines for retro computer terminals

uniform sampler2D noise_texture : hint_default_white;
uniform float speed : hint_range(0.0, 50.0) = 15.0;
uniform float intensity : hint_range(0.0, 1.0) = 0.8;
uniform vec3 tint : source_color = vec3(0.2, 1.0, 0.3);
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float flicker : hint_range(0.0, 1.0) = 0.05;

// Simple hash function for noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;

    // Animated noise scrolling
    uv.y += TIME * speed;

    // Sample noise texture or generate procedural noise
    float noise = texture(noise_texture, fract(uv)).r;

    // Add some procedural variation
    float proc_noise = hash(UV * 100.0 + TIME * 10.0);
    noise = mix(noise, proc_noise, 0.3);

    // Scanlines effect
    float scanline = sin(UV.y * 800.0) * scanline_intensity + (1.0 - scanline_intensity);

    // Random flicker
    float flicker_val = 1.0 - flicker * hash(vec2(TIME * 50.0, 0.0));

    // Combine effects
    float final_intensity = noise * scanline * intensity * flicker_val;

    // Apply tint color
    vec3 color = tint * final_intensity;

    ALBEDO = color;
    EMISSION = color * 2.0;
}
