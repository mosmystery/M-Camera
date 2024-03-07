/// @function		approach(_a, _b, _amount)
/// @description	Returns _a shifted by _amount in direction of _b. If amount overshoots _b, _b is returned.
/// @param {real}	_a	The start value
/// @param {real}	_b	The target value
/// @param {real}	_amount	The amount to shift _a to, in the direction of _b
/// returns {real}	Returns _a shifted by _amount in direction of _b. If amount overshoots _b, _b is returned.
function approach(_a, _b, _amount)
{
	if (_a > _b)
	{
		return max(_a - _amount, _b);
	}
	
	return min(_a + _amount, _b);
}