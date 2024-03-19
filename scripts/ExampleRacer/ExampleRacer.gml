// feather ignore all



/// @function			ExampleRacer() : Example() constructor
/// @description		A racer example for a basic top-down racing game, showcasing camera rotation and shake.
/// @returns {struct.Example}
function ExampleRacer() : Example() constructor
{
	// config
	
	name			= "Racer Example";
	ui_text			= "W / Up: accelerate\nS / Down / Space: break\nA / Left: turn left\nD / Right: turn right\nR: reset";
	
	racer			= undefined;			// racer object. See .create()
	track			= undefined;			// pointarray of the track
	minimap			= undefined;			// pointarray of the minimap
	
	minimap_surface		= undefined;			// surface for drawing minimap to gui
	speedo_surface		= undefined;			// surface for drawing speedometer to gui
	
	track_radius		= irandom_range(512, 2048);	// half-width and half-height for entire racetrack.
	minimap_scale		= 24/track_radius;		// scale to draw the minimap at.
	
	road_width		= 112;				// width (or diameter at corners) of the asphalt part of the road
	
	penalty_indication	= false;			// whether to indicate penalty on GUI
	penalty_indication_lerp	= 0;				// penalty_indication but with a lag
	
	checkpoint	= {
		track_index	: 0,
		x		: 0,
		y		: 0,
		angle		: 0,
		points		: undefined,
		radius		: road_width * 3
	};
	
	finish		= {
		x		: 0,
		y		: 0,
		angle		: 0,
		to_be_passed	: true,	// whether the finish line is reset and waiting for the next passing. Used for triggering the timer.
		timer		: 0,
		best_time	: infinity,
		last_lap_time	: infinity
	};
	
	
	
	  /////////////
	 // methods //
	/////////////
	
	
	
		  ////////////
		 // events //
		////////////
	
	
	
	/// @description	The create event, for setting up the camera and example.
	/// @param {bool}	_resetting	If the race is being reset.
	/// @returns		N/A
	create	= function(_resetting = false) {	
		// generate racetrack
		track_radius	= _resetting ? track_radius : irandom_range(512, 2048);
		minimap_scale	= 24/track_radius;
		
		track	= _resetting ? track : generate_racetrack_points();
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
		finish.best_time	= _resetting ? finish.best_time : infinity;
		finish.last_lap_time	= _resetting ? finish.last_lap_time : infinity;
		
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
		global.camera.set_shake_limits(16, 360/32, 0, 0.1, 1);
		global.camera.set_interpolation(1/4, 1/8, 1/64);
		
		global.camera.set_angle_anchor(racer);
		
		var _x_offset	= lengthdir_x(6, _racer_dir);
		var _y_offset	= lengthdir_y(6, _racer_dir);
		
		global.camera.set_start_values(racer.x+_x_offset, racer.y+_y_offset, -_racer_dir+90, 1);
		global.camera.reset();
	};
	
	/// @description	The destroy event, for cleaning up the example.
	/// @param {bool}	_resetting	If the race is being reset.
	/// @returns		N/A
	destroy	= function(_resetting = false) {
		if (racer == undefined)
		{
			return;
		}
		
		instance_destroy(racer, true);
		
		racer	= undefined;
		track	= _resetting ? track : undefined;
		minimap	= undefined;
		
		global.camera.set_position_anchor();	// unset position anchor, as racer no longer exists
		global.camera.set_angle_anchor();	// unset angle anchor, as racer no longer exists
		global.camera.set_zoom_anchor();	// unset zoom anchor, as rocer no longer exists
		
		if (surface_exists(minimap_surface))
		{
			surface_free(minimap_surface);
			surface_free(speedo_surface);
			
			minimap_surface = undefined;
			speedo_surface = undefined;
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
				finish.last_lap_time	= get_timer() - finish.timer;
				
				finish.best_time	= min(finish.best_time, finish.last_lap_time);
			}
			
			// reset timer
			finish.timer = get_timer();
		}
		
		// checkpoint (and finish line reset)
		checkpoint.angle += 0.5;
		checkpoint.angle %= 360;
		
		var _i = checkpoint.track_index;
		var _backup_i = min(checkpoint.track_index+1, array_length(track)-1);
		
		var _checkpoint_met = point_distance(track[_i].x, track[_i].y, racer.x, racer.y) <= checkpoint.radius+16;
		var _backup_checkpoint_met = point_distance(track[_backup_i].x, track[_backup_i].y, racer.x, racer.y) <= checkpoint.radius+16;
		
		if (_checkpoint_met || _backup_checkpoint_met)
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
		
		checkpoint.x = lerp(checkpoint.x, track[checkpoint.track_index].x, 1/4);
		checkpoint.y = lerp(checkpoint.y, track[checkpoint.track_index].y, 1/4);
		
		// rumble and slowdown if offroad
		
		penalty_indication	= false;
		
		if (distance_to_track() > road_width/2)
		{
			penalty_indication				= true;
			
			// penalty
			var _distance_over_road_edge			= distance_to_track() - (road_width/2);
			
			var _ratio_from_edge_to_max_penalty_dist	= max(0, _distance_over_road_edge) / (road_width/8);
			var _ratio_max_torque				= abs(racer.torque) / racer.max_torque;
			
			var _penalty_factor				= _ratio_from_edge_to_max_penalty_dist * _ratio_max_torque;
			
			var _max_torque_penalty				= racer.max_torque/2;
			var _torque_penalty				= _penalty_factor * _max_torque_penalty;
			
			var _new_torque					= racer.torque >= 0 ? min(racer.torque, racer.max_torque - _torque_penalty) : max(racer.torque, -(racer.max_torque - _torque_penalty));
			
			racer.torque					= lerp(racer.torque, _new_torque, 0.1);
			
			// shake
			global.camera.shake_to(_penalty_factor);
		}
		
		// reset
		if (keyboard_check_pressed(ord("R")))
		{
			global.camera.reset(true, true);
			
			destroy(true);
			create(true);
		}
	};
	
	/// @description	The draw event, for drawing the example.
	/// @returns		N/A
	draw	= function() {
		// draw track
		draw_racetrack(road_width+48, $181C20);
		draw_racetrack(road_width+16, $444448);
		draw_racetrack(road_width, $111118);
		draw_racetrack(road_width-8, $CCCCCC);
		draw_racetrack(road_width-16, $111218);
		draw_racetrack(4, $222228);
		
		// draw finish line
		draw_sprite_ext(sprFinishLine, 0, finish.x, finish.y, 8, 8, finish.angle, $CCCCCC, 1);
		
		// draw checkpoint & backup checkpoint
		if (global.loader.show_help_text) // only show if loader help is on
		{
			var _backup_i = min(checkpoint.track_index+1, array_length(track)-1);
			
			draw_checkpoint(track[_backup_i].x, track[_backup_i].y, checkpoint.angle, $444448);
			draw_checkpoint(checkpoint.x, checkpoint.y, checkpoint.angle, $CCCCCC);
		}
	};
	
	/// @description	The draw gui event, for any drawing to the gui.
	/// @returns		N/A
	draw_gui = function() {
		draw_minimap();
		draw_times();
		draw_speedometer();
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
	
	/// @description	Returns the distance to the center of the racetrack
	/// @returns {real}	N/A
	static distance_to_track = function() {
		// find nearest point (_p1)
		
		var _nearest_point_i	= 0;
		var _nearest_dist	= infinity;
		
		var _num_points = array_length(track);
		
		for (var i = 0; i < _num_points; i++)
		{
			var _p = track[i];
			
			var _dist = point_distance(_p.x, _p.y, racer.x, racer.y);
			
			if (_dist < _nearest_dist)
			{
				_nearest_dist		= _dist;
				_nearest_point_i	= i;
			}
		}
		
		var _p1 = track[_nearest_point_i];
		
		// find p1's neighbour which forms the line segment that is nearest(_p2), to complete the nearest line segment (_p1, _p2)
		
		var _p_left		= track[ wrap(_nearest_point_i-1, 0, _num_points) ];
		var _p_right		= track[ wrap(_nearest_point_i+1, 0, _num_points) ];
		
		var _p1_dir		= point_direction(_p1.x, _p1.y, racer.x, racer.y);
		var _p_left_dir		= point_direction(_p1.x, _p1.y, _p_left.x, _p_left.y);		// compare angles because if p1 is the closest point then the nearest line segment is determined by the smallest angle difference
		var _p_right_dir	= point_direction(_p1.x, _p1.y, _p_right.x, _p_right.y);
		
		var _p_left_diff	= abs(_p1_dir - _p_left_dir) % 360;				// calculate angle difference
		var _p_right_diff	= abs(_p1_dir - _p_right_dir) % 360;
		
		_p_left_diff	= _p_left_diff > 180 ? 360 - _p_left_diff : _p_left_diff;		// choose smallest engle of clockwise or counterclockwise te represent the difference
		_p_right_diff	= _p_right_diff > 180 ? 360 - _p_right_diff : _p_right_diff;
		
		if (_p_left_diff >= 90 && _p_right_diff >= 90)
		{
			return _nearest_dist;	// if both of the angle differences are more than 90 degrees, _p1 is closer than any point on the two line segments, so _p1 represents the shortest point on the track.
		}
		
		var _p2			= (_p_left_diff < _p_right_diff) ? _p_left : _p_right;
		var _p2_dir		= (_p_left_diff < _p_right_diff) ? _p_left_dir : _p_right_dir;
		
		var _p2_length		= point_distance(_p1.x, _p1.y, _p2.x, _p2.y);
		var _frac_of_length	= _nearest_dist / (_nearest_dist + point_distance(_p2.x, _p2.y, racer.x, racer.y));	// the nearest point along the length of the line segment is found by adding the distance of each point to the racer together and finding the ratio of the nearest point's distance to the racer out of the total.
		
		var _p3_length		= _p2_length * _frac_of_length; // reduce length to the point along it that is closest to the racer.
		
		var _p3	= {
			x : _p1.x + lengthdir_x(_p3_length, _p2_dir),
			y : _p1.y + lengthdir_y(_p3_length, _p2_dir)
		}; // nearest point along line segment
		
		_nearest_dist		= point_distance(_p3.x, _p3.y, racer.x, racer.y);
		
		return _nearest_dist;
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
	
	/// @description	Draws a minimap of the racetrack to the GUI
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
		
		// calculate finish line
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
		
		// draw shadows - track
		draw_pointarray(_halfsize-1, _halfsize+1, minimap, true, pr_linestrip, c_black);
		draw_pointarray(_halfsize, _halfsize+1, minimap, true, pr_linestrip, c_black);
		
		// draw shadows - finish line
		draw_set_color(c_black);
		draw_line(_p1.x-1, _p1.y+1, _p2.x-1, _p2.y+1);
		draw_line(_p1.x, _p1.y+1, _p2.x, _p2.y+1);
		
		// draw shadows - racer
		draw_circle_color(_halfsize+(racer.x*minimap_scale)-1, _halfsize+(racer.y*minimap_scale)+1, 2, c_black, c_black, false);
		draw_circle_color(_halfsize+(racer.x*minimap_scale), _halfsize+(racer.y*minimap_scale)+1, 2, c_black, c_black, false);
		
		// draw track
		draw_pointarray(_halfsize, _halfsize, minimap, true, pr_linestrip, c_grey);
		
		// draw finish line
		draw_set_color(c_grey);
		draw_line(_p1.x, _p1.y, _p2.x, _p2.y);
		
		// draw racer
		draw_circle_color(_halfsize+(racer.x*minimap_scale), _halfsize+(racer.y*minimap_scale), 2, c_yellow, c_yellow, false);
		
		// draw surface
		var _minimap_x	= global.camera.get_width()-_size;
		var _minimap_y	= global.camera.get_height()-_size;
		
		surface_reset_target();
		draw_surface(minimap_surface,_minimap_x-_halfsize, _minimap_y-_halfsize);
	};
	
	/// @description	Draws on-screen timer and lap times to the GUI.
	/// @retuns		N/A
	static draw_times = function() {
		//if (finish.timer != 0) // if this isn't prior to the first crossing of the line.
		{
			var _time		= (finish.timer == 0) ? 0 : (get_timer() - finish.timer);
			var _best		= finish.best_time;
			var _lap		= finish.last_lap_time == _best ? infinity : finish.last_lap_time;	// only get lap time if it is different from best time
			
			var _time_string	= get_timer_string(_time);
			var _best_time_string	= _best == infinity ? "" : get_timer_string(_best);
			var _lap_time_string	= _lap == infinity ? "" : " \n" + get_timer_string(_lap);
			
			var _prev_halign	= draw_get_halign();
			var _prev_valign	= draw_get_valign();
			
			var _size		= (track_radius * minimap_scale) * 2;
			var _minimap_x		= global.camera.get_width()-_size;
			var _minimap_y		= global.camera.get_height()-_size;
			
			// time
			draw_set_valign(fa_bottom);
			draw_set_halign(fa_middle);
			
			draw_set_color(c_black);
			draw_text(_minimap_x-1, (global.camera.get_height()-8)+1, _time_string);
			draw_text(_minimap_x, (global.camera.get_height()-8)+1, _time_string);
			
			draw_set_color($CCCCCC);
			draw_text(_minimap_x, global.camera.get_height()-8, _time_string);
			
			// best time
			draw_set_valign(fa_top);
			
			draw_set_color(c_black);
			draw_text(_minimap_x-1, 10+1, _best_time_string);
			draw_text(_minimap_x, 10+1, _best_time_string);
			
			draw_text_color(_minimap_x, 10, _best_time_string, $20FFFF, c_yellow, c_green, c_lime, 1);
			
			// lap time
			draw_text(_minimap_x-1, 10+1, _lap_time_string);
			draw_text(_minimap_x, 10+1, _lap_time_string);
			
			draw_set_color($CCCCCC);
			draw_text(_minimap_x, 10, _lap_time_string);
			
			// reset align
			draw_set_halign(_prev_halign);
			draw_set_valign(_prev_valign);
		}
	};
	
	/// @description	Draws on-screen speedometer to GUI.
	/// @retuns		N/A
	static draw_speedometer = function() {
		var _minimap_size	= (track_radius * minimap_scale) * 2;
		var _minimap_halfsize	= _minimap_size/2;
		
		var _speedometer_size	= 24;
		var _speedometer_radius	= _speedometer_size/2;
		var _needle_length	= 5;
		var _guage_ends_length	= 5;
		
		var _minimap_x		= global.camera.get_width() - _minimap_size;
		var _minimap_y		= global.camera.get_height() - _minimap_size;
		
		var _gear		= ceil(racer.torque);
		var _gear_str		= (_gear >= 1) ? string(_gear) : ((racer.torque == 0) ? "P" : "R");
		var _needle_percent	= racer.torque - (_gear-1);
		
		var _guage_angle_start	= 180;
		var _guage_angle_range	= -135;
		var _needle_angle	= _guage_angle_start + (_needle_percent * _guage_angle_range);
		
		var _penalty_dot_radius	= 2.6;
		
		var _prev_halign	= draw_get_halign();
		var _prev_valign	= draw_get_valign();
		
		if (!surface_exists(speedo_surface))
		{
			speedo_surface = surface_create(_speedometer_size, _speedometer_size);
		}
		
		// initialise surface
		surface_set_target(speedo_surface);
		draw_clear_alpha(c_black, 0);
		
		// draw background semicircle
		draw_set_color(c_black);
		draw_circle(_speedometer_radius-1, _speedometer_radius-1, 8, false);
		// (undraw bottom of circle)
		gpu_set_blendmode(bm_subtract);
		draw_rectangle(-_speedometer_radius, _speedometer_radius+4, _speedometer_size, _speedometer_size, false);
		gpu_set_blendmode(bm_normal);
		
		// draw guage ends
		var _start_x2	= _speedometer_radius + lengthdir_x(_speedometer_radius, _guage_angle_start);
		var _start_y2	= _speedometer_radius + lengthdir_y(_speedometer_radius, _guage_angle_start);
		var _start_x1	= _start_x2 + lengthdir_x(_guage_ends_length, _guage_angle_start - 180);
		var _start_y1	= _start_y2 + lengthdir_y(_guage_ends_length, _guage_angle_start - 180);
		var _end_x2	= _speedometer_radius + lengthdir_x(_speedometer_radius, _guage_angle_start + _guage_angle_range);
		var _end_y2	= _speedometer_radius + lengthdir_y(_speedometer_radius, _guage_angle_start + _guage_angle_range);
		var _end_x1	= _end_x2 + lengthdir_x(_guage_ends_length, (_guage_angle_start + _guage_angle_range) - 180);
		var _end_y1	= _end_y2 + lengthdir_y(_guage_ends_length, (_guage_angle_start + _guage_angle_range) - 180);
		
		draw_set_color(c_black);
		draw_line(_start_x1-1, _start_y1+1, _start_x2-1, _start_y2+1);
		draw_line(_start_x1, _start_y1+1, _start_x2, _start_y2+1);
		draw_line(_end_x1-1, _end_y1+1, _end_x2-1, _end_y2+1);
		draw_line(_end_x1, _end_y1+1, _end_x2, _end_y2+1);
		draw_set_color(c_grey);
		draw_line(_start_x1, _start_y1, _start_x2, _start_y2);
		draw_line(_end_x1, _end_y1, _end_x2, _end_y2);
		
		// draw needle
		var _needle_x2	= _speedometer_radius + lengthdir_x(_speedometer_radius, _needle_angle);
		var _needle_y2	= _speedometer_radius + lengthdir_y(_speedometer_radius, _needle_angle);
		var _needle_x1	= _needle_x2 + lengthdir_x(_needle_length, _needle_angle - 180);
		var _needle_y1	= _needle_y2 + lengthdir_y(_needle_length, _needle_angle - 180);
		
		draw_set_color(c_black);
		draw_line(_needle_x1-1, _needle_y1+1, _needle_x2-1, _needle_y2+1);
		draw_line(_needle_x1, _needle_y1+1, _needle_x2, _needle_y2+1);
		draw_set_color($0000CC);
		draw_line(_needle_x1, _needle_y1, _needle_x2, _needle_y2);
		
		// draw gear
		draw_set_valign(fa_middle);
		draw_set_halign(fa_center);
		
		draw_set_color(c_black);
		draw_text(_speedometer_radius-1, _speedometer_radius+1, _gear_str);
		draw_text(_speedometer_radius, _speedometer_radius+1, _gear_str);
		
		if (_gear >= 7)
		{
			draw_text_color(_speedometer_radius, _speedometer_radius, _gear_str, $20FFFF, c_yellow, c_green, c_lime, 1);
		}
		else
		{
			draw_set_color((racer.torque < 0) ? $0000AA : $CCCCCC);
			draw_text(_speedometer_radius, _speedometer_radius, _gear_str);
		}
		
		// draw penalty indicator
		draw_set_color(c_black)
		draw_circle((_speedometer_radius * 1.5)+1, _speedometer_radius, _penalty_dot_radius, false);
		draw_circle((_speedometer_radius * 1.5)+2, _speedometer_radius, _penalty_dot_radius, false);
		
		penalty_indication_lerp = lerp(penalty_indication_lerp, real(penalty_indication || racer.input.decelerate), 0.2);
		
		draw_set_color(penalty_indication_lerp * $0000CC);
		draw_circle((_speedometer_radius * 1.5)+2, _speedometer_radius - 1, _penalty_dot_radius, false);
		
		// draw surface
		surface_reset_target();
		draw_surface(speedo_surface, (global.camera.get_width()/2) - _speedometer_radius, global.camera.get_height() - _speedometer_size - 2);
		
		// reset align
		draw_set_halign(_prev_halign);
		draw_set_valign(_prev_valign);
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
		
		_time %= 1000000;	// remove seconds from time
		
		var _milliseconds	= floor(_time / 1000);
		
		// format
		
		var _str_minutes	= string(_minutes) + ":";
		var _str_seconds	= string_format(_seconds, 2, 0) + ".";
		var _str_milliseconds	= string_format(_milliseconds, 3, 0);
		
		var _timer_string	= _str_minutes + _str_seconds + _str_milliseconds;
		
		return string_replace_all(_timer_string, " ", "0");
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
		
		draw_primitive_end();
	};
}