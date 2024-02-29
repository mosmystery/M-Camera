/// @function		MCamera(_width, _height, _window_scale, _pixel_scale, _create_host_object_for_me);
/// @description	A system designed to manage the view's scale, resolution, movement, rotation, etc.
/// @param {real}	[_width=320]				The width of the display in pixels. Recomended to be a division of the width of your desired resolution, such as 1920/6=320, to suit 1920x1080 monitor resolution.
/// @param {real}	[_height=180]				The height of the display in pixels. Recomended to be a division of the height of your desired resolution, such as 1080/6=180, to suit 1920x1080 monitor resolution.
/// @param {real}	[_window_scale=4]			The scale to draw the display at when in windowed mode, as a multiple of width and height.
/// @param {real}	[_pixel_scale=1]			The width and height of each pixel, in subpixels. _window_scale needs to be >= _pixel_scale for all sub-pixels to be visible.
///								Examples: Pass `1` for true-to-size pixels, `2` for pixels with a resolution of 2x2 subpixels, or pass the same value as _window_scale to match the subpixel size to the actual pixel size on the display.
/// @param {bool}	[_create_host_object_for_me=true]	Whether to create a permanent host object that runs the event methods automatically (true) or not (false). Useful if you want to run the event methods in a different event or manage the hose object yourself.
///								If false:	You will need to run this camera's .room_start(), .end_step(), and optionally .draw_end() events in a permanent object for intended results.
///								If true:	An instance of objMCamera, a shell for this constructor's event methods, will automatically be created and stored in .host_object.
/// @returns {struct.MCamera}
function MCamera(_width = 320, _height = 180, _window_scale = 4, _pixel_scale = 1, _create_host_object_for_me = true) constructor
{
	// camera
	
	host_object	= undefined;		// See .create()
	
	view		= 0;			// See .set_view()
	id		= view_camera[view];	// The view port id for this camera. See view_camera in the manual.
	
	width		= _width;		// The base, unscaled width of the view
	height		= _height;		// The base, unscaled height of the view
	window_scale	= _window_scale;	// The scale of width, height to apply to the window.
	pixel_scale	= _pixel_scale;		// The detail (width, height) of each pixel. Scales the application surface, but not the window or view. Only noticable at window scales higher than 1.
	
	x		= width/2;		// The current x position for this camera. Equivalent to the center of the screen in world co-ordinates.
	y		= height/2;		// The current y position for this camera. Equivalent to the center of the screen in world co-ordinates.
	angle		= 0;			// The current angle for this camera, in degrees.
	zoom		= 1;			// The current zoom factor for this camera. <1 = zoom in, else 1 = normal, else <0 = zoom out.
	
	// transform
	
	start		= {
		x	: x,
		y	: y,
		angle	: angle,
		zoom	: zoom
	};					// See .set_start_values() .reset()
	
	previous	= {
		x	: x,
		y	: y,
		angle	: angle,
		zoom	: zoom
	};					// The transform values from the previous step.
	
	target		= {
		x	: x,			// See .move_to(),	.move_by()
		y	: y,			// See .move_to(),	.move_by()
		angle	: angle,		// See .rotate_to(),	.rotate_by()
		zoom	: zoom			// See .zoom_to(),	.zoom_by()
	};					// See .transform_to(),	.transform_by()
	
	interpolation	= {
		position	: 1/8,		// See .set_position_interpolation()
		angle		: 1/4,		// See .set_angle_interpolation()
		zoom		: 1/16,		// See .set_zoom_interpolation()
		fn_position	: lerp,		// Custom interpolation function. See .set_position_interpolation()
		fn_angle	: lerp,		// Custom interpolation function. See .set_angle_interpolation()
		fn_zoom		: lerp		// Custom interpolation function. See .set_zoom_interpolation()
	};
	
	// constraints
	
	anchors		= {
		position	: undefined,	// See .set_position_anchor()
		angle		: undefined,	// See .set_rotation_anchor()
		zoom		: undefined	// See .set_zoom_anchor()
	};
	
	boundary	= undefined;		// See .set_boundary()
	
	zoom_min	= 1/power(2, 16);	// See .set_zoom_limits()
	zoom_max	= power(2, 16);		// See .set_zoom_limits()
	
	// panning
	
	panning		= {
		active	: false,		// Whether panning mode is active or not. See .is_panning()
		start	: {
			x	: x,
			y	: y,
			angle	: angle,
			zoom	: zoom
		},				// The user-defined starting transform values for the pan. See .start_panning()
		target	: {
			x	: x,
			y	: y,
			angle	: angle,
			zoom	: zoom
		}				// The user-defined target transform values for the pan. See .start_panning()
	};					// See .is_panning(), .start_panning(), .stop_panning(), .pan_to()
	
	// shake
	
	shake = {
		x			: 0,	// The shake x position offset.
		y			: 0,	// The shake y position offset.
		angle			: 0,	// The shake angle offset.
		zoom			: 1,	// The shake zoom offset.
		intensity		: 0,	// The intensity of the shake. Is a multiplier for the transform values. 0 = No shake. 1 = match transform to limits. See .shake_to()
		intensity_falloff_rate	: 0.05,	// The falloff rate of intensity each step. See .set_shake_interpolation()
		fn_intensity		: lerp,	// Custom interpolation function for the intensity falloff. See .set_shake_interpolation()
		coarseness		: 0.25,	// How coarse the raw transform values should change each step. 1 = white noise. >0 <1 = brown noise. See .set_shake_limits()
		raw	: {
			distance	: 0,
			direction	: 0,
			angle		: 0,
			zoom		: 0
		},				// The raw internal tranform values. These are used to calculate shake.x .y .angle .zoom
		limits : {
			radius		: 4,
			angle		: 22.5,
			zoom		: 1,
			intensity	: infinity
		}				// The maximum range for shake transform values. See .set_shake_limits()
	};					// See .set_shake_limits(), .set_shake_interpolation() .shake_to()
	
	// debug
	
	debug		= {
		active		: false,	// See .is_debugging(), .set_debugging()
		rotation	: {
			points	: []		// For internal use. Used to store and display the rotation arc in debug mode.
		},
		panning		: {
			camera_start_x	: x,	// The camera's starting x co-ordinate during panning.
			camera_start_y	: y	// The camera's starting y co-ordinate during panning.
		}
	};
	
	
	
	  /////////////
	 // methods //
	/////////////
	
	
	
		  ////////////
		 // events //
		////////////
	
	
	
	/// @function		create(_create_host_object_for_me)
	/// @description	The Create event. Initialises the camera.
	/// @param {bool}	[_create_host_object_for_me=true]	Whether to create a permanent host object that runs the event methods automatically (true) or not (false). Useful if you want to run the event methods in a different event or manage the hose object yourself.
	///								If false:	You will need to run this camera's .room_start(), .end_step(), and optionally .draw_end() events in a permanent object for intended results.
	///								If true:	An instance of objMCamera, a shell for this constructor's event methods, will automatically be created and stored in .host_object.
	/// @returns		N/A
	static create = function(_create_host_object_for_me = true) {
		// create host object
		if (_create_host_object_for_me)
		{
			host_object		= instance_create_depth(0, 0, -1, objMCamera);
			host_object.camera	= self;
		}
	
		// set target position
		if (anchors.position != undefined)
		{
			target.x	= anchors.position.x;
			target.y	= anchors.position.y;
		}
		
		// initialise window
		surface_resize(application_surface, width * pixel_scale, height * pixel_scale);
		display_set_gui_size(width, height);
		window_set_size(width * window_scale, height * window_scale);
		window_center();
		
		// initialise shake
		__shake_reset_transform();
	};
	
	/// @function		room_start()
	/// @description	The Room Start event. Enables the view for this room.
	/// @returns		N/A
	static room_start = function() {
		view_enabled		= true;
		view_visible[view]	= true;
	};
	
	/// @function		end_step()
	/// @description	The End Step event. Updates the camera tranform.
	/// @returns		N/A
	static end_step = function() {
		// update transform
		previous.x	= x;
		previous.y	= y;
		previous.angle	= angle;
		previous.zoom	= zoom;
		
		x		= interpolation.fn_position(x, target.x, interpolation.position);
		y		= interpolation.fn_position(y, target.y, interpolation.position);
		angle		= interpolation.fn_angle(angle, target.angle, interpolation.angle);
		zoom		= interpolation.fn_zoom(zoom, target.zoom, interpolation.zoom);
		
		// apply constraints
		__enforce_zoom_anchor(anchors.zoom);
		__enforce_angle_anchor(anchors.angle);
		__enforce_position_anchor(anchors.position);
		__apply_panning(anchors.angle);
		__clamp_to_boundary(boundary);
		__update_shake(anchors.zoom);
		
		// update view
		camera_set_view_size(id, view_width() / shake.zoom, view_height() / shake.zoom);
		camera_set_view_angle(id, angle + shake.angle);
		camera_set_view_pos(id, view_x() + shake.x, view_y() + shake.y);
	};
	
	/// @function		draw_end()
	/// @description	The Draw End event, for drawing the camera debug overlay.
	/// @returns		N/A
	static draw_end = function() {
		__debug_draw();
	};
	
	
	
		  //////////////////////////////////////
		 // event helpers - for internal use //
		//////////////////////////////////////
	
	
	
	/// @function							__enforce_position_anchor(_anchor)
	/// @description						For internal use. Updates the camera position based on _anchor's position, to keep the anchor at the same place on-screen while adjusting position.
	/// @param {struct,id.Instance,asset.GMObject,undefined}	[_anchor=anchors.position]	The position anchor. Must contain an x and y value if not undefined.
	/// @returns							N/A
	static __enforce_position_anchor = function(_anchor=anchors.position) {
		if (_anchor != undefined)
		{
			target.x = _anchor.x;
			target.y = _anchor.y;
		}
	};
	
	/// @function							__enforce_angle_anchor(_anchor)
	/// @description						For internal use. Updates the camera position based on _anchor's position, to keep the anchor at the same place on-screen while adjusting angle.
	/// @param {struct,id.Instance,asset.GMObject,undefined}	[_anchor=anchors.angle]	The angle anchor. Must contain an x and y value if not undefined.
	/// @returns							N/A
	static __enforce_angle_anchor = function(_anchor=anchors.angle) {
		if (angle != previous.angle && _anchor != undefined)
		{
			if (is_debugging() && abs(previous.angle - angle) >= 0.5)
			{
				array_push(debug.rotation.points, {
					x : x,
					y : y
				});
			}
			
			var _distance	= point_distance(_anchor.x, _anchor.y, x, y);
			var _direction	= point_direction(_anchor.x, _anchor.y, x, y) + (previous.angle - angle);
			
			var _relative_x	= lengthdir_x(_distance, _direction);
			var _relative_y	= lengthdir_y(_distance, _direction);
			
			target.x	= _anchor.x + _relative_x;
			target.y	= _anchor.y + _relative_y;
			
			x		= target.x;
			y		= target.y;
		}
	};
	
	/// @function							__enforce_zoom_anchor(_anchor)
	/// @description						For internal use. Updates the camera position based on _anchor's position, to keep the anchor at the same place on-screen while adjusting zoom.
	/// @param {struct,id.Instance,asset.GMObject,undefined}	[_anchor=anchors.zoom]	The zoom anchor. Must contain an x and y value if not undefined.
	/// @returns							N/A
	static __enforce_zoom_anchor = function(_anchor=anchors.zoom) {
		if (zoom != previous.zoom && _anchor != undefined)
		{
			var _screen_ratio_w	= (_anchor.x - camera_get_view_x(id)) / camera_get_view_width(id);	// camera_get[...]() functions get values previously set with camera_set[...]()
			var _screen_ratio_h	= (_anchor.y - camera_get_view_y(id)) / camera_get_view_height(id);
			
			target.x		= (_anchor.x - (view_width() * _screen_ratio_w)) + (view_width()/2);
			target.y		= (_anchor.y - (view_height() * _screen_ratio_h)) + (view_height()/2);
			
			x			= target.x;
			y			= target.y;
		}
	};
	
	/// @function							__apply_panning(_angle_anchor)
	/// @description						For internal use. Updates the camera position based on the panning start and target values, and angle angle.
	/// @param {struct,id.Instance,asset.GMObject,undefined}	[_angle_anchor=anchors.angle]	The angle anchor. Must contain an x and y value if not undefined.
	/// @returns							N/A
	static __apply_panning = function(_angle_anchor=anchors.angle) {
		if (!is_panning())
		{
			return;
		}
		
		if (_angle_anchor == undefined)
		{
			target.x	-= panning.target.x - panning.start.x;
			target.y	-= panning.target.y - panning.start.y;
			
			x		= target.x;
			y		= target.y;
			
			return;
		}
		
		var _angle_diff		= panning.start.angle - previous.angle;
		
		var _pan_distance	= point_distance(_angle_anchor.x, _angle_anchor.y, panning.start.x, panning.start.y);
		var _pan_direction	= point_direction(_angle_anchor.x, _angle_anchor.y, panning.start.x, panning.start.y) + _angle_diff;
		
		var _rotated_pan_x	= _angle_anchor.x + lengthdir_x(_pan_distance, _pan_direction);
		var _rotated_pan_y	= _angle_anchor.y + lengthdir_y(_pan_distance, _pan_direction);
		
		var _relative_target_x	= panning.target.x - _rotated_pan_x;
		var _relative_target_y	= panning.target.y - _rotated_pan_y;
		
		var _angle_is_cardinal	= (_angle_diff+360) mod 90 <= math_get_epsilon() || (_angle_diff+360) mod 90 >= 90 - math_get_epsilon();
		
		target.x		-= _angle_is_cardinal ? _relative_target_x : round(_relative_target_x);		// round co-ordinates at odd relative angles to avoid jitteriness
		target.y		-= _angle_is_cardinal ? _relative_target_y : round(_relative_target_y);		// round co-ordinates at odd relative angles to avoid jitteriness
		
		x			= target.x;
		y			= target.y;
	};
	
	/// @function			__clamp_to_boundary(_rect)
	/// @description		For internal use. Clamps the camera position to be within boundary _rect.
	/// @param {struct,undefined}	[_rect=boundary]	The struct defining the boundary rectangle, or undefined for no clamping. Must contain x1, y1, x2, y2 values. Example: { x1=0, y1=0, x2=width, y2=height }
	/// @returns			N/A
	static __clamp_to_boundary = function(_rect = boundary) {
		if (_rect != undefined)
		{
			var _width_ratio	= abs( lengthdir_x(1, angle) );
			var _height_ratio	= abs( lengthdir_y(1, angle) );
			
			var _rotated_width	= (_width_ratio * view_width()) + (_height_ratio * view_height());
			var _rotated_height	= (_width_ratio * view_height()) + (_height_ratio * view_width());
			
			var _boundary_width	= _rect.x2 - _rect.x1;
			var _boundary_height	= _rect.y2 - _rect.y1;
			
			target.x		= (_rotated_width > _boundary_width)	? (_rect.x1 + _boundary_width/2)	: clamp(x, _rect.x1 + (_rotated_width/2), _rect.x2 - (_rotated_width/2));
			target.y		= (_rotated_height > _boundary_height)	? (_rect.y1 + _boundary_height/2)	: clamp(y, _rect.y1 + (_rotated_height/2), _rect.y2 - (_rotated_height/2));
			
			x			= target.x;
			y			= target.y;
		}
	};
	
	/// @function							__update_shake(_zoom_anchor)
	/// @description						For internal use. Updates the shake transform and intensity based on anchors and shake members.
	/// @param {struct,id.Instance,asset.GMObject,undefined}	[_zoom_anchor=anchors.zoom]	The zoom anchor. Must contain an x and y value if not undefined.
	///								Warning: if _zoom_anchor does not equal that of .__enforce_zoom_anchor(), the camera will drift when simultaneously zooming and shaking.
	/// @returns		N/A
	static __update_shake = function(_zoom_anchor=anchors.zoom) {
		if (shake.intensity == 0)
		{
			return;
		}
		
		with (shake)
		{
			// set raw values
			raw.distance	+= coarseness * random_range(-limits.radius, limits.radius);
			raw.direction	+= coarseness * random_range(-180, 180);
			raw.angle	+= coarseness * random_range(-limits.angle, limits.angle);
			raw.zoom	+= coarseness * random_range(-limits.zoom, limits.zoom);
			
			raw.distance	= reflect(raw.distance, -limits.radius, limits.radius);
			raw.direction	= wrap(raw.direction, -180, 180);
			raw.angle	= reflect(raw.angle, 0, limits.angle);
			raw.zoom	= reflect(raw.zoom, -(limits.zoom/2), limits.zoom/2);
			
			// set output values
			x		= lengthdir_x(intensity * raw.distance, raw.direction);
			y		= lengthdir_y(intensity * raw.distance, raw.direction);
			angle		= (intensity * raw.angle) - (intensity * (limits.angle/2));
			zoom		= power(sqrt(2), intensity * raw.zoom);
			
			// enforce zoom anchor
			if (_zoom_anchor != undefined)
			{
				// center camera
				var _next_view_width	= other.view_width() / zoom;	// next values are used so that shake is applied to the the camera transform calculated this frame
				var _next_view_height	= other.view_height() / zoom;
				var _diff_width		= _next_view_width - other.view_width();
				var _diff_height	= _next_view_height - other.view_height();
				
				var _screen_ratio_w	= (other.x - other.view_x()) / _next_view_width;
				var _screen_ratio_h	= (other.y - other.view_y()) / _next_view_height;
				
				var _x_in_world		= (other.x - (_screen_ratio_w * _next_view_width)) + (_next_view_width/2);
				var _y_in_world		= (other.y - (_screen_ratio_h * _next_view_height)) + (_next_view_height/2);
				
				x			-= _x_in_world - other.x;	// try to simplify the zoom code by removing this line and reworking the final xy
				y			-= _y_in_world - other.y;	// ''
				
				// offset camera by anchor ratio of screen size difference (wip)
				var _screen_ratio_w	= (_zoom_anchor.x - other.view_x()) / other.view_width();
				var _screen_ratio_h	= (_zoom_anchor.y - other.view_y()) / other.view_height();
			
				var _x_relative		= (_diff_width * _screen_ratio_w) - (_diff_width/2);
				var _y_relative		= (_diff_height * _screen_ratio_h) - (_diff_height/2);
				
				x			-= _x_relative;
				y			-= _y_relative;
			}
			
			// intensity falloff
			intensity	= fn_intensity(intensity, 0, intensity_falloff_rate);
		}
		
		// reset transform
		if (abs(shake.intensity) <= math_get_epsilon())
		{
			shake.intensity	= 0;
			
			__shake_reset_transform();
		}
	};
	
	/// @function		__shake_reset_transform()
	/// @description	For internal use. Resets the shake transform to initial values.
	/// @returns		N/A
	static __shake_reset_transform = function() {
		shake.raw.distance	= 0;
		shake.raw.direction	= random(360)-180;
		shake.raw.angle		= shake.limits.angle/2;
		shake.raw.zoom		= 0;
	};
	
	/// @function		__debug_draw()
	/// @description	For internal use. Draws the debug display.
	/// @returns		N/A
	static __debug_draw = function() {
		if (!is_debugging())
		{
			return;
		}
		
		// setup
		var _col_boundary	= c_white;
		var _col_pos		= c_white;
		var _col_rot_arc	= c_grey;
		var _col_view		= c_yellow;
		var _col_target		= c_red;
		var _col_rot_anchor	= _col_rot_arc;
		var _col_zoom_anchor	= c_blue;
		var _col_pan_line	= c_green;
			
		var _nav_dots_radius	= 2 / zoom;
		var _nav_ring_radius	= 16 / zoom;
		var _nav_dotring_radius	= _nav_ring_radius + (4 / zoom);
		var _dot_radius		= clamp(4, _nav_dots_radius, _nav_ring_radius);
			
		var _po			= 1; // pixel offset
			
		// boundary
		if (boundary != undefined)
		{
			draw_rectangle_colour(boundary.x1+0.5, boundary.y1+0.5, boundary.x2-1.5, boundary.y2-1.5, _col_boundary, _col_boundary, _col_boundary, _col_boundary, true);
		}
		
			// dots
		
		// rotation arc
		var _rot_arc_length = array_length(debug.rotation.points);
			
		if (_rot_arc_length >= 1)
		{
			draw_pointarray(0, 0, debug.rotation.points, false, pr_linestrip, _col_rot_arc);
			draw_circle_color(debug.rotation.points[0].x-_po, debug.rotation.points[0].y-_po, _dot_radius, _col_rot_arc, _col_rot_arc, false);
			draw_circle_color(debug.rotation.points[_rot_arc_length-1].x-_po, debug.rotation.points[_rot_arc_length-1].y-_po, _dot_radius, _col_rot_arc, _col_rot_arc, false);
		}
			
		// rotation anchor
		if (anchors.angle != undefined)
		{
			draw_circle_color(anchors.angle.x-_po, anchors.angle.y-_po, _dot_radius, _col_rot_anchor, _col_rot_anchor, false);
		}
		
		// pan line
		if (is_panning())
		{
			var _x1 = panning.start.x;
			var _y1 = panning.start.y;
			var _x2 = target.x + (panning.start.x - debug.panning.camera_start_x);
			var _y2 = target.y + (panning.start.y - debug.panning.camera_start_y);
			
			draw_line_color(_x1, _y1, _x2, _y2, _col_pan_line, _col_pan_line);
			draw_circle_color(_x1-_po, _y1-_po, _dot_radius, _col_pan_line, _col_pan_line, false);
			draw_circle_color(_x2-_po, _y2-_po, _dot_radius, _col_pan_line, _col_pan_line, false);
		}
			
		// zoom anchor
		if (anchors.zoom != undefined)
		{
			draw_circle_color(anchors.zoom.x-_po, anchors.zoom.y-_po, _dot_radius, _col_zoom_anchor, _col_zoom_anchor, false);
		}
			
		// view
		var _view_x = camera_get_view_x(id);
		var _view_y = camera_get_view_y(id);
			
		draw_circle_color(_view_x-_po, _view_y-_po, _dot_radius, _col_view, _col_view, false);
			
		// position target dot
		if (anchors.position != undefined)
		{
			draw_circle_color(anchors.position.x-_po, anchors.position.y-_po, _dot_radius, _col_target, _col_target, false);
		}
		
			// nav ring
		
		// dots
		if (_rot_arc_length >= 1)
		{
			__debug_draw_nav_dot(debug.rotation.points[0].x, debug.rotation.points[0].y, _nav_dots_radius, _nav_dotring_radius, _col_rot_arc);					// rotation arc start
			__debug_draw_nav_dot(debug.rotation.points[_rot_arc_length-1].x, debug.rotation.points[_rot_arc_length-1].y, _nav_dots_radius, _nav_dotring_radius, _col_rot_arc);	// rotation arc end
		}
		
		__debug_draw_nav_anchor_dot(anchors.angle, _nav_dots_radius, _nav_dotring_radius, _col_rot_anchor);	// rotation anchor
		__debug_draw_nav_anchor_dot(anchors.zoom, _nav_dots_radius, _nav_dotring_radius, _col_zoom_anchor);	// zoom anchor
		
		if (is_panning())
		{
			var _x2 = target.x + (panning.start.x - debug.panning.camera_start_x);
			var _y2 = target.y + (panning.start.y - debug.panning.camera_start_y);
			
			__debug_draw_nav_dot(panning.start.x, panning.start.y, _nav_dots_radius, _nav_dotring_radius, _col_pan_line);	// pan line start
			__debug_draw_nav_dot(_x2, _y2, _nav_dots_radius, _nav_dotring_radius, _col_pan_line);			// pan line end
		}
		
		__debug_draw_nav_dot(_view_x, _view_y, _nav_dots_radius, _nav_dotring_radius, _col_view);		// view
		
		if (is_struct(target) || instance_exists(target))
		{
			__debug_draw_nav_dot(target.x, target.y, _nav_dots_radius, _nav_dotring_radius, _col_target);	// target
		}
		
		// ring
		draw_circle_color(x-_po, y-_po, _nav_ring_radius, _col_pos, _col_pos, true);
		draw_line_color(x-_po, y-_po, x+_nav_ring_radius-_po, y-_po, _col_pos, _col_pos);
	};
	
	/// @function			__debug_draw_nav_dot(_x, _y, _nav_dots_radius, _nav_dotring_radius, _col)
	/// @description		For internal use. Draws a dot on the outer edge of the navigation ring of the debug display.
	/// @param {real}		_x			The x position to draw the dot.
	/// @param {real}		_x			The y position to draw the dot.
	/// @param {real}		_nav_dots_radius	The radius of the dot.
	/// @param {real}		_nav_dotring_radius	The distance from the center of the navigation ring that this dot should be drawn at.
	/// @param {constant.Color}	_col			The colour to draw the dot.
	/// @returns			N/A
	static __debug_draw_nav_dot = function(_x, _y, _nav_dots_radius, _nav_dotring_radius, _col) {
		if (_nav_dotring_radius < point_distance(x, y, _x, _y))
		{
			var _direction	= point_direction(x, y, _x, _y);
			
			var _point_x	= lengthdir_x(_nav_dotring_radius, _direction);
			var _point_y	= lengthdir_y(_nav_dotring_radius, _direction);
					
			draw_circle_color(x+_point_x-1, y+_point_y-1, _nav_dots_radius, _col, _col, false);
		}
	};
	
	/// @function							__debug_draw_nav_anchor_dot(_x, _y, _nav_dots_radius, _nav_dotring_radius, _col)
	/// @description						For internal use. Draws a dot on the outer edge of the navigation ring of the debug display, to represent an anchor object.
	/// @param {struct, id.Instance, Asset.GMObject, undefined}	_anchor			The anchor struct/object to derive x,y co-ordinates from, for where to draw the dot.
	/// @param {real}						_nav_dots_radius	The radius of the dot.
	/// @param {real}						_nav_dotring_radius	The distance from the center of the navigation ring that this dot should be drawn at.
	/// @param {constant.Color}					_col			The colour to draw the dot.
	/// @returns							N/A
	static __debug_draw_nav_anchor_dot = function(_anchor, _nav_dots_radius, _nav_dotring_radius, _col) {
		if (is_struct(_anchor) || instance_exists(_anchor))
		{
			__debug_draw_nav_dot(_anchor.x, _anchor.y, _nav_dots_radius, _nav_dotring_radius, _col)
		}
	};
	
	
	
		  /////////////////
		 // constraints //
		/////////////////
	
	
	
	/// @function							set_position_anchor(_position_anchor)
	/// @description						Sets the position anchor (target object or struct) for the camera to follow.
	///								Note: If the data type you pass is a copy and not a reference, the camera will remain anchored to the x,y position as when first set. In this case, consider setting the anchor each frame if its position is not static.
	/// @param {struct,id.Instance,asset.GMObject,undefined}	[_position_anchor=undefined]	The position anchor. Must contain an x and y value if not undefined. Pass undefined to remove anchor.
	/// @returns							N/A
	static set_position_anchor = function(_position_anchor=undefined) {
		anchors.position = _position_anchor;
	};
	
	/// @function							set_angle_anchor(_angle_anchor)
	/// @description						Sets the angle anchor for the camera to pivot around when rotating. Useful for keeping a position at the same place on the screen, such as the player position, the mouse position, the center of the level or a Vector2.
	///								Note: If the data type you pass is a copy and not a reference, the camera will remain anchored to the x,y position as when first set. In this case, consider setting the anchor each frame if its position is not static.
	/// @param {struct,id.Instance,asset.GMObject,undefined}	[_angle_anchor=undefined]	The angle anchor. Must contain an x and y value if not undefined. Pass undefined to remove anchor.
	/// @returns							N/A
	static set_angle_anchor = function(_angle_anchor=undefined) {
		anchors.angle = _angle_anchor;
	};
	
	/// @function							set_zoom_anchor(_zoom_anchor)
	/// @description						Sets the zoom anchor for the camera to zoom towards or away from. Useful for zooming towards or away from a point of interest, such as in cutscenes, or the mouse in an editor or strategy game.
	///								Note: If the data type you pass is a copy and not a reference, the camera will remain anchored to the x,y position as when first set. In this case, consider setting the anchor each frame if its position is not static.
	/// @param {struct,id.Instance,asset.GMObject,undefined}	[_zoom_anchor=undefined]	The zoom anchor. Must contain an x and y value if not undefined. Pass undefined to remove anchor.
	/// @returns							N/A
	static set_zoom_anchor = function(_zoom_anchor=undefined) {
		anchors.zoom = _zoom_anchor;
	};
	
	/// @function		set_zoom_limits(_zoom_min, _zoom_max)
	/// @description	Sets the minimum and maximum limits for the camera zoom.
	/// @param {real}	[_zoom_min=zoom_min]	The minimum camera zoom. Limited to 1/(2^16), or 16 halvings of the base zoom amount.
	/// @param {real}	[_zoom_max=zoom_max]	The maximum camera zoom. Limited to 2^16, or 16 doublings of the base zoom amount at most, and _zoom_min at least.
	/// @returns		N/A
	static set_zoom_limits = function(_zoom_min = zoom_min, _zoom_max = zoom_max) {
		var _min = 1/power(2, 16);
		var _max = power(2, 16);
		
		zoom_min = clamp(_zoom_min, _min, _max);
		zoom_max = clamp(_zoom_max, max(_min, _zoom_min), _max);
	};
	
	/// @function		set_boundary(_x1, _y1, _x2, _y2)
	/// @description	Defines the boundary for the camera to clamp to. Useful for keeping the camera within the bounds of a level or area. Unset with .unset_boundary(). Note: The outer bounds may be visible while the camera is rotating or zoomed out.
	/// @param {real}	[_x1=0]			The left edge of the boundary.
	/// @param {real}	[_y1=0]			The top edge of the boundary.
	/// @param {real}	[_x2=room_width]	The right edge of the boundary.
	/// @param {real}	[_y2=room_height]	The bottom edge of the boundary.
	/// @returns		N/A
	static set_boundary = function(_x1=0, _y1=0, _x2=room_width, _y2=room_height) {
		boundary = {
			x1 : _x1,
			y1 : _y1,
			x2 : _x2,
			y2 : _y2
		};
	};
	
	/// @function		unset_boundary()
	/// @description	Unsets the position boundary for the camera, ensuring the camera's position is not limited. Set with .set_boundary()
	/// @returns		N/A
	static unset_boundary = function() {
		boundary = undefined;
	};
	
	
	
		  ///////////////////////////////
		 // transformation - settings //
		///////////////////////////////
	
	
	
	/// @function		set_start_values(_xstart, _ystart, _anglestart, _zoomstart)
	/// @description	Sets the start values for the camera. These values are used by .reset(), so they are useful if you want to, for example, change where the camera should reset to.
	/// @param {real}	[_xstart=start.x]		The starting x position.
	/// @param {real}	[_ystart=start.y]		The starting y position.
	/// @param {real}	[_anglestart=start.angle]	The starting angle.
	/// @param {real}	[_zoomstart=start.zoom]		The starting zoom.
	/// @returns		N/A
	static set_start_values = function(_xstart = start.x, _ystart = start.y, _anglestart = start.angle, _zoomstart = start.zoom) {
		start.x		= _xstart;
		start.y		= _ystart;
		start.angle	= _anglestart;
		start.zoom	= _zoomstart;
	};
	
	/// @function		set_position_interpolation(_value, _fn_interpolate)
	/// @description	Sets the interpolation factor and function for transforming the x, y position towards target.x/.y. Essentially how fast x/y should approach target.x/.y.
	/// @param {real}	[_value=interpolation.position]			The interpolation factor, as a fraction between 0 and 1. 1 = instant interpolation. 0 = no interpolation.
	/// @param {function}	[_fn_interpolate=interpolation.fn_position]	Optional custom interpolation function for updating the camera's x and y values. Takes 3 arguments (_current, _target, _factor) and returns a real value, indicating the new _current value. Recommended that _factor of 0 returns _current and _factor of 1 returns _target.
	/// @returns		N/A
	static set_position_interpolation = function(_value=interpolation.position, _fn_interpolate=interpolation.fn_position) {
		interpolation.position		= _value;
		interpolation.fn_position	= _fn_interpolate;
	};
	
	/// @function		set_angle_interpolation(_value, _fn_interpolate)
	/// @description	Sets the interpolation factor and function for transforming the angle towards target.angle. Essentially how fast angle should approach target.angle.
	/// @param {real}	[_value=interpolation.angle]			The interpolation factor, as a fraction between 0 and 1. 1 = instant interpolation. 0 = no interpolation.
	/// @param {function}	[_fn_interpolate=interpolation.fn_angle]	Optional custom interpolation function for updating the camera's angle. Takes 3 arguments (_current, _target, _factor) and returns a real value, indicating the new _current value. Recommended that _factor of 0 returns _current and _factor of 1 returns _target.
	/// @returns		N/A
	static set_angle_interpolation = function(_value=interpolation.angle, _fn_interpolate=interpolation.fn_angle) {
		interpolation.angle	= _value;
		interpolation.fn_angle	= _fn_interpolate;
	};
	
	/// @function		set_zoom_interpolation(_value, _fn_interpolate)
	/// @description	Sets the interpolation factor and function for transforming the zoom towards target.zoom. Essentially how fast zoom should approach target.zoom.
	/// @param {real}	[_value=interpolation.zoom]		The interpolation factor, as a fraction between 0 and 1. 1 = instant interpolation. 0 = no interpolation.
	/// @param {function}	[_fn_interpolate=interpolation.fn_zoom]	Optional custom interpolation function for updating the camera's zoom. Takes 3 arguments (_current, _target, _factor) and returns a real value, indicating the new _current value. Recommended that _factor of 0 returns _current and _factor of 1 returns _target.
	/// @returns		N/A
	static set_zoom_interpolation = function(_value=interpolation.zoom, _fn_interpolate=interpolation.fn_angle) {
		interpolation.zoom	= _value;
		interpolation.fn_zoom	= _fn_interpolate;
	};
	
	/// @function		set_interpolation_values(_position_interpolation, _angle_interpolation, _zoom_interpolation)
	/// @description	Sets the interpolation factors for moving, rotating and zooming the camera. Essentially how fast x, y, angle and zoom should approach their respective target values.
	/// @param {real}	[_position_interpolation=interpolation.position]	The position interpolation factor, as a fraction between 0 and 1. 1 = instant interpolation. 0 = no interpolation.
	/// @param {real}	[_angle_interpolation=interpolation.angle]		The angle interpolation factor, as a fraction between 0 and 1. 1 = instant interpolation. 0 = no interpolation.
	/// @param {real}	[_zoom_interpolation=interpolation.zoom]		The zoom interpolation factor, as a fraction between 0 and 1. 1 = instant interpolation. 0 = no interpolation.
	/// @returns		N/A
	static set_interpolation_values = function(_position_interpolation=interpolation.position, _angle_interpolation=interpolation.angle, _zoom_interpolation=interpolation.zoom) {
		set_position_interpolation(_position_interpolation);
		set_angle_interpolation(_angle_interpolation);
		set_zoom_interpolation(_zoom_interpolation);
	};
	
	
	
		  ////////////////////
		 // transformation //
		////////////////////
	
	
	
	/// @function		move_to(_target_x, _target_y)
	/// @description	Sets the target.x/.y for the camera.
	/// @param {real}	[_target_x=target.x]		The new target.x position for the camera.
	/// @param {real}	[_target_y=target.y]		The new target.y position for the camera.
	/// @returns		N/A
	static move_to = function(_target_x=target.x, _target_y=target.y) {
		target.x = _target_x;
		target.y = _target_y;
	};
	
	/// @function		move_by(_x, _y)
	/// @description	Moves the camera target.x/.y by a relative amount.
	/// @param {real}	[_x=0]				The x value to move target.x by.
	/// @param {real}	[_y=0]				The y value to move target.y by.
	/// @returns		N/A
	static move_by = function(_x=0, _y=0) {
		move_to(target.x + _x, target.y + _y);
	};
	
	/// @function		rotate_to(_target_angle)
	/// @description	Sets the target.angle for the camera.
	/// @param {real}	[_target_angle=target.angle]	The new target angle for the camera, in degrees.
	/// @returns		N/A
	static rotate_to = function(_target_angle=target.angle) {
		if (is_debugging())
		{
			debug.rotation.points = [];
		}
		
		target.angle	= _target_angle;
		
		// wrap angle values to interpolate in the correct direction
		if (abs(target.angle - angle) == 180)
		{
			target.angle = choose(angle-180, angle+180);
		}
		else
		{
			target.angle = wrap(target.angle, 0, 360);
			
			while (abs(target.angle - angle) > 180)
			{
				angle	= (angle < target.angle) ? angle + 360 : angle - 360;
			}
		}
	};
	
	/// @function		rotate_by(_degrees)
	/// @description	Increments camera's target.angle by _degrees.
	/// @param {real}	[_degrees=0]		How many degrees to rotate the camera by. >0 = clockwise, <0 = counter clockwise. 0 = no change.
	/// @returns		N/A
	static rotate_by = function(_degrees=0) {
		rotate_to(target.angle + _degrees);
	};
	
	/// @function		zoom_to(_target_zoom)
	/// @description	Sets the target.zoom factor for the camera.
	/// @param {real}	[_target_zoom=target.zoom]	The new target zoom for the camera. >1 = zoom in, else 1 = normal zoom, else >0 = zoom out.
	/// @returns		N/A
	static zoom_to = function(_target_zoom=target.zoom) {
		target.zoom = clamp(_target_zoom, zoom_min, zoom_max);
	};
	
	/// @function		zoom_by(_zoom_factor)
	/// @description	Sets the target.zoom factor relative to the current target.zoom.
	/// @param {real}	[_zoom_factor=1]	The new relative target zoom for the camera. >1 = multiply (zoom in), >0 = divide (zoom out). Examples: 2 = double current zoom, 0.5 = halve current zoom.
	/// @returns		N/A
	static zoom_by = function(_zoom_factor=1) {
		zoom_to(target.zoom * _zoom_factor);
	};
	
	/// @function		transform_to(_target_x, _target_y, _target_angle, _target_zoom)
	/// @description	Sets the target values for the camera.
	/// @param {real}	[_target_x=target.x]		The new target.x position for the camera.
	/// @param {real}	[_target_y=target.y]		The new target.y position for the camera.
	/// @param {real}	[_target_angle=target.angle]	The new target angle for the camera, in degrees.
	/// @param {real}	[_target_zoom=target.zoom]	The new target zoom for the camera. >1 = zoom in, else 1 = normal zoom, else >0 = zoom out.
	/// @returns		N/A
	static transform_to = function(_target_x=x, _target_y=y, _target_angle=angle, _target_zoom=zoom) {
		move_to(_target_x, _target_y);
		rotate_to(_target_angle);
		zoom_to(_target_zoom);
	};
	
	/// @function		transform_by(_x, _y, _degrees, _zoom_factor)
	/// @description	Sets the camera target by a relative amount.
	/// @param {real}	[_x=0]			The x value to move target.x by.
	/// @param {real}	[_y=0]			The y value to move target.y by.
	/// @param {real}	[_degrees=0]		How many degrees to rotate the camera by. >0 = clockwise, <0 = counter clockwise. 0 = no change.
	/// @param {real}	[_zoom_factor=1]	The new relative target zoom for the camera. >1 = multiply (zoom in), >0 = divide (zoom out). Examples: 2 = double current zoom, 0.5 = halve current zoom.
	/// @returns		N/A
	static transform_by = function(_x=0, _y=0, _degrees=0, _zoom_factor=1) {
		move_by(_x, _y);
		rotate_by(_degrees);
		zoom_by(_zoom_factor);
	};
	
	/// @function		reset()
	/// @description	Resets the camera back to the start values and stops panning. See .set_start_values() and .stop_panning()
	/// @returns		N/A
	static reset = function() {
		if (is_debugging())
		{
			debug.rotation.points = [];
		}
		
		stop_panning();
		
		target.x	= start.x;
		target.y	= start.y;
		target.angle	= start.angle;
		target.zoom	= start.zoom;
		
		x		= target.x;
		y		= target.y;
		angle		= target.angle;
		zoom		= target.zoom;
	};
	
	
	
		  //////////////////////////////
		 // transformation - panning //
		//////////////////////////////
	
	
	
	/// @function		is_panning()
	/// @description	Checks if camera is in panning mode. Useful to check before using .pan_to(). Start panning mode with .start_panning(), stop panning mode with .stop_panning().
	/// @returns {bool}	Returns panning (true) or not (false).
	static is_panning = function() {
		return panning.active;
	};
	
	/// @function		start_panning(_from_x, _from_y)
	/// @description	Starts camera panning mode and sets start values. Start panning mode before using .pan_to()
	/// @param {real}	_from_x		The x co-ordinate from which you wish to pan from. Is used for calculations in .pan_to()
	/// @param {real}	_from_y		The y co-ordinate from which you wish to pan from. Is used for calculations in .pan_to()
	/// @returns		N/A
	static start_panning = function(_from_x, _from_y) {
		panning.active		= true;
		panning.start.x		= _from_x;
		panning.start.y		= _from_y;
		panning.start.angle	= angle;
		panning.start.zoom	= zoom;
		panning.target.x	= _from_x;
		panning.target.y	= _from_y;
		panning.target.angle	= angle;
		panning.target.zoom	= zoom;
		
		debug.panning.camera_start_x	= x;
		debug.panning.camera_start_y	= y;
	};
	
	/// @function		stop_panning()
	/// @description	Stops camera panning mode. Call this method when you have finished panning with .pan_to()
	/// @returns		N/A
	static stop_panning = function() {
		panning.active		= false;
	};
	
	/// @function		pan_to(_to_x, _to_y)
	/// @description	Sets target panning co-ordinates. Only call this function when in panning mode. See .start_panning(), .stop_panning() and .is_panning().
	/// @param {real}	[_to_x=panning.start.x]	The x co-ordinate to which to pan.
	/// @param {real}	[_to_y=panning.start.y]	The y co-ordinate to which to pan.
	/// @returns		N/A
	static pan_to = function(_to_x=panning.start.x, _to_y=panning.start.y) {
		if (!is_panning())
		{
			throw ("Error: MCamera() attempting to use .pan_to() outside of panning mode. Check panning mode with .is_panning(), start panning mode with .start_panning(), and stop panning mode with .stop_panning()");
		}
		
		panning.target.x	= _to_x;
		panning.target.y	= _to_y;
	};
	
	
	
		  ////////////////////////////
		 // transfomration - shake //
		////////////////////////////
	
	
	
	/// @function		set_shake_limits(_radius, _angle, _zoom, _coarseness, _intensity)
	/// @description	Sets the maximum radius, angle, and zoom for camera shake transformation. Additionally sets the courseness for transform value change. If you don't want shake to transform a particular way, set that transform limit to 0.
	/// @param {real}	_radius					The maximum distance from 0,0 the camera x,y can be transformed.
	/// @param {real}	_angle					The maximum angle range the camera can be rotated. Output angle is added to negative half of the range. For example, 20 will transform the camera between -10 to 10 degrees.
	/// @param {real}	_zoom					The maximum range the zoom factor can fluctuate in.
	/// @param {real}	[_coarseness=shake.coarseness]		The coarseness of the brownian step function for changing each transform value each frame. 0 = +-no change (not recommended), 1 = +-whole range (white noise).
	///								For intended results, input a value >0 and <=1. For white noise, input 1. For typical brown noise, try something between 0.1 and 0.5.
	/// @param {real}	[_intensity=shake.limits.intensity]	The maximum intensity of the shake. See .shake_to() and .shake_by()
	/// @returns		N/A
	static set_shake_limits = function(_radius, _angle, _zoom, _coarseness=shake.coarseness, _intensity=shake.limits.intensity) {
		shake.limits.radius	= _radius;
		shake.limits.angle	= _angle;
		shake.limits.zoom	= _zoom;
		shake.coarseness	= _coarseness;
		shake.limits.intensity	= _intensity;
	};
	
	/// @function		set_shake_interpolation(_value, _fn_interpolate)
	/// @description	Sets the interpolation factor and function for reducing the intensity of the shake. Essentially how fast intensity should approach 0.
	/// @param {real}	[_value=shake.intensity_falloff_rate]		The interpolation factor, as a fraction between 0 and 1. 1 = instantly turn off intensity. 0 = maintain intensity.
	/// @param {function}	[_fn_interpolate=shake.fn_intensity]		Optional custom interpolation function for fading intensity. Takes 3 arguments (_current, _target, _factor) and returns a real value, indicating the new _current value. Recommended that _factor of 0 returns _current and _factor of 1 returns _target.
	/// @returns		N/A
	static set_shake_interpolation = function(_value=shake.intensity_falloff_rate, _fn_interpolate=shake.fn_intensity) {
		shake.intensity_falloff_rate	= _value;
		shake.fn_intensity		= _fn_interpolate;
	};
	
	/// @function		shake_to(_intensity, _reset_transform)
	/// @description	Sets the intensity for the shake.
	/// @param {real}	_intensity		The intensity level of the shake; a multiplier for the shake limits (See .set_shake_limits()). 0 = turn off. 1 = set to shake limits. Intended to be a value between 0 and 1, but go wild.
	/// @param {bool}	[_reset_transform=true]	Whether to reset the initial transform values before the shake (true) or not (false).
	/// @returns		N/A
	static shake_to = function(_intensity, _reset_transform=true) {
		if (_reset_transform)
		{
			__shake_reset_transform();
		}
		
		shake.intensity	= clamp(_intensity, -shake.limits.intensity, shake.limits.intensity);
	};
	
	/// @function		shake_by(_intensity, _reset_transform)
	/// @description	Adds _intensity on to the intensity for the shake. Useful for increasing the shake with consecutive hits.
	/// @param {real}	_intensity			The intensity to add on to the intensity level of the shake; a multiplier for the shake limits. See .set_shake_limits(), .shake_to()
	/// @param {bool}	[_reset_transform=false]	Whether to reset the initial transform values before the shake (true) or not (false).
	/// @returns		N/A
	static shake_by = function(_intensity, _reset_transform=false) {
		shake_to(shake.intensity+_intensity, _reset_transform);
	};
	
	
	
		  /////////////
		 // utility //
		/////////////
	
	
	
	/// @function		set_view(_view)
	/// @description	Sets the view and id for this camera.
	/// @param {real}	[_view=0]	View number [0..7].
	/// @returns		N/A
	static set_view = function(_view=0)
	{
		view	= _view;
		id	= view_camera[view];
	};
	
	/// @function		view_x();
	/// @description	Returns this camera's x position in the world.
	/// @returns {real}	camera x.
	static view_x = function()
	{
		return x - (view_width()/2);
	};
	
	/// @function		view_y();
	/// @description	Returns this camera's y position in the world.
	/// @returns {real}	camera y.
	static view_y = function()
	{
		return y - (view_height()/2);
	};
	
	/// @function		view_width();
	/// @description	Returns this camera's width scaled by zoom.
	/// @returns {real}	width scaled by zoom.
	static view_width = function()
	{
		return width/zoom;
	};
	
	/// @function		view_height();
	/// @description	Returns this camera's height scaled by zoom.
	/// @returns {real}	height scaled by zoom.
	static view_height = function()
	{
		return height/zoom;
	};
	
	/// @function		is_debugging()
	/// @description	Returns if debug mode is active (true) or not (false).
	/// @returns {bool}	Returns if debug mode is active (true) or not (false).
	static is_debugging = function() {
		return debug.active;
	};
	
	/// @function		set_debugging(_is_debugging)
	/// @description	Activates or deactivates debug mode. When debug mode is active, the debug display is drawn to the screen.
	/// @param {bool}	[_is_debugging]		Whether to turn debug mode on (true) or off (false). Toggles on/off by default.
	/// @returns		N/A
	static set_debugging = function(_is_debugging=!debug.active) {
		debug.active = _is_debugging;
	};
	
	/// @function		find_gui_mouse_x()
	/// @description	Finds the x position of the mouse on the GUI. Useful for drawing a mouse cursor to the GUI.
	/// @returns {real}	Returns an x position relative to the GUI.
	static find_gui_mouse_x = function() {
		if (window_get_fullscreen())
		{
			return find_gui_position(mouse_x, mouse_y).x;
		}
		
		return window_mouse_get_x() / window_scale;
	};
	
	/// @function		find_gui_mouse_y()
	/// @description	Finds the y position of the mouse on the GUI. Useful for drawing a mouse cursor to the GUI.
	/// @returns {real}	Returns an y position relative to the GUI.
	static find_gui_mouse_y = function() {
		if (window_get_fullscreen())
		{
			return find_gui_position(mouse_x, mouse_y).y;
		}
		
		return window_mouse_get_y() / window_scale;
	};
	
	/// @function		find_gui_position(_x, _y)
	/// @description	Converts an x,y position in the world to co-ordinates on the GUI and returns it in a struct. Useful for drawing tracking icons on the GUI.
	/// @param {real}	[_x=0]		The x co-ordinate in the world.
	/// @param {real}	[_y=0]		The y co-ordinate in the world.
	/// @returns {struct}	Returns a Vector2 / struct containing an x and y value.
	static find_gui_position = function(_x, _y) {
		var _gui_x = (_x - camera_get_view_x(id)) * zoom;
		var _gui_y = (_y - camera_get_view_y(id)) * zoom;
		
		var _gui_center_x = display_get_gui_width()/2;
		var _gui_center_y = display_get_gui_height()/2;

		var _position_len = point_distance(_gui_center_x, _gui_center_y, _gui_x, _gui_y);
		var _position_dir = point_direction(_gui_center_x, _gui_center_y, _gui_x, _gui_y);
		
		var _rotated_x = lengthdir_x(_position_len, _position_dir+angle);
		var _rotated_y = lengthdir_y(_position_len, _position_dir+angle);
		
		return {
			x : _gui_center_x + _rotated_x,
			y : _gui_center_y + _rotated_y
		};
	};
	
	
	
	// init
	
	create(_create_host_object_for_me);
}