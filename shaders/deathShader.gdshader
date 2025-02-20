shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec4 pixelColor = texture(SCREEN_TEXTURE, SCREEN_UV);
    if (pixelColor.r > 0.5 || (pixelColor.g >= 0.5 && pixelColor.b >= 0.5) || pixelColor.r >= pixelColor.g + pixelColor.b / 2.0) {
        COLOR = vec4(0.973, 0.094, 0.094, 1.0);
    } else {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	}
}