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
	// config
	
	host_object		= undefined;		// See _create_host_object_for_me
	
	if (_create_host_object_for_me)
	{
		host_object		= instance_create_depth(0, 0, -1, objMCamera);
		host_object.camera	= self;
	}
	
	view			= 0;
	id			= view_camera[view];	// The view port id for this camera. See view_camera in the manual.
	width			= _width;
	height			= _height;
	window_scale		= _window_scale;
	pixel_scale		= _pixel_scale;
	
	// state
	
	position_boundary	= undefined;					// See .set_position_boundary()
	should_follow_target	= method(self, function() {return true});	// See .set_target_follow_condition()
	
	target			= self;			// See .set_target()
	rotation_anchor		= undefined;		// See .set_rotation_anchor()
	zoom_anchor		= undefined;		// See .set_zoom_anchor()
	
	target_x		= width/2;		// See .move_to() .move_by(), .translate_to(), .translate_by()
	target_y		= height/2;		// See .move_to() .move_by(), .translate_to(), .translate_by()
	target_angle		= 0;			// See .rotate_to(), .rotate_by(), .translate_to(), .translate_by()
	target_zoom		= 1;			// See .zoom_to(), .zoom_by(), .translate_to(), .translate_by()
	
	if (target != self && (is_struct(target) || instance_exists(target)))
	{
		target_x	= target.x;
		target_y	= target.y;
	}
	
	xstart			= target_x;		// See .set_start_values() and .reset()
	ystart			= target_y;		// See .set_start_values() and .reset()
	anglestart		= target_angle;		// See .set_start_values() and .reset()
	zoomstart		= target_zoom;		// See .set_start_values() and .reset()
	
	x			= xstart;		// The current x position for this camera. Equivalent to the center of the screen in world co-ordinates.
	y			= ystart;		// The current y position for this camera. Equivalent to the center of the screen in world co-ordinates.
	angle			= anglestart;		// The current angle for this camera, in degrees.
	zoom			= zoomstart;		// The current zoom factor for this camera. <1 = zoom in, else 1 = normal, else <0 = zoom out.
	zoom_min		= 1/16;			// See .set_zoom_limits()
	zoom_max		= 4;			// See .set_zoom_limits()
	
	position_interpolation	= 1/8;			// See .set_position_interpolation()
	angle_interpolation	= 1/4;			// See .set_angle_interpolation()
	zoom_interpolation	= 1/16;			// See .set_zoom_interpolation()
	
	debug			= false;		// See .set_debug_mode()
	debug_rotation_points	= [];			// For internal use. Used to store and display the rotation arc in debug mode.
	
	// panning
	
	panning			= false;		// See .start_panning(), .stop_panning(), .is_panning(), .pan_to()
	pan_xstart		= xstart;		// See .start_panning(), .stop_panning(), .is_panning(), .pan_to()
	pan_ystart		= ystart;		// See .start_panning(), .stop_panning(), .is_panning(), .pan_to()
	
	// init
	
	__window_init();				// See .__window_init()
	
	
	
	  /////////////
	 // methods //
	/////////////
	
	
	
		  ////////////
		 // events //
		////////////
	
	
	
	/// @function		room_start()
	/// @description	The Room Start event. Enables the view for this room.
	/// @returns		N/A
	static room_start = function() {
		view_enabled		= true;
		view_visible[view]	= true;
	};
	
	/// @function		end_step()
	/// @description	The End Step event. Updates the camera translation.
	/// @returns		N/A
	static end_step = function() {
		__apply_zoom(false);
		__apply_rotation(false);
		__apply_movement(false, false);
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
	
	
	
	/// @function		__window_init()
	/// @description	For internal use. Initialises the application_surface, display, and window sizes, and centers the window.
	/// @returns		N/A
	static __window_init = function() {
		surface_resize(application_surface, width * pixel_scale, height * pixel_scale);
		display_set_gui_size(width, height);
		window_set_size(width * window_scale, height * window_scale);
		window_center();
	};
	
	/// @function		__apply_zoom(_instant)
	/// @description	For internal use. Updates the camera zoom.
	/// @param {bool}	[_instant=false]	Whether to apply target_zoom instantly (true) or interpolate towards it (false).
	/// @returns		N/A
	static __apply_zoom = function(_instant=false) {
		var _previous_zoom	= zoom;
		
		// update zoom
		
		zoom	= lerp(zoom, target_zoom, _instant ? 1 : zoom_interpolation);
		
		// update view to comply with zoom_anchor
		
		if (zoom != _previous_zoom && (is_struct(zoom_anchor) || instance_exists(zoom_anchor)))
		{
			// setup
			
			var _screen_ratio_w	= (zoom_anchor.x - camera_get_view_x(id)) / camera_get_view_width(id);
			var _screen_ratio_h	= (zoom_anchor.y - camera_get_view_y(id)) / camera_get_view_height(id);
			
			// change size
			
			var _view_width		= width/zoom;
			var _view_height	= height/zoom;
			
			camera_set_view_size(id, _view_width, _view_height);
			
			// change position
			
			var _w2			= _view_width / 2;
			var _h2			= _view_height / 2;
	
			x			= zoom_anchor.x - (_view_width * _screen_ratio_w) + _w2;
			y			= zoom_anchor.y - (_view_height * _screen_ratio_h) + _h2;
			
			camera_set_view_pos(id, x-_w2, y-_h2);
		}
		else
		{
			camera_set_view_size(id, width/zoom, height/zoom);
		}
	};
	
	/// @function		__apply_rotation(_instant)
	/// @description	For internal use. Updates the camera angle.
	/// @param {bool}	[_instant=false]	Whether to apply target_angle instantly (true) or interpolate towards it (false).
	/// @returns		N/A
	static __apply_rotation = function(_instant=false) {
		// update angle
		
		var _previous_angle	= angle;
		
		if (_instant)
		{
			angle		= target_angle;
		}
		else
		{
			// wrap angle values
			
			if (abs(target_angle - angle) == 180)
			{
				target_angle = choose(angle-180, angle+180);
			}
			else
			{
				target_angle = wrap(target_angle, 0, 360);
				
				if (abs(target_angle - angle) > 180)
				{
					angle	= (angle < target_angle) ? angle + 360 : angle - 360;
				}
			}
			
			// set angle
			
			angle		= lerp(angle, target_angle, angle_interpolation);
		}
		
		// update postion to comply with rotation_anchor
		
		if (angle != _previous_angle && (is_struct(rotation_anchor) || instance_exists(rotation_anchor)))
		{
			if (debug && abs(_previous_angle-angle) >= 1)
			{
				array_push(debug_rotation_points, {
					x : x,
					y : y
				});
			}
			
			var _distance	= point_distance(rotation_anchor.x, rotation_anchor.y, x, y);
			var _direction	= point_direction(rotation_anchor.x, rotation_anchor.y, x, y) + (_previous_angle-angle);
			
			var _position_x	= lengthdir_x(_distance, _direction);
			var _position_y	= lengthdir_y(_distance, _direction);
			
			x		= rotation_anchor.x + _position_x;
			y		= rotation_anchor.y + _position_y;
		}
		
		// update view
		
		camera_set_view_angle(id, angle);
	};
	
	/// @function		__apply_movement(_instant)
	/// @description	For internal use. Updates the camera position.
	/// @param {bool}	[_instant=false]		Whether to apply target_x / target_y instantly (true) or interpolate towards them (false).
	/// @param {bool}	[_ignore_target=false]		Whether ignore the target (true) or not (false). Useful for resetting to the correct start position.
	/// @returns		N/A
	static __apply_movement = function(_instant=false, _ignore_target=false) {
		// comply with target
		
		if (!panning && !_ignore_target && should_follow_target() && (is_struct(target) || instance_exists(target)))
		{
			move_to(target.x, target.y, false); // true will cause an infinite loop. let the code below handle _instant instead.
		}
		
		// update position
		
		x = lerp(x, target_x, _instant ? 1 : position_interpolation);
		y = lerp(y, target_y, _instant ? 1 : position_interpolation);
		
		__clamp_position_to_boundary();
		
		// update view
		
		camera_set_view_pos(id, x - ((width/zoom)/2), y - ((height/zoom)/2));
	};
	
	/// @function			__clamp_position_to_boundary(_instant)
	/// @description		For internal use. Clamps the camera position to be within position_boundary.
	/// @param {struct, undefined}	[_rect_or_undefined=position_boundary]	The struct defining the boundary rectangle, or undefined for no clamping. Must contain x1, y1, x2, y2 values. Example: { x1=0, y1=0, x2=width, y2=height }
	/// @returns			N/A
	static __clamp_position_to_boundary = function(_rect_or_undefined = position_boundary) {
		if (!is_undefined(_rect_or_undefined))
		{
			var _view_width			= width/zoom;
			var _view_height		= height/zoom;		
			var _width_ratio		= abs( lengthdir_x(1, angle) );
			var _height_ratio		= abs( lengthdir_y(1, angle) );
			
			var _rotated_width		= (_width_ratio * _view_width) + (_height_ratio * _view_height);
			var _rotated_height		= (_width_ratio * _view_height) + (_height_ratio * _view_width);
		
			var _boundary_width		= _rect_or_undefined.x2 - _rect_or_undefined.x1;
			var _boundary_height		= _rect_or_undefined.y2 - _rect_or_undefined.y1;
			
			x = (_rotated_width > _boundary_width)		? (_boundary_width/2)	: clamp(x, _rect_or_undefined.x1 + (_rotated_width/2), _rect_or_undefined.x2 - (_rotated_width/2));
			y = (_rotated_height > _boundary_height)	? (_boundary_height/2)	: clamp(y, _rect_or_undefined.y1 + (_rotated_height/2), _rect_or_undefined.y2 - (_rotated_height/2));
		}
	};
	
	/// @function		__debug_draw()
	/// @description	For internal use. Draws the debug display.
	/// @returns		N/A
	static __debug_draw = function() {
		if (!debug)
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
			
		var _nav_dots_radius	= 2 / zoom;
		var _nav_ring_radius	= 16 / zoom;
		var _nav_dotring_radius	= _nav_ring_radius + (4 / zoom);
		var _dot_radius		= clamp(4, _nav_dots_radius, _nav_ring_radius);
			
		var _po			= 1; // pixel offset
			
		// boundary
		if (!is_undefined(position_boundary))
		{
			draw_rectangle_colour(position_boundary.x1+0.5, position_boundary.y1+0.5, position_boundary.x2-1.5, position_boundary.y2-1.5, _col_boundary, _col_boundary, _col_boundary, _col_boundary, true);
		}
		
			// dots
		
		// rotation arc
		var _rot_arc_length = array_length(debug_rotation_points);
			
		if (_rot_arc_length >= 1)
		{
			draw_pointarray(0, 0, debug_rotation_points, false, pr_linestrip, _col_rot_arc);
			draw_circle_color(debug_rotation_points[0].x-_po, debug_rotation_points[0].y-_po, _dot_radius, _col_rot_arc, _col_rot_arc, false);
			draw_circle_color(debug_rotation_points[_rot_arc_length-1].x-_po, debug_rotation_points[_rot_arc_length-1].y-_po, _dot_radius, _col_rot_arc, _col_rot_arc, false);
		}
			
		// rotation anchor
		if (is_struct(rotation_anchor) || instance_exists(rotation_anchor))
		{
			draw_circle_color(rotation_anchor.x-_po, rotation_anchor.y-_po, _dot_radius, _col_rot_anchor, _col_rot_anchor, false);
		}
			
		// zoom anchor
		if (is_struct(zoom_anchor) || instance_exists(zoom_anchor))
		{
			draw_circle_color(zoom_anchor.x-_po, zoom_anchor.y-_po, _dot_radius, _col_zoom_anchor, _col_zoom_anchor, false);
		}
			
		// view
		var _view_x = camera_get_view_x(id);
		var _view_y = camera_get_view_y(id);
			
		draw_circle_color(_view_x-_po, _view_y-_po, _dot_radius, _col_view, _col_view, false);
			
		// position target dot
		if (is_struct(target) || instance_exists(target))
		{
			draw_circle_color(target_x-_po, target_y-_po, _dot_radius, _col_target, _col_target, false);
		}
		
			// nav ring
		
		// dots
		if (_rot_arc_length >= 1)
		{
			__debug_draw_nav_dot(debug_rotation_points[0].x, debug_rotation_points[0].y, _nav_dots_radius, _nav_dotring_radius, _col_rot_arc);					// rotation arc start
			__debug_draw_nav_dot(debug_rotation_points[_rot_arc_length-1].x, debug_rotation_points[_rot_arc_length-1].y, _nav_dots_radius, _nav_dotring_radius, _col_rot_arc);	// rotation arc end
		}
		
		__debug_draw_nav_anchor_dot(rotation_anchor, _nav_dots_radius, _nav_dotring_radius, _col_rot_anchor);	// rotation anchor
		__debug_draw_nav_anchor_dot(zoom_anchor, _nav_dots_radius, _nav_dotring_radius, _col_zoom_anchor);	// zoom anchor
		__debug_draw_nav_dot(_view_x, _view_y, _nav_dots_radius, _nav_dotring_radius, _col_view);		// view
		
		if (is_struct(target) || instance_exists(target))
		{
			__debug_draw_nav_dot(target_x, target_y, _nav_dots_radius, _nav_dotring_radius, _col_target);	// target
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
	
	
	
	/// @function		set_zoom_limits(_zoom_min, _zoom_max)
	/// @description	Sets the minimum and maximum limits for the camera zoom.
	/// @param {real}	[_zoom_min=zoom_min]	The minimum camera zoom. Limited to 1/(2^16), or 16 halvings of the base zoom amount.
	/// @param {real}	[_zoom_max=zoom_max]	The maximum camera zoom. Limited to 2^16, or 16 doublings of the base zoom amount at most, and _zoom_min at least.
	/// @returns		N/A
	static set_zoom_limits = function(_zoom_min = zoom_min, _zoom_max = zoom_max) {
		var _max = power(2, 16);
		var _min = 1/_max;
		
		zoom_min = clamp(_zoom_min, _min, _max);
		zoom_max = clamp(_zoom_max, max(_min, _zoom_min), _max);
	};
	
	/// @function							set_target(_target)
	/// @description						Sets the target for the camera to follow.
	/// @param {struct, id.Instance, asset.GMObject, undefined}	[_target=target]	The target to follow. If not undefined, must contain an x and y value.
	///											Note: If you are not translating the position manually or with a target, set to self to maintain x,y as the target_x/target_y, otherwise the last target_x/target_y will remain, which may affect rotate/zoom.
	/// @returns							N/A
	static set_target = function(_target=target) {
		target = _target;
	};
	
	/// @function		set_target_follow_condition(_fn_follow_target_while)
	/// @description	Sets the follow condition for the target. The target is followed when this function returns true. Useful if you only want the camera to follow the target given a certain circumstance, for example when the game is not paused.
	/// @param {function}	[_fn_follow_target_while]	The function returning true when the target object should be followed. By default, a function always returning true is passed.
	/// @returns		N/A
	static set_target_follow_condition = function(_fn_follow_target_while=function(){return true}) {
		should_follow_target = method(self, _fn_follow_target_while);
	};
	
	/// @function							set_rotation_anchor(_rotation_anchor_or_undefined)
	/// @description						Sets the rotation anchor for the camera to pivot around when rotating. Useful for keeping a position at the same place on the screen, such as the player position, the mouse position, the center of the level or a Vector2.
	///								Note: If the data type you pass is a copy and not a reference, the camera will remain anchored to the x,y position as when first set. In this case, consider setting the anchor each frame if its position is not static.
	/// @param {struct, id.Instance, asset.GMObject, undefined}	[_rotation_anchor_or_undefined=undefined]	The rotation anchor. Must contain an x and y value if not undefined. If undefined, the MCamera object's position will be used.
	/// @returns							N/A
	static set_rotation_anchor = function(_rotation_anchor_or_undefined=undefined) {
		rotation_anchor = _rotation_anchor_or_undefined;
	};
	
	/// @function							set_zoom_anchor(set_zoom_anchor_or_undefined)
	/// @description						Sets the zoom anchor for the camera to zoom towards or away from. Useful for zooming towards or away from a point of interest, such as in cutscenes, or the mouse in an editor or strategy game.
	///								Note: If the data type you pass is a copy and not a reference, the camera will remain anchored to the x,y position as when first set. In this case, consider setting the anchor each frame if its position is not static.
	/// @param {struct, id.Instance, asset.GMObject, undefined}	[_zoom_anchor_or_undefined=undefined]		The zoom anchor. Must contain an x and y value if not undefined. If undefined, the MCamera object's position will be used.
	/// @returns							N/A
	static set_zoom_anchor = function(_zoom_anchor_or_undefined=undefined) {
		zoom_anchor = _zoom_anchor_or_undefined;
	};
	
	/// @function		set_position_boundary(_x1, _y1, _x2, _y2)
	/// @description	Defines the boundary for the camera to clamp to. Useful for keeping the camera within the bounds of a level or area. Unset with .unset_position_boundary(). Note: The outer bounds may be visible while the camera is rotating or zoomed out.
	/// @param {real}	_x1			The left edge of the boundary.
	/// @param {real}	_y1			The top edge of the boundary.
	/// @param {real}	_x2			The right edge of the boundary.
	/// @param {real}	_y2			The bottom edge of the boundary.
	/// @returns		N/A
	static set_position_boundary = function(_x1, _y1, _x2, _y2) {
		position_boundary = {
			x1 : _x1,
			y1 : _y1,
			x2 : _x2,
			y2 : _y2
		};
	};
	
	/// @function		unset_position_boundary()
	/// @description	Unsets the position boundary for the camera, ensuring the camera's position is not limited. Set with .set_position_boundary()
	/// @returns		N/A
	static unset_position_boundary = function() {
		position_boundary = undefined;
	};
	
	
	
		  /////////////////
		 // translation //
		/////////////////
	
	
	
	/// @function		set_position_interpolation(_position_interpolation)
	/// @description	Sets the interpolation factor for translating the x, y position towards target_x, target_y. Essentially how fast x, y should approach target_x, target_y.
	/// @param {real}	[_position_interpolation=position_interpolation]	The interpolation factor, as a fraction between 0 and 1. 1 = instant interpolation. 0 = no interpolation.
	/// @returns		N/A
	static set_position_interpolation = function(_position_interpolation=position_interpolation) {
		position_interpolation = _position_interpolation;
	};
	
	/// @function		set_angle_interpolation(_angle_interpolation)
	/// @description	Sets the interpolation factor for rotating the angle towards target_angle. Essentially how fast angle should approach target_angle.
	/// @param {real}	[_angle_interpolation=angle_interpolation]	The interpolation factor, as a fraction between 0 and 1. 1 = instant interpolation. 0 = no interpolation.
	/// @returns		N/A
	static set_angle_interpolation = function(_angle_interpolation=angle_interpolation) {
		angle_interpolation = _angle_interpolation;
	};
	
	/// @function		set_zoom_interpolation(_zoom_interpolation)
	/// @description	Sets the interpolation factor for magnifying the zoom towards target_zoom. Essentially how fast zoom should approach target_zoom.
	/// @param {real}	[_zoom_interpolation=zoom_interpolation]	The interpolation factor, as a fraction between 0 and 1. 1 = instant interpolation. 0 = no interpolation.
	/// @returns		N/A
	static set_zoom_interpolation = function(_zoom_interpolation=zoom_interpolation) {
		zoom_interpolation = _zoom_interpolation;
	};
	
	/// @function		set_interpolation_values(_position_interpolation, _angle_interpolation, _zoom_interpolation)
	/// @description	Sets the interpolation factors for moving, rotating and zooming the camera. Essentially how fast x, y, angle and zoom should approach their respective target values.
	/// @param {real}	[_position_interpolation=position_interpolation]	The position interpolation factor, as a fraction between 0 and 1. 1 = instant interpolation. 0 = no interpolation.
	/// @param {real}	[_angle_interpolation=angle_interpolation]		The angle interpolation factor, as a fraction between 0 and 1. 1 = instant interpolation. 0 = no interpolation.
	/// @param {real}	[_zoom_interpolation=zoom_interpolation]		The zoom interpolation factor, as a fraction between 0 and 1. 1 = instant interpolation. 0 = no interpolation.
	/// @returns		N/A
	static set_interpolation_values = function(_position_interpolation=position_interpolation, _angle_interpolation=angle_interpolation, _zoom_interpolation=zoom_interpolation) {
		set_position_interpolation(_position_interpolation);
		set_angle_interpolation(_angle_interpolation);
		set_zoom_interpolation(_zoom_interpolation);
	};
	
	/// @function		set_start_values(_xstart, _ystart, _anglestart, _zoomstart)
	/// @description	Sets the start values for the camera. These values are used by .reset(), so they are useful if you want to, for example, change where the camera should reset to.
	/// @param {real}	[_xstart=xstart]		The starting x position.
	/// @param {real}	[_ystart=ystart]		The starting y position.
	/// @param {real}	[_anglestart=anglestart]	The starting angle.
	/// @param {real}	[_zoomstart=zoomstart]		The starting zoom.
	/// @returns		N/A
	static set_start_values = function(_xstart = xstart, _ystart = ystart, _anglestart = anglestart, _zoomstart = zoomstart)
	{
		xstart		= _xstart;
		ystart		= _ystart;
		anglestart	= _anglestart;
		zoomstart	= _zoomstart;
	};
	
	/// @function		zoom_to(_target_zoom, _instant)
	/// @description	Sets the target_zoom factor for the camera.
	/// @param {real}	[_target_zoom=target_zoom]	The new target zoom for the camera. >1 = zoom in, else 1 = normal zoom, else >0 = zoom out.
	/// @param {bool}	[_instant=false]		Whether to apply target_zoom instantly (true) or interpolate towards it (false).
	/// @returns		N/A
	static zoom_to = function(_target_zoom=target_zoom, _instant=false) {
		target_zoom = clamp(_target_zoom, zoom_min, zoom_max);
		
		if (_instant)
		{
			__apply_zoom(_instant);
		}
	};
	
	/// @function		zoom_by(_zoom_factor, _instant)
	/// @description	Sets the target_zoom factor relative to the current target_zoom.
	/// @param {real}	[_zoom_factor=1]	The new relative target zoom for the camera. >1 = multiply (zoom in), >0 = divide (zoom out). Examples: 2 = double current zoom, 0.5 = halve current zoom.
	/// @param {bool}	[_instant=false]	Whether to apply target_zoom instantly (true) or interpolate towards it (false).
	/// @returns		N/A
	static zoom_by = function(_zoom_factor=1, _instant=false) {
		zoom_to(target_zoom * _zoom_factor, _instant);
	};
	
	/// @function		rotate_to(_target_angle, _instant)
	/// @description	Sets the target_angle for the camera.
	/// @param {real}	[_target_angle=target_angle]	The new target angle for the camera, in degrees.
	/// @param {bool}	[_instant=false]		Whether to apply target_angle instantly (true) or interpolate towards it (false).
	/// @returns		N/A
	static rotate_to = function(_target_angle=target_angle, _instant=false) {
		if (debug)
		{
			debug_rotation_points = [];
		}
		
		target_angle	= _target_angle;
		
		if (_instant)
		{
			__apply_rotation(_instant);
		}
	};
	
	/// @function		rotate_by(_degrees, _instant)
	/// @description	Increments camera's target_angle by _degrees.
	/// @param {real}	[_degrees=0]		How many degrees to rotate the camera by. >0 = clockwise, <0 = counter clockwise. 0 = no change.
	/// @param {bool}	[_instant=false]	Whether to apply target_angle instantly (true) or interpolate towards it (false).
	/// @returns		N/A
	static rotate_by = function(_degrees=0, _instant=false) {		
		rotate_to(target_angle + _degrees, _instant);
	};
	
	/// @function		move_to(_target_x, _target_y, _instant)
	/// @description	Sets the target_x/target_y for the camera.
	/// @param {real}	[_target_x=target_x]		The new target_x position for the camera.
	/// @param {real}	[_target_y=target_y]		The new target_y position for the camera.
	/// @param {bool}	[_instant=false]		Whether to apply target_x/target_y instantly (true) or interpolate towards them (false).
	/// @returns		N/A
	static move_to = function(_target_x=target_x, _target_y=target_y, _instant=false, _ignore_target=false) {
		target_x = _target_x;
		target_y = _target_y;
		
		if (_instant)
		{
			__apply_movement(_instant, _ignore_target);
		}
	};
	
	/// @function		move_by(_x, _y, _instant)
	/// @description	Moves the camera target_x/target_y by a relative amount.
	/// @param {real}	[_x=0]					The x value to move target_x by.
	/// @param {real}	[_y=0]					The y value to move target_y by.
	/// @param {bool}	[_instant=false]		Whether to apply target_x/target_y instantly (true) or interpolate towards them (false).
	/// @returns		N/A
	static move_by = function(_x=0, _y=0, _instant=false, _ignore_target=false) {
		move_to(target_x + _x, target_y + _y, _instant, _ignore_target);
	};
	
	/// @function		translate_to(_target_x, _target_y, _target_angle, _target_zoom, _instant)
	/// @description	Sets the target_x/target_y/target_angle/target_zoom for the camera.
	/// @param {real}	[_target_x=target_x]		The new target_x position for the camera.
	/// @param {real}	[_target_y=target_y]		The new target_y position for the camera.
	/// @param {real}	[_target_angle=target_angle]	The new target angle for the camera, in degrees.
	/// @param {real}	[_target_zoom=target_zoom]	The new target zoom for the camera. >1 = zoom in, else 1 = normal zoom, else >0 = zoom out.
	/// @param {bool}	[_instant=false]		Whether to apply target_x/target_y instantly (true) or interpolate towards them (false).
	/// @returns		N/A
	static translate_to = function(_target_x=x, _target_y=y, _target_angle=angle, _target_zoom=zoom, _instant=false) {
		zoom_to(_target_zoom, _instant);
		rotate_to(_target_angle, _instant);
		move_to(_target_x, _target_y, _instant);
	};
	
	/// @function		translate_by(_x, _y, _degrees, _zoom_factor, _instant)
	/// @description	Moves the camera target_x/target_y/target_angle/target_zoom by a relative amount.
	/// @param {real}	[_x=0]			The x value to move target_x by.
	/// @param {real}	[_y=0]			The y value to move target_y by.
	/// @param {real}	[_degrees=0]		How many degrees to rotate the camera by. >0 = clockwise, <0 = counter clockwise. 0 = no change.
	/// @param {real}	[_zoom_factor=1]	The new relative target zoom for the camera. >1 = multiply (zoom in), >0 = divide (zoom out). Examples: 2 = double current zoom, 0.5 = halve current zoom.
	/// @param {bool}	[_instant=false]	Whether to apply target_x/target_y instantly (true) or interpolate towards them (false).
	/// @returns		N/A
	static translate_by = function(_x=0, _y=0, _degrees=0, _zoom_factor=1, _instant=false) {
		zoom_by(_zoom_factor, _instant);
		rotate_by(_degrees, _instant);
		move_by(_x, _y, _instant);
	};
	
	/// @function		reset(_instant)
	/// @description	Resets the camera back to the startx/y/angle/zoom values.
	/// @param {bool}	[_instant=false]	Whether to apply target_x/target_y/target_angle/target_zoom instantly (true) or interpolate towards them (false).
	/// @returns		N/A
	static reset = function(_instant=false) {
		if (debug)
		{
			debug_rotation_points = [];
		}
		
		zoom_to(zoomstart, _instant);
		rotate_to(anglestart, _instant);
		move_to(xstart, ystart, _instant, true);
	};
	
	
	
		  /////////////
		 // panning //
		/////////////
	
	
	
	/// @function		is_panning()
	/// @description	Checks if camera is in panning mode. Useful to check before using .pan_to(). Start panning mode with .start_panning(), stop panning mode with .stop_panning().
	/// @returns		N/A
	static is_panning = function() {
		return panning;
	};
	
	/// @function		start_panning(_from_x, _from_y)
	/// @description	Starts camera panning mode and sets pan_xstart and pan_ystart. Start panning mode before using .pan_to()
	/// @param {real}	_from_x		The x co-ordinate from which you wish to pan from. Is used for calculations in .pan_to()
	/// @param {real}	_from_y		The y co-ordinate from which you wish to pan from. Is used for calculations in .pan_to()
	/// @returns		N/A
	static start_panning = function(_from_x, _from_y) {
		pan_xstart	= _from_x;
		pan_ystart	= _from_y;
		
		panning		= true;
	};
	
	/// @function		stop_panning()
	/// @description	Stops camera panning mode. Call this method when you have finished panning with .pan_to()
	/// @returns		N/A
	static stop_panning = function() {
		panning		= false;
	};
	
	/// @function		pan_to(_to_x, _to_y, _instant)
	/// @description	Pans the camera to _to_x, _to_y from pan_xstart and pan_ystart. Only call this function when in panning mode - See .start_panning(), .stop_panning() and .is_panning().
	/// @param {real}	[_to_x=pan_xstart]	The x co-ordinate to which you wish to pan.
	/// @param {real}	[_to_y=pan_ystart]	The y co-ordinate to which you wish to pan.
	/// @param {bool}	[_instant=false]	Whether to apply target_x, target_y instantly (true) or interpolate towards them (false).
	/// @returns		N/A
	static pan_to = function(_to_x=pan_xstart, _to_y=pan_ystart, _instant=true) {
		if (!panning)
		{
			throw ("Error: MCamera() attempting to use .pan_to() outside of panning mode. Check panning mode with .is_panning(), start panning mode with .start_panning(), and stop panning mode with .stop_panning()");
		}
		
		target_x -= _to_x - pan_xstart;
		target_y -= _to_y - pan_ystart;
		
		move_to(target_x, target_y, _instant);
	}
	
	
	
		  /////////////
		 // utility //
		/////////////
	
	
	
	/// @function		set_debug_mode(_is_debug_mode)
	/// @description	Sets debug to _is_debug_mode. When debug mode is active, the debug display is drawn to the screen.
	/// @param {bool}	[_is_debug_mode]	Whether to turn debug mode on (true) or off (false). Toggles debug by default.
	/// @returns		N/A
	static set_debug_mode = function(_is_debug_mode=!debug) {
		debug = _is_debug_mode;
	};
	
	/// @function		set_view(_view)
	/// @param {real}	[_view=0]	View number [0..7].
	/// @returns		N/A
	static set_view = function(_view=0)
	{
		view	= _view;
		id	= view_camera[view];
	}
	
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
	
	/// @function		find_gui_position()
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
}