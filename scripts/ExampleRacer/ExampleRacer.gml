// feather ignore all



/// @function			ExampleRacer() : Example() constructor
/// @description		A racer example for a basic top-down racing game, showcasing camera rotation and shake.
/// @returns {struct.Example}
function ExampleRacer() : Example() constructor
{
	// config
	
	name		= "Racer Example";
	ui_text		= "W / up: Accelerate\nS / down: Decelerate\nA / left: turn left\nD / right: turn right";
	
	racer		= undefined;		// racer object. See .create()
	track		= undefined;		// pointarray of the track
	minimap		= undefined;		// pointarray of the minimap
	minimap_surface	= undefined;
	
	track_radius	= irandom_range(512, 2048);
	minimap_scale	= 24/track_radius;
	
	road_width	= 128;
	
	
	
	  /////////////
	 // methods //
	/////////////
	
	
	
		  ////////////
		 // events //
		////////////
	
	
	
	/// @description	The create event, for setting up the camera and example.
	/// @returns		N/A
	create	= function() {	
		// generate racetrack
		track_radius	= irandom_range(512, 2048);
		minimap_scale	= 24/track_radius;
		
		track	= generate_racetrack_points();
		minimap	= pointarray_scale(track, minimap_scale);
		
		// place racer on track
		var _p1		= track[0];
		var _p2		= track[1];
		var _dir	= point_direction(_p1.x, _p1.y, _p2.x, _p2.y)
		
		racer ??= instance_create_depth(_p1.x, _p1.y, -1, objCar);
		racer.velocity.dir	= _dir;
		racer.car_angle		= _dir-90;
		
		// camera init
		global.camera.set_interpolation(1/4, 1/8, 1/16);
		
		global.camera.set_angle_anchor(racer);
		
		var _x_offset	= lengthdir_x(6, _dir);
		var _y_offset	= lengthdir_y(6, _dir);
		
		global.camera.set_start_values(racer.x+_x_offset, racer.y+_y_offset, -_dir+90, 1);
		global.camera.reset();
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
		
		if (surface_exists(minimap_surface))
		{
			surface_free(minimap_surface);
			
			minimap_surface = undefined;
		}
	};
	
	/// @description	The step event, for code that needs to run every frame.
	/// @returns		N/A
	step	= function() {
		
	};
	
	/// @description	The draw event, for drawing the example.
	/// @returns		N/A
	draw	= function() {
		draw_racetrack(road_width+64, $181C20);
		draw_racetrack(road_width+32, $444448);
		draw_racetrack(road_width+16, $111118);
		draw_racetrack(road_width+8, $CCCCCC);
		draw_racetrack(road_width, $111218);
		draw_racetrack(4, $222228);
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
		var _num_points	= ceil(track_radius/(64+irandom_range(-8, 8)));
		
		for (i = 0; i < _num_points; i++)
		{
			var _length	= track_radius - irandom_range(track_radius/2, 0);
			var _dir	= (360/_num_points) * i;
			
			array_push(_points, {
				x : lengthdir_x(_length, _dir),
				y : lengthdir_y(_length, _dir)
			});
		}
		
		return choose(_points, array_reverse(_points));
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
	
	/// @description		Draws the racetrack
	/// @param {real}		_width		The width of the road to draw
	/// @param {constant.Colour)	_colour		The colour to draw the road
	/// @retuns			N/A
	static draw_racetrack = function(_width, _colour) {
		draw_set_color(_colour);
		
		var _num_points = array_length(track);
		
		for(i = 0; i < _num_points; i++)
		{
			var _p1 = track[i];
			var _p2	= track[(i+1) % _num_points];
			
			draw_line_width(_p1.x, _p1.y, _p2.x, _p2.y, _width);
			draw_circle(_p1.x, _p1.y, _width/2, false);
		}
	};
	
	/// @description	Draws the racetrack
	/// @retuns		N/A
	static draw_minimap = function() {
		var _size	= (track_radius * minimap_scale) * 2;
		var _halfsize	= _size/2;
		
		if (!surface_exists(minimap_surface))
		{
			minimap_surface = surface_create(_size, _size);
		}
		
		surface_set_target(minimap_surface);
		
		draw_clear_alpha(c_black, 0);
		draw_pointarray(_halfsize, _halfsize, minimap, true, pr_linestrip, c_grey);
		draw_circle_color(_halfsize+(racer.x*minimap_scale), _halfsize+(racer.y*minimap_scale), 2, c_yellow, c_yellow, false);
		
		surface_reset_target();
		
		var _minimap_x	= global.camera.width-_size;
		var _minimap_y	= global.camera.height-_size;
		
		draw_surface(minimap_surface,_minimap_x-_halfsize, _minimap_y-_halfsize);
	};
}