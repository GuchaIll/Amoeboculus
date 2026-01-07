use glam::{Vec3, Mat4};
use serde::{Deserialize, Serialize};
use material::Material;


#[derive(Serialize, Deserialize, Clone, Default)]
pub struct Scene {
    pub camera: Camera,
    pub objects: Vec<Object>,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct Camera {
    pub position: Vec3,
    pub look_at: Vec3,
    pub fov_y: f32,
}

impl Default for Camera {
    fn default() -> Self {
        Self {
            position: Vec3::new(0.0, 2.0, 5.0),
            look_at: Vec3::ZERO,
            fov_y: 32.0,
        }
    }
}


#[derive(Serialize, Deserialize, Clone)]
pub struct Object {
    pub id: u32,
    pub transform: Mat4,
    pub material: Material,
    pub shape: Shape,
}

#[derive(Serialize, Deserialize, Clone)]
pub enum Shape {
    Sphere { radius: f32 },
    Plane { normal: Vec3, height: f32 },
    Cube { size: Vec3 },
    Mesh { path: String },
    Empty,
}