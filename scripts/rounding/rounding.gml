// feather ignore all



/// @function		round_towards(_n, _dest)
/// @description	Rounding function where values halfway between integers (x.5) are rounded in the direction of _dest. This differs from the built in round() function, which rounds towards the nearest even integer.
/// @param {real}	_n		Number to round.
/// @param {real}	_dest		Number to round towards when n == x.5.
/// @returns {real}	Returns number rounded to the nearest integer, with a preference for the integer in the direction of _dest.
function round_towards(_n, _dest)
{
	if (abs(_n) % 1 == 0.5)
	{
		if (_n > _dest)
		{
			return floor(_n);
		}
		else if (_n < _dest)
		{
			return ceil(_n);
		}
	}
	
	return round(_n);
}