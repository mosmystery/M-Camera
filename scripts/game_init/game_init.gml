/// @function		game_init()
/// @description	This function initialises the game. It is ran in the creation code of Room1
/// @returns		N/A
function game_init()
{
	draw_set_font(fntSystem);
	
	// world init
	
	global.world	= {
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
	
	global.world.level = level_create(global.world.width, global.world.height)			// create the array2d representation of the level.
	
	// create mouse controller
	
	instance_create_depth(0, 0, 0, objMouseControl);						// create objMouseControl which houses the demo code.
	
	// camera init
	
	global.camera	= new MCamera(320, 180, 4, 1);							// Create MCamera. View MCamera() for parameter descriptions. Try setting different parameters.
	
	global.camera.set_interpolation_values(1/4, 1/4, 1/4);						// See MCamera.gml for full list of methods and documentation. Try setting zoom interpolation to a fraction.
	global.camera.set_start_values(global.world.width_scaled()/2, global.world.height_scaled()/2);	// sets the camera startx and starty to the center of global.world. Also takes optional parameters for anglestart and zoomstart.
	global.camera.reset();										// resets the camera to the new start values.
	
	var _angle_anchor = {										// targets and anchors simply need to include an x and y value to work, whether that is an object or a struct (such as a Vector2).
		x : global.world.width_scaled() / 2,
		y : global.world.height_scaled() / 2,
	};
	
	global.camera.set_angle_anchor(_angle_anchor);							// ensure the camera rotates around the center of the level.
	global.camera.set_zoom_anchor(objMouseControl);							// ensure camera zooms towards and away from objMouseControl.
	global.camera.set_zoom_limits(1/16, 4);								// Sets max and min zoom limits to a reasonable expectation for level editing. Try other values or removing this line for wider default range.
	
	var _border	= 1024;
	
	global.camera.set_boundary(-_border, -_border, global.world.width_scaled()+_border, global.world.height_scaled()+_border);	// sets a boundary for the camera. Try .set_debug_mode(true) to see it, or try removing this line or calling .unset_boundary() to remove it.
	
	global.camera.set_debugging(true);								// Turn debug mode on. Try setting to false or removing line.
}



/// @function				level_create(_width, _height)
/// @description			This function creates a 2d array with values of 1 in a Z shape around the border, and 0 in other cells.
/// @param {real}			_width		The width of the level, in cells.
/// @param {real}			_height		The height of the level, in cells.
/// @returns {array<array<real>>}	Returns an array of arrays of value 0 or 1.
function level_create(_width, _height)
{
	var _level = array2d_create(_width, _height, 0);
	
	for (i = 0; i < _width; i++)
	{
		_level[0][i]				= 1;
		_level[_height-1][i]			= 1;
		_level[max(0, (_height-1)-i)][i]	= 1;
	}
	
	return _level;
}



/// @function				level_draw(_array2d, _cellwidth, _cellheight, _solid_val)
/// @description			Draws _array2d cells of value _solid_val as blocks, given _cellwidth, _cellheight, then draws a rectangle around the perimeter of the level.
/// @param {array<array<any>>}		_array2d	The _array2d to draw.
/// @param {real}			_cellwidth	The width to draw cells.
/// @param {real}			_cellheight	The height to draw cells.
/// @param {real}			[_solid_val=1]	The value that represents a solid block in _array2d.
/// @returns				N/A
function level_draw(_array2d, _cellwidth, _cellheight, _solid_val=1, _solid_sprite=sprBlock)
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