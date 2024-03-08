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
	
	checkpoint	= {
		track_index	: 0,
		x		: 0,
		y		: 0,
		angle		: 0,
		points		: undefined,
		radius		: road_width
	};
	
	finish		= {
		x		: 0,
		y		: 0,
		angle		: 0,
		to_be_passed	: true,	// whether the finish line is reset and waiting for the next passing. Used for triggering the timer.
		timer		: 0,
		best_time	: infinity
	}
	
	
	
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
		
		var _racer_dir	= point_direction(_p1.x, _p1.y, _p2.x, _p2.y)
		
		racer ??= instance_create_depth(_p1.x, _p1.y, -1, objCar);
		racer.velocity.dir	= _racer_dir;
		racer.car_angle		= _racer_dir-90;
		
		// create finish line
		finish.x		= _p1.x + ((_p2.x - _p1.x)/2);
		finish.y		= _p1.y + ((_p2.y - _p1.y)/2);
		finish.angle		= _racer_dir-90;
		finish.to_be_passed	= true;
		finish.timer		= 0;
		finish.best_time	= infinity;
		
		// create checkpoint
		var _num_points = 32;
		
		checkpoint.track_index	= 1;
		checkpoint.x		= _p2.x;
		checkpoint.y		= _p2.y;
		checkpoint.points	= [];
		
		for (var i = 0; i < _num_points; i++)
		{
			var _dir	= (360/_num_points) * i;
			
			array_push(checkpoint.points, {
				x : lengthdir_x(checkpoint.radius, _dir),
				y : lengthdir_y(checkpoint.radius, _dir)
			});
		}
		
		// camera init
		global.camera.set_interpolation(1/4, 1/8, 1/16);
		
		global.camera.set_angle_anchor(racer);
		
		var _x_offset	= lengthdir_x(6, _racer_dir);
		var _y_offset	= lengthdir_y(6, _racer_dir);
		
		global.camera.set_start_values(racer.x+_x_offset, racer.y+_y_offset, -_racer_dir+90, 1);
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
		// finish line & timer
		if (passed_finish_line() && finish.to_be_passed)
		{
			finish.to_be_passed = false;
			
			// update best lap time
			if (finish.timer != 0)	// if this isn't the initial crossing before the first lap
			{
				var _lap_time		= get_timer() - finish.timer;
				
				finish.best_time	= min(finish.best_time, _lap_time);
			}
			
			// reset timer
			finish.timer = get_timer();
		}
		
		show_debug_message(finish)
		
		// checkpoint (and finish line reset)
		checkpoint.angle += 0.5;
		checkpoint.angle %= 360;
		
		if (point_distance(track[checkpoint.track_index].x, track[checkpoint.track_index].y, racer.x, racer.y) <= checkpoint.radius+16)
		{
			if (checkpoint.track_index != 1 || passed_finish_line()) // require passing of finish line before progressing from checkpoint 1
			{
				if (checkpoint.track_index == 1)	// if you are passing the first checkpoint
				{
					finish.to_be_passed = true;	// reset the finish line switch
				}
				
				checkpoint.track_index += 1;
				checkpoint.track_index %= array_length(track);
			}
		}
		
		checkpoint.x = lerp(checkpoint.x, track[checkpoint.track_index].x, 1/16);
		checkpoint.y = lerp(checkpoint.y, track[checkpoint.track_index].y, 1/16);
	};
	
	/// @description	The draw event, for drawing the example.
	/// @returns		N/A
	draw	= function() {
		// draw track
		draw_racetrack(road_width+64, $181C20);
		draw_racetrack(road_width+32, $444448);
		draw_racetrack(road_width+16, $111118);
		draw_racetrack(road_width+8, $CCCCCC);
		draw_racetrack(road_width, $111218);
		draw_racetrack(4, $222228);
		
		// draw finish line
		draw_sprite_ext(sprFinishLine, 0, finish.x, finish.y, 8, 8, finish.angle, $CCCCCC, 1);
		
		// draw checkpoint
		draw_checkpoint(checkpoint.x, checkpoint.y, checkpoint.angle, $CCCCCC);
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
		
		for (var i = 0; i < _num_points; i++)
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
		
		for (var i = 0; i < _num_points; i++)
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
		
		for (var i = 0; i < _num_points; i++)
		{
			var _p1 = track[i];
			var _p2	= track[(i+1) % _num_points];
			
			draw_line_width(_p1.x, _p1.y, _p2.x, _p2.y, _width);
			draw_circle(_p1.x, _p1.y, _width/2, false);
		}
	};
	
	/// @description	Checks whether the finish line has been passed. Passing is defined as being closer to track[1] than track[0] when checkpoint is at track[1].
	/// @retuns {bool}	Returns whether the finish line is triggered as having being passed on this frame (true) or (not).
	static passed_finish_line = function() {
		if (checkpoint.track_index != 1)
		{
			return false;
		}
		
		var _p0 = track[0];
		var _p1 = track[1];
		
		var _p0_dist = point_distance(_p0.x, _p0.y, racer.x, racer.y);
		var _p1_dist = point_distance(_p1.x, _p1.y, racer.x, racer.y);
		
		if (_p1_dist <= _p0_dist)
		{
			return true;
		}
		
		return false;
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
		
		// initialise surface
		surface_set_target(minimap_surface);
		draw_clear_alpha(c_black, 0);
		
		// draw track
		draw_pointarray(_halfsize, _halfsize, minimap, true, pr_linestrip, c_grey);
		
		// draw finish line
		var _p = {
			x : _halfsize + (finish.x * minimap_scale),
			y : _halfsize + (finish.y * minimap_scale)
		};
		
		var _p1 = {
			x : _p.x + lengthdir_x(3, finish.angle),
			y : _p.y + lengthdir_y(3, finish.angle)
		};
		
		var _p2 = {
			x : _p.x + lengthdir_x(3, finish.angle-180),
			y : _p.y + lengthdir_y(3, finish.angle-180)
		};
		
		draw_set_color(c_grey);
		draw_line(_p1.x, _p1.y, _p2.x, _p2.y);
		
		// draw racer
		draw_circle_color(_halfsize+(racer.x*minimap_scale), _halfsize+(racer.y*minimap_scale), 2, c_yellow, c_yellow, false);
		
		// draw surface
		var _minimap_x	= global.camera.width-_size;
		var _minimap_y	= global.camera.height-_size;
		
		surface_reset_target();
		draw_surface(minimap_surface,_minimap_x-_halfsize, _minimap_y-_halfsize);
		
		// draw times
		if (finish.timer != 0) // if this isn't prior to the first crossing of the line.
		{
			var _time		= (get_timer() - finish.timer);
			var _best		= finish.best_time;
			
			var _time_string	= get_timer_string(_time);
			var _best_time_string	= _best == infinity ? "" : get_timer_string(_best);
			
			var _prev_halign	= draw_get_halign();
			var _prev_valign	= draw_get_valign();
			
			draw_set_halign(fa_center);
			draw_set_valign(fa_top);
			draw_set_color(c_white);
			
			draw_text(_minimap_x, _minimap_y+_halfsize, _time_string + "\n" + _best_time_string);
			
			draw_set_halign(_prev_halign);
			draw_set_valign(_prev_valign);
		}
	};
	
	/// @description		Converts raw microseconds value to a displayable string.
	/// @param {real}		_time		The time to convert to a string, in microseconds (there are 1 million microseconds per second)
	/// @retuns {string}		Return string of timer.
	static get_timer_string = function(_time)
	{
		// get values
		
		var _minutes = floor(_time / 60000000);
		
		_time %= 60000000;	// remove minutes from time
		
		var _seconds = floor(_time / 1000000);
		
		_time %= 1000000;	// remove seonds from time
		
		var _milliseconds = floor(_time / 1000);
		
		// format
		
		return (string(_minutes) + ":" + string_format(_seconds, 2, 0) + "." + string_format(_milliseconds, 3, 0));
	};
	
	/// @description		Draws the checkpoint
	/// @param {real}		_x		The x coordinate to draw the checkpoint at
	/// @param {real}		_y		The y coordinate to draw the checkpoint at
	/// @param {real}		_angle		The angle to draw the checkpoint at
	/// @param {constant.Colour)	_colour		The colour to draw the checkpoint
	/// @retuns			N/A
	static draw_checkpoint = function(_x, _y, _angle, _colour) {
		var _pointarray = checkpoint.points;
		var _num_points	= array_length(_pointarray);
		
		draw_set_color(_colour);
		draw_primitive_begin(pr_linelist);
		
		for (var i = 0; i < _num_points; i++)
		{
			var _p_len	= distance_to_point(_pointarray[i].x, _pointarray[i].y);
			var _p_dir	= point_direction(0, 0, _pointarray[i].x, _pointarray[i].y);
			var _x_rotated	= lengthdir_x(_p_len, _p_dir-_angle);
			var _y_rotated	= lengthdir_y(_p_len, _p_dir-_angle);
			
			draw_vertex(_x + _x_rotated, _y + _y_rotated);
		}
		
		if (_num_points > 0)
		{
			var _p_len	= distance_to_point(_pointarray[0].x, _pointarray[0].y); //so that last point continues to first point
			var _p_dir	= point_direction(0, 0, _pointarray[0].x, _pointarray[0].y);
			var _x_rotated	= lengthdir_x(_p_len, _p_dir-_angle);
			var _y_rotated	= lengthdir_y(_p_len, _p_dir-_angle);
			
			draw_vertex(_x + _x_rotated, _y + _y_rotated);
		}
		
		draw_primitive_end();
	};
}