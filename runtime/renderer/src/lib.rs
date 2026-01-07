use wgpu::util::DeviceExt;

#[repr(C)]
#[derive(Debug, Copy, Clone, bytemuck::Pod, bytemuck::Zeroable)]
pub struct Globals {
    pub camera_pos: [f32; 4],
    pub time: f32,
    pub _pad0: [f32; 3],
    pub camera_matrix: [[f32; 4]; 4],
    pub resolution: [f32; 2],
    pub _pad1: [f32; 2],
}

pub enum RenderTarget<'a> {
    SwapChain { view: &'a wgpu::TextureView },
    Offscreen { view: &'a wgpu::TextureView },
}


pub struct RuntimeRenderer {
    pub pipeline: wgpu::RenderPipeline,
    pub globals: Globals,
    pub globals_buffer: wgpu::Buffer,
    pub globals_bind_group: wgpu::BindGroup,
}

impl RuntimeRenderer {

    pub fn new(device: &wgpu::Device, format: wgpu::TextureFormat) -> Self {
        let globals = Globals {
            camera_pos: [0.0, 2.0, 10.0, 0.0],
            time: 0.0,
            _pad0: [0.0; 3],
            camera_matrix: [[1.0, 0.0, 0.0, 0.0], [0.0, 1.0, 0.0, 0.0], [0.0, 0.0, 1.0, 0.0], [0.0, 0.0, 0.0, 1.0]],
            resolution: [800.0, 600.0],
            _pad1: [0.0; 2],
        };

        let globals_buffer = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("Globals Buffer"),
            contents: bytemuck::cast_slice(&[globals]),
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
        });

        let globals_bind_group_layout = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
            entries: &[wgpu::BindGroupLayoutEntry {
                binding: 0,
                visibility: wgpu::ShaderStages::FRAGMENT,
                ty: wgpu::BindingType::Buffer {
                    ty: wgpu::BufferBindingType::Uniform,
                    has_dynamic_offset: false,
                    min_binding_size: None,
                },
                count: None,
            }],
            label: Some("globals_bind_group_layout"),
        });

        let globals_bind_group = device.create_bind_group(&wgpu::BindGroupDescriptor {
            layout: &globals_bind_group_layout,
            entries: &[wgpu::BindGroupEntry {
                binding: 0,
                resource: globals_buffer.as_entire_binding(),
            }],
            label: Some("globals_bind_group"),
        });

        // ... Keep your shader_source format! and pipeline creation logic here ...
        // Ensure fragment targets[0].format = format (passed into new)

        let shader_source = format!(
            "{}\n{}\n{}\n{}\n{}",
            include_str!("../../shader-lib/common.wgsl"),
            include_str!("../../shader-lib/materials.wgsl"),
            include_str!("../../shader-lib/primitives.wgsl"),
            include_str!("../../shader-lib/sdf_ops.wgsl"),
            include_str!("../../shader-lib/optimization.wgsl"),
        );

        // ... (Create shader module, layout, and pipeline as in your existing code) ...

        Self {
            pipeline: render_pipeline, // from your existing logic
            globals,
            globals_buffer,
            globals_bind_group,
        }
    }

    pub fn render(&self, encoder: &mut wgpu::CommandEncoder, target: RenderTarget) {
        let view = match target {
            RenderTarget::SwapChain { view } => view,
            RenderTarget::Offscreen { view } => view,
        };

        let mut render_pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
            label: Some("Runtime Render Pass"),
            color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                view,
                resolve_target: None,
                ops: wgpu::Operations {
                    load: wgpu::LoadOp::Clear(wgpu::Color::BLACK),
                    store: wgpu::StoreOp::Store,
                },
                depth_slice: None,
            })],
            ..Default::default()
        });

        render_pass.set_pipeline(&self.pipeline);
        render_pass.set_bind_group(0, &self.globals_bind_group, &[]);
        render_pass.draw(0..3, 0..1);
    }
}