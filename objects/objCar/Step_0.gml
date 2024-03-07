// get inputs

var _input = {
	accelerate	: keyboard_check(ord("W")) || keyboard_check(vk_up),
	decelerate	: keyboard_check(ord("S")) || keyboard_check(vk_down),
	turn_left	: keyboard_check(ord("A")) || keyboard_check(vk_left),
	turn_right	: keyboard_check(ord("D")) || keyboard_check(vk_right)
};

// acceleration and breaking

if (_input.decelerate)
{
	torque = approach(torque, -max_torque/2, breaking_power * decel);
}

if (_input.accelerate)
{
	torque = approach(torque, max_torque, accel);
}
else if (!_input.decelerate)
{
	torque = approach(torque, 0, decel);
}

// turning

if (_input.turn_left != _input.turn_right)
{
	var _max_steering_angle = _input.turn_left ? -max_steering_angle : max_steering_angle;
	
	
	steering_angle = approach(steering_angle, _max_steering_angle, steering_rate);
}
else
{
	steering_angle = approach(steering_angle, 0, steering_rate/2);
}

// velocity and position

velocity.length	= torque;
velocity.dir	= approach(velocity.dir, velocity.dir - steering_angle, (abs(steering_angle) / max_torque) * torque * 0.1);

x += lengthdir_x(velocity.length, velocity.dir);
y += lengthdir_y(velocity.length, velocity.dir);

// visual

car_angle	= velocity.dir - 90;

array_delete(trail, 0, 1);
array_push(trail, {
	x : x,
	y : y
});

// camera update

var _zoom_change = (torque == 0) ? 0 : - (0.4 / max_torque) * min(abs(torque * 2), max_torque);

global.camera.zoom_to(1 + _zoom_change);
global.camera.rotate_to(-car_angle);