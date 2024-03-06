// feather ignore all



/// @function			ExampleEditor() : Example() constructor
/// @description		A camera example for a basic level or graphics editor, showcasing pan and zoom with the mouse.
/// @returns {struct.Example}
function ExampleEditor() : Example() constructor
{
	// config
	
	name	= "Editor Example";
	ui_text	= "Mouse:\n- L / R: place / erase\n- Middle: pan\n- Scroll: zoom\nZ / X: rotate\nR: reset\nSpace: shake";
	
	x	= mouse_x;
	y	= mouse_y;
	
	
	
	  /////////////
	 // methods //
	/////////////
	
	
	
		  ////////////
		 // events //
		////////////
	
	
	
	/// @description	The create event, for setting up the camera and example.
	/// @returns		N/A
	create	= function() {
		// world init
		
		world	= {
			width		: 16,
			height		: 16,
			cell_width	: 8,
			cell_height	: 8,
			width_scaled : function() {
				return cell_width * width;
			},
			height_scaled : function() {
				return cell_height * height;
			}
		};
	
		world.level = level_create(world.width, world.height)		// create the array2d representation of the level.
		
		// camera init
		
		var _angle_anchor = {
			x : world.width_scaled() / 2,
			y : world.height_scaled() / 2,
		};								// targets and anchors simply need to include an x and y value to work, whether that is an object or a struct (such as a Vector2).
		
		var _border	= 1024;						// A border margin for the camera boundary.
		
		global.camera.set_angle_anchor(_angle_anchor);			// ensure the camera rotates around the center of the level.
		global.camera.set_zoom_anchor(self);				// ensure camera zooms towards and away from objMouseControl.
		
		global.camera.set_zoom_limits(1/16, 4);				// Sets max and min zoom limits to a reasonable expectation for level editing. Try other values or removing this line for wider default range.
		global.camera.set_shake_limits(4, 22.5, 1);			// Define the shake limits. Try different settings! Try 0 to turn off a parameter.
		global.camera.set_interpolation(1, 1/4, 1/4);			// Try setting interpolation values to different interpolation values, such as other fractions or 1 for instant change.
		
		global.camera.set_boundary(-_border, -_border, world.width_scaled()+_border, world.height_scaled()+_border);	// sets a boundary for the camera. Try .set_debug_mode(true) to see it, or try removing this line or calling .unset_boundary() to remove it.
		global.camera.set_start_values(world.width_scaled()/2, world.height_scaled()/2);				// sets the camera startx and starty to the center of global.world. Also takes optional parameters for anglestart and zoomstart.
		global.camera.reset();						// resets the camera to the new start values.
	};
	
	/// @description	The destroy event, for cleaning up the example.
	/// @returns		N/A
	destroy	= function() {
		delete world;
		
		world = undefined;
	};
	
	/// @description	The step event, for code that needs to run every frame.
	/// @returns		N/A
	step	= function() {
		// update x,y to match mouse position
		
		x	= mouse_x;
		y	= mouse_y;
		
		global.camera.set_zoom_anchor(self);	// because self is a struct, the anchor needs to be set every frame to update. If the anchor was an object instance it would only need to be set once.
		
		// get inputs
		
		var _input = {
			// camera controls
			zoom_in		: mouse_wheel_up(),
			zoom_out	: mouse_wheel_down(),
			rotate_ccw	: keyboard_check_pressed(ord("Z")),
			rotate_cw	: keyboard_check_pressed(ord("X")),
			pan_start	: mouse_check_button_pressed(mb_middle),
			pan_end		: mouse_check_button_released(mb_middle),
			reset		: keyboard_check_pressed(ord("R")),
			shake		: keyboard_check_pressed(vk_space),
			
			// editor controls
			place_block	: mouse_check_button(mb_left),
			erase_block	: mouse_check_button(mb_right)
		};
		
		// control camera
		
		with (global.camera)
		{
			if (_input.zoom_in)
			{
				zoom_by(2);		// input 2 to double the camera zoom. Try .zoom_to() to set the taget zoom factor directly (>1 = zoom in, else 1 = normal, else >0 = zoom out)
			}
			else if (_input.zoom_out)
			{
				zoom_by(0.5);		// input 0.5 to half the camera zoom.
			}
			
			if (_input.rotate_cw)
			{
				rotate_by(90);		// rotate camera by 90 degrees. "false" indicates gradual change. Try other values such as 1 or 45 degrees, and/or try changing keyboard_check_pressed() to keyboard_check() for constant rotation.
			}
			else if (_input.rotate_ccw)
			{
				rotate_by(-90);		// rotate by a negative number to rotate counterclockwise
			}
			
			if (_input.pan_start)
			{
				start_panning(other.x, other.y);	// start panning on input press
			}
			else if (_input.pan_end)
			{
				stop_panning();				// end panning on input release
			}
			else if (is_panning())
			{
				pan_to(other.x, other.y);		// pan to desired position when .is_panning()
			}
			
			if (_input.reset)
			{
				reset(true, false);	// reset the camera to start values. Try manually resetting the camera with .zoom_to(), .rotate_to() and .move_to() 
			}
			
			if (_input.shake)
			{
				shake_to(0.5);		// set the intensity of the shake and optionally resets the shake transform values. Try a value between 0 and 1. Or, hell, try 1000, why not. See .shake_to(), .shake_by(), .set_shake_limits() and .set_shake_interpolation().
			}
		}
		
		// place and erase blocks
		
		if (_input.place_block != _input.erase_block)	// if place_block or erase_block is pressed or otherwise different from eachother ...
		{
			// find current cell from mouse position
			var _cell_x = floor(x / world.cell_width);
			var _cell_y = floor(y / world.cell_height);
			
			// edit current cell
			if (_cell_x == clamp(_cell_x, 0, world.width-1) && _cell_y == clamp(_cell_y, 0, world.height-1))
			{
				world.level[_cell_y][_cell_x] = real(_input.place_block); // set cell value to 1 if place_block was pressed, otherwise 0
			}
		}
	};
	
	/// @description	The draw event, for drawing the example.
	/// @returns		N/A
	draw	= function() {
		// draw level
		
		level_draw(world.level, world.cell_width, world.cell_height, 1);
		
		// draw cell outline of cell at mouse position
		
		var _x1 = (floor(x / world.cell_width) * (world.cell_width));
		var _y1 = (floor(y / world.cell_height) * (world.cell_height));
		var _x2 = _x1 + (world.cell_width-1);
		var _y2 = _y1 + (world.cell_height-1);
		
		draw_rectangle_colour(_x1, _y1, _x2, _y2, $CCCCCC, $CCCCCC, $CCCCCC, $CCCCCC, true);
	};
	
	/// @description	The draw gui event, for any drawing to the gui.
	/// @returns		N/A
	draw_gui = function() {
		draw_sprite(sprMouse, 0, global.camera.find_gui_mouse_x(), global.camera.find_gui_mouse_y());
	};
	
	
	
		  ////////////////////////
		 // supporting methods //
		////////////////////////
	
	
	
	/// @description			Creates a 2d array with values of 1 in a Z shape around the border, and 0 in other cells.
	/// @param {real}			_width		The width of the level, in cells.
	/// @param {real}			_height		The height of the level, in cells.
	/// @returns {array<array<real>>}	Returns an array of arrays of value 0 or 1.
	static level_create = function(_width, _height)
	{
		var _level = array2d_create(_width, _height, 0);
		
		for (i = 0; i < _width; i++)
		{
			_level[0][i]				= 1;
			_level[_height-1][i]			= 1;
		}
		
		return _level;
	}
	
	
	
	/// @description			Draws _array2d cells of value _solid_val as blocks, given _cellwidth, _cellheight, then draws a rectangle around the perimeter of the level.
	/// @param {array<array<any>>}		_array2d	The _array2d to draw.
	/// @param {real}			_cellwidth	The width to draw cells.
	/// @param {real}			_cellheight	The height to draw cells.
	/// @param {real}			[_solid_val=1]	The value that represents a solid block in _array2d.
	/// @returns				N/A
	static level_draw = function(_array2d, _cellwidth, _cellheight, _solid_val=1, _solid_sprite=sprBlock)
	{
		// draw blocks
		
		var _width	= array2d_width(_array2d);
		var _height	= array2d_width(_array2d);
		
		for (_y = 0; _y < _height; _y++)
		{
			for (_x = 0; _x < _width; _x++)
			{
				if (_array2d[_y][_x] != _solid_val)
				{
					continue;
				}
				
				draw_sprite(_solid_sprite, -1, _x * _cellwidth, _y * _cellheight);
			}
		}
		
		// draw boundary
		
		draw_rectangle_colour(0, 0, (_width * _cellwidth)-1, (_height * _cellheight)-1, $0000FF, $0000FF, $0000FF, $0000FF, true);
	}
}