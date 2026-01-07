// ============ SDF Primitives ============

fn sdSphere(p: vec3<f32>, r: f32) -> f32 {
    return length(p) - r;
}

fn sdBox(p: vec3<f32>, b: vec3<f32>) -> f32 {
    let q = abs(p) - b;
    return length(max(q, vec3<f32>(0.0))) +
           min(max(q.x, max(q.y, q.z)), 0.0);
}

fn sdTorus(p: vec3<f32>, t: vec2<f32>) -> f32 {
    let q = vec2<f32>(length(vec2<f32>(p.x, p.z)) - t.x, p.y);
    return length(q) - t.y;
}

fn sdCapsule(
    p: vec3<f32>,
    a: vec3<f32>,
    b: vec3<f32>,
    r: f32
) -> f32 {
    let pa = p - a;
    let ba = b - a;
    let h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

fn sdCylinder(p: vec3<f32>, h: f32, r: f32) -> f32 {
    let d = abs(vec2<f32>(length(vec2<f32>(p.x, p.z)), p.y))
            - vec2<f32>(r, h);
    return min(max(d.x, d.y), 0.0) +
           length(max(d, vec2<f32>(0.0)));
}

fn sdPlane(p: vec3<f32>, n: vec3<f32>, h: f32) -> f32 {
    // n must be normalized
    // positive above plane, negative below
    return dot(p, n) + h;
}

fn sdPlaneY(p: vec3<f32>, h: f32) -> f32 {
    // plane at y = h
    return p.y - h;
}

fn sdEllipsoid(p: vec3<f32>, r: vec3<f32>) -> f32 {
    let k0 = length(p / r);
    let k1 = length(p / (r * r));
    return k0 * (k0 - 1.0) / k1;
}
