draw_sprite(sprMouse, 0, global.camera.find_gui_mouse_x(), global.camera.find_gui_mouse_y());

if (global.camera.is_debugging())
{
	draw_set_alpha(0.25);
	draw_text(8, 8, "mouse:\n- L/R: place/erase\n- Middle: pan\n- Scroll: zoom\nZ/X: rotate\nR: reset\nD: toggle debug\nSpace: shake");
	draw_set_alpha(1);
}