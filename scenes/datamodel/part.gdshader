shader_type spatial;
// CRITICAL FLAG: "world_vertex_coords" forces Godot to bypass the parent's scale matrix entirely
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, world_vertex_coords;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 texture_scale = vec3(1.0, 1.0, 1.0);

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
    // Because of world_vertex_coords, VERTEX is now natively in true world space meter units
    world_position = VERTEX;
    world_normal = abs(NORMAL);
}

void fragment() {
    // Standard triplanar blending math
    vec3 blend_weights = world_normal / (world_normal.x + world_normal.y + world_normal.z);
    
    // Scale the absolute global position
    vec3 scaled_pos = world_position / texture_scale;
    
    // Project texture maps from all 3 directions
    vec4 tex_x = texture(albedo_texture, scaled_pos.zy);
    vec4 tex_y = texture(albedo_texture, scaled_pos.xz);
    vec4 tex_z = texture(albedo_texture, scaled_pos.xy);
    
    // Combine them based on the surface angle
    vec4 final_color = tex_x * blend_weights.x + tex_y * blend_weights.y + tex_z * blend_weights.z;
    
    ALBEDO = final_color.rgb;
}
