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
	};					// See .translate_to(),	.translate_by()
	
	interpolation	= {
		position	: 1/8,		// See .set_position_interpolation()
		angle		: 1/4,		// See .set_angle_interpolation()
		zoom		: 1/16,		// See .set_zoom_interpolation()
		fn_position	: lerp,		// See .set_position_interpolation()
		fn_angle	: lerp,		// See .set_angle_interpolation()
		fn_zoom		: lerp		// See .set_zoom_interpolation()
	};
	
	// contraints
	
	zoom_min	= 1/16;			// See .set_zoom_limits()
	zoom_max	= 4;			// See .set_zoom_limits()
	
	anchors		= {
		position	: undefined,	// See .set_position_anchor()
		angle		: undefined,	// See .set_rotation_anchor()
		zoom		: undefined	// See .set_zoom_anchor()
	};
	
	boundary	= undefined;		// See .set_boundary()
	
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
		if (!is_undefined(anchors.position))
		{
			target.x	= anchors.position.x;
			target.y	= anchors.position.y;
		}
		
		// initialise window
		surface_resize(application_surface, width * pixel_scale, height * pixel_scale);
		display_set_gui_size(width, height);
		window_set_size(width * window_scale, height * window_scale);
		window_center();
	};
	
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
		__clamp_to_boundary(boundary);
		
		// update view
		var _new_width = width/zoom;
		var _new_height = height/zoom;
		
		camera_set_view_size(id, _new_width, _new_height);
		camera_set_view_angle(id, angle);
		camera_set_view_pos(id, x - (_new_width/2), y - (_new_height/2));
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
		if (!is_panning() && !is_undefined(_anchor))
		{
			move_to(_anchor.x, _anchor.y);
		}
	};
	
	/// @function							__enforce_angle_anchor(_anchor)
	/// @description						For internal use. Updates the camera position based on _anchor's position, to keep the anchor at the same place on-screen while adjusting angle.
	/// @param {struct,id.Instance,asset.GMObject,undefined}	[_anchor=anchors.angle]	The angle anchor. Must contain an x and y value if not undefined.
	/// @returns							N/A
	static __enforce_angle_anchor = function(_anchor=anchors.angle) {
		if (angle != previous.angle && !is_undefined(_anchor))
		{
			if (is_debugging() && abs(previous.angle-angle) >= 0.5)
			{
				array_push(debug.rotation.points, {
					x : x,
					y : y
				});
			}
			
			// calculate position
			var _distance	= point_distance(_anchor.x, _anchor.y, x, y);
			var _direction	= point_direction(_anchor.x, _anchor.y, x, y) + (previous.angle-angle);
			
			var _relative_x	= lengthdir_x(_distance, _direction);
			var _relative_y	= lengthdir_y(_distance, _direction);
			
			var _adjusted_x = _anchor.x + _relative_x;
			var _adjusted_y = _anchor.y + _relative_y;
			
			// update position - without move_to() so that x,y can be relative to previous x,y, to not override panning.
			var _diff_x	= _adjusted_x-target.x;
			var _diff_y	= _adjusted_y-target.y;
			
			target.x	+= _diff_x;
			target.y	+= _diff_y;
			
			x		+= _diff_x;
			y		+= _diff_y;
		}
	};
	
	/// @function							__enforce_zoom_anchor(_anchor)
	/// @description						For internal use. Updates the camera position based on _anchor's position, to keep the anchor at the same place on-screen while adjusting zoom.
	/// @param {struct,id.Instance,asset.GMObject,undefined}	[_anchor=anchors.zoom]	The zoom anchor. Must contain an x and y value if not undefined.
	/// @returns							N/A
	static __enforce_zoom_anchor = function(_anchor=anchors.zoom) {
		if (zoom != previous.zoom && !is_undefined(_anchor))
		{
			// calculate position
			var _screen_ratio_w	= (_anchor.x - camera_get_view_x(id)) / camera_get_view_width(id);
			var _screen_ratio_h	= (_anchor.y - camera_get_view_y(id)) / camera_get_view_height(id);
			
			var _view_width		= width/zoom;
			var _view_height	= height/zoom;
			
			var _adjusted_x		= _anchor.x - (_view_width * _screen_ratio_w) + (_view_width/2);
			var _adjusted_y		= _anchor.y - (_view_height * _screen_ratio_h) + (_view_height/2);
			
			// update position - without move_to() so that x,y can be set conditionally, for panning.
			var _diff_x		= _adjusted_x-target.x;
			var _diff_y		= _adjusted_y-target.y;
			
			target.x		+= _diff_x;
			target.y		+= _diff_y;
			
			if (!is_panning())
			{
				x		+= _diff_x;
				y		+= _diff_y;
			}
		}
	};
	
	/// @function			__clamp_to_boundary(_rect_or_undefined)
	/// @description		For internal use. Clamps the camera position to be within boundary.
	/// @param {struct,undefined}	[_rect_or_undefined=boundary]	The struct defining the boundary rectangle, or undefined for no clamping. Must contain x1, y1, x2, y2 values. Example: { x1=0, y1=0, x2=width, y2=height }
	/// @returns			N/A
	static __clamp_to_boundary = function(_rect_or_undefined = boundary) {
		if (!is_undefined(_rect_or_undefined))
		{
			var _view_width		= width/zoom;
			var _view_height	= height/zoom;		
			var _width_ratio	= abs( lengthdir_x(1, angle) );
			var _height_ratio	= abs( lengthdir_y(1, angle) );
			
			var _rotated_width	= (_width_ratio * _view_width) + (_height_ratio * _view_height);
			var _rotated_height	= (_width_ratio * _view_height) + (_height_ratio * _view_width);
		
			var _boundary_width	= _rect_or_undefined.x2 - _rect_or_undefined.x1;
			var _boundary_height	= _rect_or_undefined.y2 - _rect_or_undefined.y1;
			
			var _clamped_x		= (_rotated_width > _boundary_width)	? (_rect_or_undefined.x1 + _boundary_width/2)	: clamp(x, _rect_or_undefined.x1 + (_rotated_width/2), _rect_or_undefined.x2 - (_rotated_width/2));
			var _clamped_y		= (_rotated_height > _boundary_height)	? (_rect_or_undefined.y1 + _boundary_height/2)	: clamp(y, _rect_or_undefined.y1 + (_rotated_height/2), _rect_or_undefined.y2 - (_rotated_height/2));
			
			// update position - without move_to() to avoid springing while panning.
			target.x		= _clamped_x;
			target.y		= _clamped_y;
			
			x			= target.x;
			y			= target.y;
		}
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
		if (!is_undefined(boundary))
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
		if (!is_undefined(anchors.angle))
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
		if (!is_undefined(anchors.zoom))
		{
			draw_circle_color(anchors.zoom.x-_po, anchors.zoom.y-_po, _dot_radius, _col_zoom_anchor, _col_zoom_anchor, false);
		}
			
		// view
		var _view_x = camera_get_view_x(id);
		var _view_y = camera_get_view_y(id);
			
		draw_circle_color(_view_x-_po, _view_y-_po, _dot_radius, _col_view, _col_view, false);
			
		// position target dot
		if (!is_undefined(anchors.position))
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
	
	
	
		  /////////////////
		 // translation //
		/////////////////
	
	
	
	/// @function		set_position_interpolation(_value, _fn_interpolate)
	/// @description	Sets the interpolation factor and function for translating the x, y position towards target.x/.y. Essentially how fast x/y should approach target.x/.y.
	/// @param {real}	[_value=interpolation.position]			The interpolation factor, as a fraction between 0 and 1. 1 = instant interpolation. 0 = no interpolation.
	/// @param {function}	[_fn_interpolate=interpolation.fn_position]	Optional custom interpolation function for updating the camera's x and y values. Takes 3 arguments (_current, _target, _factor) and returns a real value, indicating the new _current value. Recommended that _factor of 0 returns _current and _factor of 1 returns _target.
	/// @returns		N/A
	static set_position_interpolation = function(_value=interpolation.position, _fn_interpolate=interpolation.fn_position) {
		interpolation.position		= _value;
		interpolation.fn_position	= _fn_interpolate;
	};
	
	/// @function		set_angle_interpolation(_value, _fn_interpolate)
	/// @description	Sets the interpolation factor and function for rotating the angle towards target.angle. Essentially how fast angle should approach target.angle.
	/// @param {real}	[_value=interpolation.angle]			The interpolation factor, as a fraction between 0 and 1. 1 = instant interpolation. 0 = no interpolation.
	/// @param {function}	[_fn_interpolate=interpolation.fn_angle]	Optional custom interpolation function for updating the camera's angle. Takes 3 arguments (_current, _target, _factor) and returns a real value, indicating the new _current value. Recommended that _factor of 0 returns _current and _factor of 1 returns _target.
	/// @returns		N/A
	static set_angle_interpolation = function(_value=interpolation.angle, _fn_interpolate=interpolation.fn_angle) {
		interpolation.angle	= _value;
		interpolation.fn_angle	= _fn_interpolate;
	};
	
	/// @function		set_zoom_interpolation(_value, _fn_interpolate)
	/// @description	Sets the interpolation factor and function for magnifying the zoom towards target.zoom. Essentially how fast zoom should approach target.zoom.
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
	
	/// @function		translate_to(_target_x, _target_y, _target_angle, _target_zoom)
	/// @description	Sets the target values for the camera.
	/// @param {real}	[_target_x=target.x]		The new target.x position for the camera.
	/// @param {real}	[_target_y=target.y]		The new target.y position for the camera.
	/// @param {real}	[_target_angle=target.angle]	The new target angle for the camera, in degrees.
	/// @param {real}	[_target_zoom=target.zoom]	The new target zoom for the camera. >1 = zoom in, else 1 = normal zoom, else >0 = zoom out.
	/// @returns		N/A
	static translate_to = function(_target_x=x, _target_y=y, _target_angle=angle, _target_zoom=zoom) {
		zoom_to(_target_zoom);
		rotate_to(_target_angle);
		move_to(_target_x, _target_y);
	};
	
	/// @function		translate_by(_x, _y, _degrees, _zoom_factor)
	/// @description	Sets the camera target by a relative amount.
	/// @param {real}	[_x=0]			The x value to move target.x by.
	/// @param {real}	[_y=0]			The y value to move target.y by.
	/// @param {real}	[_degrees=0]		How many degrees to rotate the camera by. >0 = clockwise, <0 = counter clockwise. 0 = no change.
	/// @param {real}	[_zoom_factor=1]	The new relative target zoom for the camera. >1 = multiply (zoom in), >0 = divide (zoom out). Examples: 2 = double current zoom, 0.5 = halve current zoom.
	/// @returns		N/A
	static translate_by = function(_x=0, _y=0, _degrees=0, _zoom_factor=1) {
		zoom_by(_zoom_factor);
		rotate_by(_degrees);
		move_by(_x, _y);
	};
	
	/// @function		reset()
	/// @description	Resets the camera back to the startx/y/angle/zoom values and stops panning.
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
	
	
	
		  /////////////
		 // panning //
		/////////////
	
	
	
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
	/// @description	Pans the camera to _to_x, _to_y from panning.start.x and panning.start.y. Only call this function when in panning mode - See .start_panning(), .stop_panning() and .is_panning().
	/// @param {real}	[_to_x=panning.start.x]	The x co-ordinate to which to pan.
	/// @param {real}	[_to_y=panning.start.y]	The y co-ordinate to which to pan.
	/// @returns		N/A
	static pan_to = function(_to_x=panning.start.x, _to_y=panning.start.y) {
		if (!is_panning())
		{
			throw ("Error: MCamera() attempting to use .pan_to() outside of panning mode. Check panning mode with .is_panning(), start panning mode with .start_panning(), and stop panning mode with .stop_panning()");
		}
		
		var _angle_diff			= angle - panning.start.angle;
		
		var _rotation_adjustment_len	= point_distance(anchors.angle.x, anchors.angle.y, panning.start.x, panning.start.y);
		var _rotation_adjustment_dir	= point_direction(anchors.angle.x, anchors.angle.y, panning.start.x, panning.start.y) - _angle_diff;
		
		var _rotated_pan_start_x	= anchors.angle.x + lengthdir_x(_rotation_adjustment_len, _rotation_adjustment_dir);
		var _rotated_pan_start_y	= anchors.angle.y + lengthdir_y(_rotation_adjustment_len, _rotation_adjustment_dir);
		
		var _relative_to_x		= _to_x - _rotated_pan_start_x;
		var _relative_to_y		= _to_y - _rotated_pan_start_y;
		
		var _angle_diff_is_cardinal	= (_angle_diff+360) mod 90 <= math_get_epsilon() || (_angle_diff+360) mod 90 >= 90 - math_get_epsilon();
		
		_relative_to_x			= _angle_diff_is_cardinal ? _relative_to_x : round(_relative_to_x);	// round co-ordinates at odd relative angles to avoid jitteriness
		_relative_to_y			= _angle_diff_is_cardinal ? _relative_to_y : round(_relative_to_y);	// round co-ordinates at odd relative angles to avoid jitteriness
		
		target.x			-= _relative_to_x;
		target.y			-= _relative_to_y;
		
		x				-= _relative_to_x;
		y				-= _relative_to_y;
	};
	
	
	
		  /////////////
		 // utility //
		/////////////
	
	
	
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
	
	
	
	// init
	
	create(_create_host_object_for_me);
}