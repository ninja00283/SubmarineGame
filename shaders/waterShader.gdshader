shader_type canvas_item;

uniform sampler2D noiseMapX : source_color;
uniform sampler2D noiseMapY : source_color;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float time : hint_range(0.0, 10.0);
uniform float offsetMultiplier : hint_range(0.0, 1.0);

void fragment() {
    vec2 uv = SCREEN_UV;

    // Scroll the noise maps based on time
    vec2 offsetX = vec2(time, 0.0);
    vec2 offsetY = vec2(0.0, time);

    float noiseX = texture(noiseMapX, fract(uv + offsetX)).r;
    float noiseY = texture(noiseMapY, fract(uv + offsetY)).r;

    // Displace the UVs based on the noise values
    uv.x += noiseX * offsetMultiplier;
    uv.y += noiseY * offsetMultiplier;

    // Fetch the color from the screen texture with the displaced UVs
    COLOR = texture(SCREEN_TEXTURE, uv);
}
