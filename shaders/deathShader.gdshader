shader_type canvas_item;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform int lineThickness = 3;

void fragment() {
	vec2 texelSize = vec2(1.0) / vec2(textureSize(SCREEN_TEXTURE, 0));
	vec4 center = texture(SCREEN_TEXTURE, SCREEN_UV);
	float centerBrightness = dot(center.rgb, vec3(0.299, 0.587, 0.114));
	bool edgeDetected = false;
	bool centerIsBrightest = true;

	for (int x = -lineThickness; x <= lineThickness; x++) {
		for (int y = -lineThickness; y <= lineThickness; y++) {
			if (x == 0 && y == 0) continue;
			vec2 offset = vec2(float(x), float(y)) * texelSize;
			vec4 neighbor = texture(SCREEN_TEXTURE, SCREEN_UV + offset);
			float neighborBrightness = dot(neighbor.rgb, vec3(0.299, 0.587, 0.114));
			float diff = distance(center.rgb, neighbor.rgb);
			if (diff > 0.2) {
				edgeDetected = true;
				if (neighborBrightness > centerBrightness) centerIsBrightest = false;
			}
		}
	}

	if (edgeDetected) {
		if (centerIsBrightest) {
			COLOR = vec4(1.0, 0.0, 0.0, 1.0);
		} else {
			COLOR = vec4(0.0, 0.0, 0.0, 1.0);
		}
	} else {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	}
}
