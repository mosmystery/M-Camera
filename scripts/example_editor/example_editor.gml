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