// feather ignore all



/// @function			ExampleRacer() : Example() constructor
/// @description		A racer example for a basic top-down racing game, showcasing camera rotation and shake.
/// @returns {struct.Example}
function ExampleRacer() : Example() constructor
{
	// config
	
	name	= "Racer Example";
	ui_text	= "W / up: Accelerate\nS / down: Decelerate\nA / left: turn left\nD / right: turn right";
	
	racer	= undefined;		// racer object. See .create()
	track	= undefined;
	minimap	= undefined;
	
	track_radius	= 1024;
	minimap_scale	= 24/track_radius;
	
	
	  /////////////
	 // methods //
	/////////////
	
	
	
		  ////////////
		 // events //
		////////////
	
	
	
	/// @description	The create event, for setting up the camera and example.
	/// @returns		N/A
	create	= function() {
		racer ??= instance_create_depth(0, 0, 0, objCar);
		
		// camera init
		global.camera.set_interpolation(1/4, 1/8, 1/16);
		
		global.camera.set_angle_anchor(racer);
		
		global.camera.set_start_values(racer.x, racer.y-6);
		global.camera.reset();
		
		//generate racetrack
		track	= generate_racetrack_points();
		minimap	= pointarray_scale(track, minimap_scale);
	};
	
	/// @description	The destroy event, for cleaning up the example.
	/// @returns		N/A
	destroy	= function() {
		if (racer = undefined)
		{
			return;
		}
		
		instance_destroy(racer, true);
		
		racer	= undefined;
		track	= undefined;
		minimap	= undefined;
		
		global.camera.set_position_anchor();	// unset position anchor, as racer no longer exists
		global.camera.set_angle_anchor();	// unset angle anchor, as racer no longer exists
		global.camera.set_zoom_anchor();	// unset zoom anchor, as rocer no longer exists
	};
	
	/// @description	The step event, for code that needs to run every frame.
	/// @returns		N/A
	step	= function() {
		
	};
	
	/// @description	The draw event, for drawing the example.
	/// @returns		N/A
	draw	= function() {
		draw_racetrack();
	};
	
	/// @description	The draw gui event, for any drawing to the gui.
	/// @returns		N/A
	draw_gui = function() {
		draw_minimap();
	};
	
	
	
		  ////////////////////////
		 // supporting methods //
		////////////////////////
	
	
	
	/// @description		Generate a pointlist for the racetrack
	/// @returns {array<struct>}	returns array of vector2s.
	static generate_racetrack_points = function() {
		var _points	= [];
		var _num_points = irandom_range(8, 16);
		
		for (i=0; i<_num_points; i++)
		{
			var _length	= track_radius + irandom_range(-(track_radius/2), 0);
			var _dir	= (360/_num_points) * i;
			
			array_push(_points, {
				x : lengthdir_x(_length, _dir),
				y : lengthdir_y(_length, _dir)
			});
		}
		
		return _points;
	};
	
	/// @description		Convert a pointarray into a smaller scale version.
	/// @param {array<struct>}	_pointarray	Array of vector2s
	/// @param {real}		_scale		The the factor to scale each vector2 coordinates by. 
	/// @returns {array<struct>}	Returns _pointarray with positions scaled by _scale.
	static pointarray_scale = function(_pointarray, _scale) {
		var _points	= []
		var _num_points = array_length(_pointarray);
		
		for (i=0; i<_num_points; i++)
		{
			array_push(_points, {
				x : _pointarray[i].x * _scale,
				y : _pointarray[i].y * _scale
			});
		}
		
		return _points;
	};
	
	/// @description	Draws the racetrack
	/// @retuns		N/A
	static draw_racetrack = function() {
		draw_pointarray(0, 0, track, true, pr_linestrip, c_grey);
	};
	
	/// @description	Draws the racetrack
	/// @retuns		N/A
	static draw_minimap = function() {
		var _margin	= (track_radius * minimap_scale) * 2;
		var _minimap_x	= global.camera.width-_margin;
		var _minimap_y	= global.camera.height-_margin;
		
		draw_pointarray(_minimap_x, _minimap_y, minimap, true, pr_linestrip, c_grey);
		
		draw_point_color(_minimap_x+(racer.x*minimap_scale), _minimap_y+(racer.y*minimap_scale), c_yellow);
	};
}