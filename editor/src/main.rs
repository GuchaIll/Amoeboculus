
use eframe::egui;
use scene::Scene;
use serialization::save_scene;

pub struct EditorApp {
    runtime: RuntimeRenderer,
    viewport: Options<EditorViewport>
}

impl eframe::App for EditorApp {
    fn update(&mut self, ctx: &egui::Context, frame: &mut eframe::Frame) {
        let render_state = frame.wgpu_render_state().unwrap();
        let device = &render_state.device;

        // 1. Handle resizing / Viewport creation
        egui::CentralPanel::default().show(ctx, |ui| {
            let size = ui.available_size();
            let size_px = [size.x as u32, size.y as u32];

            if self.viewport.is_none() || self.viewport.as_ref().unwrap().size != size_px {
                // (Re)create viewport if size changed
                self.viewport = Some(EditorViewport::new(device, &mut render_state.renderer.write(), size_px));
                self.runtime.globals.resolution = [size.x, size.y];
                self.runtime.update_globals();
            }

            // 2. Draw the image in the UI
            ui.image(self.viewport.as_ref().unwrap().egui_id, size);
        });

        // 3. Queue the Runtime Render
        let mut encoder = device.create_command_encoder(&wgpu::CommandEncoderDescriptor::default());

        if let Some(vp) = &self.viewport {
            self.runtime.render(
                &mut encoder,
                RenderTarget::Offscreen { view: &vp.view }
            );
        }

        // Submit to the same queue egui uses
        render_state.queue.submit(Some(encoder.finish()));

        // Request continuous repaint for game loop
        ctx.request_repaint();
    }
}