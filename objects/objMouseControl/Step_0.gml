// update x,y to match mouse position

x = mouse_x;
y = mouse_y;

// get inputs

var _input = {
	// camera controls
	zoom_in		: mouse_wheel_up(),
	zoom_out	: mouse_wheel_down(),
	rotate_ccw	: keyboard_check_pressed(ord("Z")),
	rotate_cw	: keyboard_check_pressed(ord("X")),
	pan_start	: mouse_check_button_pressed(mb_middle),
	pan_end		: mouse_check_button_released(mb_middle),
	reset		: keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("R")),
	toggle_debug	: keyboard_check_pressed(vk_tab) || keyboard_check_pressed(ord("D")),
	shake		: keyboard_check_pressed(vk_space),
	
	// editor controls
	place_block	: mouse_check_button(mb_left),
	erase_block	: mouse_check_button(mb_right)
};

// contol the camera

if (_input.zoom_in)
{
	global.camera.zoom_by(2);		// input 2 to double the camera zoom. Try .zoom_to() to set the taget zoom factor directly (>1 = zoom in, else 1 = normal, else >0 = zoom out)
}
else if (_input.zoom_out)
{
	global.camera.zoom_by(0.5);		// input 0.5 to half the camera zoom.
}

if (_input.rotate_cw)
{
	global.camera.rotate_by(90);		// rotate camera by 90 degrees. "false" indicates gradual change. Try other values such as 1 or 45 degrees, and/or try changing keyboard_check_pressed() to keyboard_check() for constant rotation.
}
else if (_input.rotate_ccw)
{
	global.camera.rotate_by(-90);		// rotate by a negative number to rotate counterclockwise
}

if (_input.pan_start)
{
	global.camera.start_panning(x, y);	// start panning on input press
}
else if (_input.pan_end)
{
	global.camera.stop_panning();		// end panning on input release
}
else if (global.camera.is_panning())
{
	global.camera.pan_to(x, y);		// pan to desired position when .is_panning()
}

if (_input.reset)
{
	global.camera.reset();			// reset the camera to start values. Try manually resetting the camera with .zoom_to(), .rotate_to() and .move_to() 
}

if (_input.toggle_debug)
{
	global.camera.set_debugging();		// toggle camera debug display
}

if (_input.shake)
{
	global.camera.shake_to(0.5, true);	// set the intensity of the shake and optionally resets the shake transform values. Try a value between 0 and 1. Or, hell, try 1000, why not. See .shake_to(), .shake_by(), .set_shake_limits() and .set_shake_interpolation().
}

// place and erase blocks

if (_input.place_block != _input.erase_block)	// if place_block or erase_block is pressed or otherwise different from eachother ...
{
	// find current cell from mouse position
	var _cell_x = floor(x / global.world.cell_width);
	var _cell_y = floor(y / global.world.cell_height);
	
	// edit current cell
	if (_cell_x == clamp(_cell_x, 0, global.world.width-1) && _cell_y == clamp(_cell_y, 0, global.world.height-1))
	{
		global.world.level[_cell_y][_cell_x] = real(_input.place_block); // set cell value to 1 if place_block was pressed, otherwise 0
	}
}