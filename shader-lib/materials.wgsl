fn checkerboardXZ(p: vec3<f32>, scale: f32) -> f32 {
    let cx = floor(p.x * scale);
    let cz = floor(p.z * scale);
    return f32(i32(cx + cz) & 1);
}