pub struct EditorViewport {
    pub texture: wgpu::Texture,
    pub view: wgpu::TextureView,
    pub egui_id: egui::TextureId,
    pub size: [u32; 2],
}

impl EditorViewport {
    pub fn new(device: &wgpu::Device, egui_renderer: &mut egui_wgpu::Renderer, size: [u32; 2]) -> Self {
        let texture = device.create_texture(&wgpu::TextureDescriptor {
            label: Some("Viewport Texture"),
            size: wgpu::Extent3d { width: size[0], height: size[1], depth_or_array_layers: 1 },
            mip_level_count: 1,
            sample_count: 1,
            dimension: wgpu::TextureDimension::D2,
            format: wgpu::TextureFormat::Rgba8UnormSrgb, // Match egui expectation
            usage: wgpu::TextureUsages::RENDER_ATTACHMENT | wgpu::TextureUsages::TEXTURE_BINDING,
            view_formats: &[],
        });

        let view = texture.create_view(&Default::default());
        // Register the texture so egui knows how to draw it
        let egui_id = egui_renderer.register_native_texture(device, &view, wgpu::FilterMode::Linear);

        Self { texture, view, egui_id, size }
    }
}