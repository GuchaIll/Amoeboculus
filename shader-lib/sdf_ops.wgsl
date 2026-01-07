// ============ SDF Operations ============

fn opUnion(d1: f32, d2: f32) -> f32 {
    return min(d1, d2);
}

fn opSubtraction(d1: f32, d2: f32) -> f32 {
    // same as GLSL: max(-d1, d2)
    return max(-d1, d2);
}

fn opIntersection(d1: f32, d2: f32) -> f32 {
    return max(d1, d2);
}

fn opSmoothUnion(d1: f32, d2: f32, k: f32) -> f32 {
    // clamp(x, 0, 1) is WGSL clamp(x, 0.0, 1.0)
    let h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    // GLSL mix(a,b,t) -> WGSL mix(a,b,t) OR explicit lerp
    // Note: mix(a,b,t) == a*(1-t) + b*t
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

fn opSmoothSubtraction(d1: f32, d2: f32, k: f32) -> f32 {
    let h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0);
    return mix(d2, -d1, h) + k * h * (1.0 - h);
}

fn opSmoothIntersection(d1: f32, d2: f32, k: f32) -> f32 {
    let h = clamp(0.5 - 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) + k * h * (1.0 - h);
}

// ============ Domain Operations ============

fn opRepeat(p: vec3<f32>, c: vec3<f32>) -> vec3<f32> {
    // GLSL mod(x,y) -> WGSL rem_euclid(x,y) (preferred for positive modulus behavior)
    // rem_euclid works component-wise on vectors.
    //return fmod(p + 0.5 * c,c) - 0.5 * c;
     return (p + 0.5 * c) % c - 0.5 * c;
}

fn opSymmetryX(p_in: vec3<f32>) -> vec3<f32> {
    var p = p_in;
    p.x = abs(p.x);
    return p;
}

fn opSymmetryXZ(p_in: vec3<f32>) -> vec3<f32> {
    var p = p_in;
    // p.xz = abs(p.xz) in WGSL:
    p.x = abs(p.x);
    p.z = abs(p.z);
    return p;
}

// ============ Transformations ============

fn opRotateY(p: vec3<f32>, angle: f32) -> vec3<f32> {
    let c = cos(angle);
    let s = sin(angle);

    // GLSL mat2(c,-s,s,c) * p.xz
    let x = c * p.x - s * p.z;
    let z = s * p.x + c * p.z;

    return vec3<f32>(x, p.y, z);
}

fn opRotateX(p: vec3<f32>, angle: f32) -> vec3<f32> {
    let c = cos(angle);
    let s = sin(angle);

    // rotate in YZ plane
    let y = c * p.y - s * p.z;
    let z = s * p.y + c * p.z;

    return vec3<f32>(p.x, y, z);
}

fn opRotateZ(p: vec3<f32>, angle: f32) -> vec3<f32> {
    let c = cos(angle);
    let s = sin(angle);

    // rotate in XY plane
    let x = c * p.x - s * p.y;
    let y = s * p.x + c * p.y;

    return vec3<f32>(x, y, p.z);
}