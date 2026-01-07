struct VOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) v_color: vec4<f32>,
    @location(1) vert_pos: vec3<f32>, // Added this field so you can access it
};

@vertex
fn vs_main(@builtin(vertex_index) in_vertex_index: u32) -> VOutput {
    var pos = array<vec2<f32>, 3>(
        vec2<f32>(0.0, 0.5),
        vec2<f32>(-0.5, -0.5),
        vec2<f32>(0.5, -0.5)
    );
    var color = array<vec3<f32>, 3>(
        vec3<f32>(1.0, 0.0, 0.0),
        vec3<f32>(0.0, 1.0, 0.0),
        vec3<f32>(0.0, 0.0, 1.0)
    );

    var out: VOutput;
    let x = pos[in_vertex_index].x;
    let y = pos[in_vertex_index].y;
    
    out.clip_position = vec4<f32>(x, y, 0.0, 1.0);
    out.v_color = vec4<f32>(color[in_vertex_index], 1.0);
    out.vert_pos = out.clip_position.xyz; // This will now work
    return out;
}

@fragment
fn fs_main(in: VOutput) -> @location(0) vec4<f32> {
    return in.v_color;
}
