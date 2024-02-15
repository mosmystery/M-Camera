/// @function		game_init()
/// @description	This function initialises the game. It is ran in the creation code of Room1
/// @returns		N/A
function game_init()
{
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
	
	global.camera	= new MCamera(320, 180, 4, 1);
	
	var _rotation_anchor = {									// targets and anchors simply need to include an x and y value to work, whether that is an object or a struct (such as a Vector2).
		x : global.world.width_scaled() / 2,
		y : global.world.height_scaled() / 2,
	};
	
	global.camera.set_rotation_anchor(_rotation_anchor);						// ensure the camera rotates around the center of the level
	global.camera.set_zoom_anchor(objMouseControl);							// ensure camera zooms towards and away from objMouseControl
	global.camera.set_start_values(global.world.width_scaled()/2, global.world.height_scaled()/2);	// sets the camera startx and starty to the center of global.world. Also takes optional parameters for anglestart and zoomstart
	global.camera.reset(true);									// resets the camera to the new start values
	global.camera.set_debug_mode(false);								// Set to true to see debug display
	
	global.camera.set_interpolation_values(0, 1/4, 1);						// See MCamera.gml for full list of methods and documentation.
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