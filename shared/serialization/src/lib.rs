use scene::Scene;
use anyhow;
use serde_json;

pub fn save_scene(scene: &Scene, path: &str) -> anyhow::Result<()> {
    let json = serde_json::to_string_pretty(scene)?;
    std::fs::write(path, json)?;
    Ok(())
}

pub fn load_scene(path: &str) -> anyhow::Result<Scene> {
    let data = std::fs::read_to_string(path)?;
    Ok(serde_json::from_str(&data)?)
}
