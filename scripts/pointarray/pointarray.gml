// feather ignore all



/// @function				draw_pointarray(_x, _y, _pointarray, _connect_end_points, _primitive_type, _colour)
/// @description			Draws a pointarray (array of vector2 structs containing x, y)
/// @param {real}			_x				The x co-ordinate to draw the pointarray at.
/// @param {real}			_y				The y co-ordinate to draw the pointarray at.
/// @param {array<struct.vector2>}	_pointarray			The pointarray (points are structs holding x, y; needs 1 point to be considered a pointlist)
/// @param {bool}			[_connect_end_points=false]	Whether to continue the primitive drawing from the last to the first point of the pointarray (true) or not (false).
/// @param {constant.PrimitiveType}	[_primitive_type=pr_pointlist]	The primitive type to draw with the points. Default: pr_pointlist
/// @param {constant.Color}		[_colour=c_green]		The colour to draw the pointlist.
/// @return				N/A
function draw_pointarray(_x, _y, _pointarray, _connect_end_points=false, _primitive_type = pr_pointlist, _colour = c_green)
{
	var _reset_colour = draw_get_color();
	
	draw_set_color(_colour);
	draw_primitive_begin(_primitive_type);
	
	var _len = array_length(_pointarray);
	
	for (var i = 0; i < _len; i++)
	{
		draw_vertex(_x + _pointarray[i].x, _y + _pointarray[i].y);
	}
	if (_connect_end_points && _len > 0)
	{
		draw_vertex(_x + _pointarray[0].x, _y + _pointarray[0].y); //so that last point continues to first point
	}
	
	draw_primitive_end();
	draw_set_colour(_reset_colour);
}