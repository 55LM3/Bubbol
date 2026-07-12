shader_type canvas_item;

uniform float scroll_speed_x = 1.0;
uniform float scroll_speed_y = 1.0;

varying vec4 modulate_color;

void vertex() {
    modulate_color = COLOR;
}

void fragment() {
    vec2 shifted_uv = UV;
    
    shifted_uv.x -= TIME * scroll_speed_x;
    shifted_uv.y += TIME * scroll_speed_y;
    
    COLOR = texture(TEXTURE, shifted_uv) * modulate_color;
}
