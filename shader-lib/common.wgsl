struct VOutput {
    @builtin(position) clip_position: vec4<f32>,
};


@vertex
fn vs_main(@builtin(vertex_index) vid: u32) -> VOutput {
    // Fullscreen triangle in clip space
    var positions = array<vec2<f32>, 3>(
        vec2<f32>(-1.0, -1.0),
        vec2<f32>( 3.0, -1.0),
        vec2<f32>(-1.0,  3.0)
    );

    var out: VOutput;
    out.clip_position = vec4<f32>(positions[vid], 0.0, 1.0);
    return out;
}

fn fmod(x: f32, y: f32) -> f32 {
    return x - y * floor(x / y);
}
