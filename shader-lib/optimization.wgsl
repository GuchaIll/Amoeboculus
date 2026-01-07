// ============================================
// Basic Material - Core Ray Marching Functions
// WGSL version (WebGPU compatible)
// ============================================
//
// NOTE:
// - sceneSDF(p) must be implemented elsewhere
// - uniforms must be declared in the main shader
// ============================================
// ============================================================
// Minimal Raymarch + Phong (WGSL, WebGPU-friendly, compiles)
// ============================================================

// ---------- Uniforms ----------
struct Globals {
    camera_pos: vec3<f32>,

    time: f32,
    _pad0: vec3<f32>,

    camera_matrix: mat4x4<f32>,

    uResolution: vec2<f32>,
    _pad1: vec2<f32>
};

@group(0) @binding(0)
var<uniform> globals: Globals;

// ---------- IO ----------


@fragment
fn fs_main(in: VOutput) -> @location(0) vec4<f32> {
    let ro = globals.camera_pos;
    // let rd = getRayDir(in.clip_position.xy);

    let fragCoord = in.clip_position.xy;
    let resolution = globals.uResolution;

    // Convert pixel coords → [0,1]
    let uv01 = fragCoord / resolution;

    // Convert to [-1,1] with correct Y flip
    let uv = vec2<f32>(
        uv01.x * 2.0 - 1.0,
        1.0 - uv01.y * 2.0
    );

    // Aspect correct
    let uv_corrected = uv * vec2<f32>(
        resolution.x / resolution.y,
        1.0
    );

    let fov = radians(60.0);
    let z = -1.0 / tan(fov * 0.5);
    let rd = normalize(vec3<f32>(uv_corrected, z));

    // Raymarch hit test
    let hit = rayMarch(ro, rd);

    var color: vec3<f32>;

    if (hit.hit) {
        color = shade(hit.pos, rd, globals.time);
    } else {
        // simple sky gradient
        color = vec3<f32>(0.1, 0.2, 0.3) * (rd.y * 0.5 + 0.5);
    }

    // Gamma correction
    color = pow(color, vec3<f32>(1.0 / 2.2));
    return vec4<f32>(color, 1.0);

//      let uv = in.clip_position.xy / globals.uResolution;
//          return vec4<f32>(uv, 0.0, 1.0);
}

// ============================================================
// Ray direction (pixel -> view ray -> world ray)
// ============================================================
fn getRayDir(fragCoord: vec2<f32>) -> vec3<f32> {
    let resolution = globals.uResolution;

    // fragCoord here is in pixel space because builtin(position).xy is pixel coords in fragment stage
    // Map to NDC-ish uv in [-1,1] with aspect correction by dividing by resolution.y
    let uv = (fragCoord * 2.0 - resolution) / resolution.y;

    let fov: f32 = radians(60.0);
    let z: f32 = -1.0 / tan(fov * 0.5);

    let rdLocal = normalize(vec3<f32>(uv, z));

    // Rotate into world space. w = 0 so translation doesn't apply.
    let rdWorld = normalize((globals.camera_matrix * vec4<f32>(rdLocal, 0.0)).xyz);
    return rdWorld;

}

// ============================================================
// SDF primitives + scene
// ============================================================


fn sceneSDF(p: vec3<f32>) -> f32 {
    // Example scene: sphere at origin with radius 5

    let d1 =  sdSphere(p, 1.0);
    let d3 = sdCylinder(p, 4.0, 1.0);
    let d2 = sdPlane(p,  vec3<f32> (0.0,1.0,0.0), -0.5);
    return opUnion(opUnion(d1,d3), d2);

}

// ============================================================
// Ray marching
// ============================================================

struct HitInfo {
    hit: bool,
    t: f32,
    pos: vec3<f32>,
    steps: i32,
};

fn rayMarch(ro: vec3<f32>, rd: vec3<f32>) -> HitInfo {
    var t: f32 = 0.0;
    let max_t: f32 = 100.0;
    let epsilon: f32 = 0.0005;

    var p: vec3<f32> = ro;
    var steps: i32 = 0;

    for (var i: i32 = 0; i < 128; i = i + 1) {
        steps = i;
        p = ro + rd * t;

        let d = sceneSDF(p);

        if (d < epsilon) {
            return HitInfo(true, t, p, steps);
        }

        t = t + d;

        if (t > max_t) {
            break;
        }
    }

    return HitInfo(false, t, p, steps);
}

// ============================================================
// Normal + shadows + shading
// ============================================================

fn calcNormal(p: vec3<f32>, eps: f32) -> vec3<f32> {
    // Tetrahedron technique
    let k = vec2<f32>(1.0, -1.0);
    let c = sceneSDF(p);

    let n =
        vec3<f32>( k.x,  k.y,  k.y) * sceneSDF(p + vec3<f32>( k.x,  k.y,  k.y) * eps) +
        vec3<f32>( k.y,  k.y,  k.x) * sceneSDF(p + vec3<f32>( k.y,  k.y,  k.x) * eps) +
        vec3<f32>( k.y,  k.x,  k.y) * sceneSDF(p + vec3<f32>( k.y,  k.x,  k.y) * eps) +
        vec3<f32>( k.x,  k.x,  k.x) * c;

    return normalize(n);
}

fn softShadow(ro: vec3<f32>, rd: vec3<f32>, maxDist: f32, steps: i32) -> f32 {
    var res: f32 = 1.0;
    var t: f32 = 0.02;

    for (var i: i32 = 0; i < steps; i = i + 1) {
        let p = ro + rd * t;
        let h = sceneSDF(p);

        if (h < 0.001) {
            return 0.0;
        }

        res = min(res, 10.0 * h / t);
        t = t + clamp(h, 0.02, 0.1);

        if (t > maxDist) {
            break;
        }
    }

    return clamp(res, 0.0, 1.0);
}

fn groundColor(p: vec3<f32>) -> vec3<f32> {
    let check = checkerboardXZ(p, 1.0);

    let colorA = vec3<f32>(0.15, 0.15, 0.15);
    let colorB = vec3<f32>(0.85, 0.85, 0.85);

    return mix(colorA, colorB, check);
}

fn shade(p: vec3<f32>, rd: vec3<f32>, time: f32) -> vec3<f32> {
    let n = calcNormal(p, 0.001);

    // Animated directional light
    let lightDir = normalize(vec3<f32>(
        sin(time * 0.5) * 0.5,
        0.7,
        -0.3 + cos(time * 0.5) * 0.5
    ));
    let lightColor = vec3<f32>(1.0, 1.0, 1.0);


    let ambient: f32 = 0.1;

    var shadow: f32 = 1.0;
    // Enable/disable shadows here (or make it a uniform bool)
    shadow = softShadow(p + n * 0.01, lightDir, 10.0, 24);

    // Diffuse
    let diff = max(dot(n, lightDir), 0.0);

    // Specular
    let viewDir = -rd;
    let halfDir = normalize(lightDir + viewDir);
    let spec = pow(max(dot(n, halfDir), 0.0), 32.0);

    var color = vec3<f32>(ambient);

    color = color + diff * lightColor * shadow;
    color = color + spec * lightColor * 0.5 * shadow;

    if (abs(p.y) < 0.001) {
            color = groundColor(p);
        }


    // Simple fog (optional): uses distance from origin-ish; if you want actual t, pass it in
    // let fog = 1.0 - exp(-length(p) * 0.02);
    // color = mix(color, vec3<f32>(0.1, 0.15, 0.2), fog);

    return color;
}