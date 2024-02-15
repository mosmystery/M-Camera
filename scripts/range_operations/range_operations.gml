/// @function		wrap(_number, _range_start, _range_end)
/// @description	Given a value and a range, constricts the value to the range by looping it around the edges of the range. Example use: constrict an angle to the range 0->360.
/// @param {real}	_number		The number to keep within range
/// @param {real}	_range_start	The first number in the range
/// @param {real}	_range_end	The last number in the range
/// @returns {real}	The value constricted to the range.
function wrap(_number, _range_start, _range_end)
{
	if ((_range_end - _range_start) == 0)
	{
		return _range_start;
	}
	
	_number = (_range_start + ((_number - _range_start) % (_range_end - _range_start)));
	
	if (_number < _range_start)
	{
		return (_range_end - (_range_start - _number));
	}
	
	return _number;
}