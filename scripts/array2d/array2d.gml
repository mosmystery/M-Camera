/// @function				array2d_create(width, height, value);
/// @description			Returns a array2d of defined width and height and initialises each cell with a value.
/// @param {real}			_width			The width of the array.
/// @param {real}			_height			The height of the array.
/// @param {any}			[_value=undefined]	The value to initialise each cell with. Optional - defaults to 0 if no value is supplied.
/// @returns {array<array<any>}	
function array2d_create(_width, _height, _value=undefined)
{
	var _array = [];
	
	for (var i = _height-1; i >= 0; i--)
	{
		_array[i] = array_create(_width, _value);
	}
	
	return _array;
}



/// @function			array2d_height(array2d);
/// @description		Gets height of an array2d.
/// @param {array<array<any>}	_array2d	The array2d to get the height of.
/// @returns {real}		Returns the height of _array2d.
function array2d_height(_array2d)
{
	return array_length(_array2d);
}



/// @function			array2d_width(array2d);
/// @description		Gets width of a array2d. Only compatable with rectangular arrays with uniform width and height; gets width from element 0;
/// @param {array<array<any>}	_array2d	The array2d to get the width of.
/// @returns {real}		Returns the width of _array2d.
function array2d_width(_array2d)
{
	if (array_length(_array2d)>0)
	{
		return array_length(_array2d[0]);
	}
	
	return 0;
}