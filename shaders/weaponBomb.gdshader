shader_type canvas_item;

uniform vec4 col : source_color;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if(tex.a >= 0.1){COLOR = tex + col;}
	
}