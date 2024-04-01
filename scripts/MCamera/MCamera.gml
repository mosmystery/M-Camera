// feather ignore all



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
	
	self.host_object	= undefined;			// See .create()
	
	self.view		= 0;				// See .set_view()
	self.id			= view_camera[self.view];	// The view port id for this camera. See view_camera in the manual.
	
	self.width		= _width;			// The base, unscaled width of the view
	self.height		= _height;			// The base, unscaled height of the view
	self.window_scale	= _window_scale;		// The scale of width, height to apply to the window.
	self.pixel_scale	= _pixel_scale;			// The detail (width, height) of each pixel. Scales the application surface, but not the window or view. Only noticable at window scales higher than 1.
	
	self.x			= self.width/2;			// The current x position for this camera. Equivalent to the center of the screen in world co-ordinates.
	self.y			= self.height/2;		// The current y position for this camera. Equivalent to the center of the screen in world co-ordinates.
	self.angle		= 0;				// The current angle for this camera, in degrees.
	self.zoom		= 1;				// The current zoom factor for this camera. <1 = zoom in, else 1 = normal, else <0 = zoom out.
	
	// transform
	
	self.start		= {
		x	: self.x,
		y	: self.y,
		angle	: self.angle,
		zoom	: self.zoom
	};						// See .set_start_values() .reset()
	
	self.previous		= {
		x	: self.x,
		y	: self.y,
		angle	: self.angle,
		zoom	: self.zoom
	};						// The transform values from the previous step.
	
	self.target		= {
		x	: self.x,			// See .move_to(),	.move_by()
		y	: self.y,			// See .move_to(),	.move_by()
		angle	: self.angle,			// See .rotate_to(),	.rotate_by()
		zoom	: self.zoom			// See .zoom_to(),	.zoom_by()
	};						// See .transform_to(),	.transform_by()
	
	self.interpolation	= {
		position	: 1,			// See .set_position_interpolation()
		angle		: 1,			// See .set_angle_interpolation()
		zoom		: 1,			// See .set_zoom_interpolation()
		fn_position	: lerp,			// Custom interpolation function. See .set_position_interpolation()
		fn_angle	: lerp,			// Custom interpolation function. See .set_angle_interpolation()
		fn_zoom		: lerp			// Custom interpolation function. See .set_zoom_interpolation()
	};
	
	// constraints
	
	self.anchors		= {
		position	: undefined,		// See .set_position_anchor()
		angle		: undefined,		// See .set_angle_anchor()
		zoom		: undefined		// See .set_zoom_anchor()
	};
	
	self.boundary	= undefined;			// See .set_boundary()
	
	self.zoom_min	= 1/power(2, 16);		// See .set_zoom_limits()
	self.zoom_max	= power(2, 16);			// See .set_zoom_limits()
	
	// panning
	
	self.panning		= {
		active	: false,			// Whether panning mode is active or not. See .is_panning()
		start	: {
			x	: self.x,
			y	: self.y,
			angle	: self.angle,
			zoom	: self.zoom
		},					// The user-defined starting transform values for the pan. See .start_panning()
		target	: {
			x	: self.x,
			y	: self.y,
			angle	: self.angle,
			zoom	: self.zoom
		}					// The user-defined target transform values for the pan. See .start_panning()
	};						// See .is_panning(), .start_panning(), .stop_panning(), .pan_to()
	
	// shake
	
	self.shake = {
		x			: 0,		// The shake x position offset.
		y			: 0,		// The shake y position offset.
		angle			: 0,		// The shake angle offset.
		zoom			: 1,		// The shake zoom offset.
		intensity		: 0,		// The intensity of the shake. Is a multiplier for the transform values. 0 = No shake. 1 = match transform to limits. See .shake_to()
		intensity_falloff_rate	: 0.05,		// The falloff rate of intensity each step. See .set_shake_interpolation()
		fn_intensity		: lerp,		// Custom interpolation function for the intensity falloff. See .set_shake_interpolation()
		coarseness		: 0.25,		// How coarse the raw transform values should change each step. 1 = white noise. >0 <1 = brown noise. See .set_shake_limits()
		raw	: {
			distance	: 0,
			direction	: 0,
			angle		: 0,
			zoom		: 0
		},					// The raw internal tranform values. These are used to calculate shake.x .y .angle .zoom
		limits : {
			radius		: 4,
			angle		: 22.5,
			zoom		: 1,
			intensity	: 1
		}					// The maximum range for shake transform values. See .set_shake_limits()
	};						// See .set_shake_limits(), .set_shake_interpolation() .shake_to()
	
	// debug
	
	self.debug		= {
		active		: false,		// See .is_debugging(), .set_debugging()
		rotation	: {
			points	: []			// For internal use. Used to store and display the rotation arc in debug mode.
		},
		panning		: {
			camera_start_x	: self.x,	// The camera's starting x co-ordinate during panning.
			camera_start_y	: self.y	// The camera's starting y co-ordinate during panning.
		}
	};
	
	
	
	  /////////////
	 // methods //
	/////////////
	
	
	
		  ////////////
		 // events //
		////////////
	
	
	
	/// @description	The Create event. Initialises the camera.
	/// @param {bool}	[_create_host_object_for_me=true]	Whether to create a permanent host object that runs the event methods automatically (true) or not (false). Useful if you want to run the event methods in a different event or manage the hose object yourself.
	///								If false:	You will need to run this camera's .room_start(), .end_step(), and optionally .draw_end() events in a permanent object for intended results.
	///								If true:	An instance of objMCamera, a shell for this constructor's event methods, will automatically be created and stored in .host_object.
	/// @returns		N/A
	static create = function(_create_host_object_for_me = true) {
		// create host object
		if (_create_host_object_for_me)
		{
			self.host_object	= instance_create_depth(0, 0, -1, objMCamera);
			self.host_object.camera	= self;
		}
	
		// set target position
		if (self.anchors.position != undefined)
		{
			self.target.x	= self.anchors.position.x;
			self.target.y	= self.anchors.position.y;
		}
		
		// initialise window
		self.reset_window();
		
		// initialise shake
		self.__shake_reset_transform();
	};
	
	/// @description	The destroy event, for cleaning up the host object, anchors and boundary. Call this before deleting / dereferencing the camera struct.
	/// @returns		N/A
	static destroy	= function() {
		self.anchors.position	= undefined;
		self.anchors.angle	= undefined;
		self.anchors.zoom	= undefined;
		self.boundary		= undefined;
		
		if (self.host_object == undefined)
		{
			return;
		}
		
		instance_destroy(self.host_object, true);
	};
	
	/// @description	The Room Start event. Enables the view for this room.
	/// @returns		N/A
	static room_start = function() {
		view_enabled		= true;
		view_visible[self.view]	= true;
	};
	
	/// @description	The End Step event. Updates the camera tranform.
	/// @returns		N/A
	static end_step = function() {
		// update transform
		self.previous.x		= self.x;
		self.previous.y		= self.y;
		self.previous.angle	= self.angle;
		self.previous.zoom	= self.zoom;
		
		self.x		= self.interpolation.fn_position(self.x, self.target.x, self.interpolation.position);
		self.y		= self.interpolation.fn_position(self.y, self.target.y, self.interpolation.position);
		self.angle	= self.interpolation.fn_angle(self.angle, self.target.angle, self.interpolation.angle);
		self.zoom	= self.interpolation.fn_zoom(self.zoom, self.target.zoom, self.interpolation.zoom);
		
		// apply constraints
		self.__enforce_zoom_anchor(self.anchors.zoom);
		self.__enforce_angle_anchor(self.anchors.angle);
		self.__enforce_position_anchor(self.anchors.position);
		self.__apply_panning(self.anchors.angle);
		self.__clamp_to_boundary(self.boundary);
		self.__update_shake(self.anchors.angle, self.anchors.zoom);
		
		// update view
		camera_set_view_size(self.id, self.view_width() / self.shake.zoom, self.view_height() / self.shake.zoom);
		camera_set_view_angle(self.id, self.angle + self.shake.angle);
		camera_set_view_pos(self.id, self.view_x() + self.shake.x, self.view_y() + self.shake.y);
	};
	
	/// @description	The Draw End event, for drawing the camera debug overlay.
	/// @returns		N/A
	static draw_end = function() {
		self.__debug_draw();
	};
	
	
	
		  //////////////////////////////////////
		 // event helpers - for internal use //
		//////////////////////////////////////
	
	
	
	/// @description						For internal use. Updates the camera position based on _anchor's position, to keep the anchor at the same place on-screen while adjusting position.
	/// @param {struct,id.Instance,asset.GMObject,undefined}	[_anchor=anchors.position]	The position anchor. Must contain an x and y value if not undefined.
	/// @returns							N/A
	static __enforce_position_anchor = function(_anchor=self.anchors.position) {
		if (_anchor != undefined)
		{
			self.target.x = _anchor.x;
			self.target.y = _anchor.y;
		}
	};
	
	/// @description						For internal use. Updates the camera position based on _anchor's position, to keep the anchor at the same place on-screen while adjusting angle.
	/// @param {struct,id.Instance,asset.GMObject,undefined}	[_anchor=anchors.angle]	The angle anchor. Must contain an x and y value if not undefined.
	/// @returns							N/A
	static __enforce_angle_anchor = function(_anchor=self.anchors.angle) {
		if (self.angle != self.previous.angle && _anchor != undefined)
		{
			if (self.is_debugging() && abs(self.previous.angle - self.angle) >= 0.5)
			{
				array_push(self.debug.rotation.points, {
					x : self.x,
					y : self.y
				});
			}
			
			var _distance	= point_distance(_anchor.x, _anchor.y, self.x, self.y);
			var _direction	= point_direction(_anchor.x, _anchor.y, self.x, self.y) + (self.previous.angle - self.angle);
			
			var _relative_x	= lengthdir_x(_distance, _direction);
			var _relative_y	= lengthdir_y(_distance, _direction);
			
			self.target.x	= _anchor.x + _relative_x;
			self.target.y	= _anchor.y + _relative_y;
			
			self.x		= self.target.x;
			self.y		= self.target.y;
		}
	};
	
	/// @description						For internal use. Updates the camera position based on _anchor's position, to keep the anchor at the same place on-screen while adjusting zoom.
	/// @param {struct,id.Instance,asset.GMObject,undefined}	[_anchor=anchors.zoom]	The zoom anchor. Must contain an x and y value if not undefined.
	/// @returns							N/A
	static __enforce_zoom_anchor = function(_anchor=self.anchors.zoom) {
		if (self.zoom != self.previous.zoom && _anchor != undefined)
		{
			var _screen_ratio_w	= (_anchor.x - self.view_x_previous()) / self.view_width_previous();
			var _screen_ratio_h	= (_anchor.y - self.view_y_previous()) / self.view_height_previous();
			
			self.target.x		= (_anchor.x - (_screen_ratio_w * self.view_width())) + (self.view_width()/2);
			self.target.y		= (_anchor.y - (_screen_ratio_h * self.view_height())) + (self.view_height()/2);
			
			self.x			= self.target.x;
			self.y			= self.target.y;
		}
	};
	
	/// @description						For internal use. Updates the camera position based on the panning start and target values, and angle angle.
	/// @param {struct,id.Instance,asset.GMObject,undefined}	[_angle_anchor=anchors.angle]	The angle anchor. Must contain an x and y value if not undefined.
	/// @returns							N/A
	static __apply_panning = function(_angle_anchor=self.anchors.angle) {
		if (!self.is_panning())
		{
			return;
		}
		
		if (_angle_anchor == undefined)
		{
			self.target.x	-= self.panning.target.x - self.panning.start.x;
			self.target.y	-= self.panning.target.y - self.panning.start.y;
			
			self.x		= self.target.x;
			self.y		= self.target.y;
			
			return;
		}
		
		var _angle_diff		= self.panning.start.angle - self.previous.angle;
		
		var _pan_distance	= point_distance(_angle_anchor.x, _angle_anchor.y, self.panning.start.x, self.panning.start.y);
		var _pan_direction	= point_direction(_angle_anchor.x, _angle_anchor.y, self.panning.start.x, self.panning.start.y) + _angle_diff;
		
		var _rotated_pan_x	= _angle_anchor.x + lengthdir_x(_pan_distance, _pan_direction);
		var _rotated_pan_y	= _angle_anchor.y + lengthdir_y(_pan_distance, _pan_direction);
		
		var _relative_target_x	= self.panning.target.x - _rotated_pan_x;
		var _relative_target_y	= self.panning.target.y - _rotated_pan_y;
		
		var _angle_is_cardinal	= (_angle_diff+360) mod 90 <= math_get_epsilon() || (_angle_diff+360) mod 90 >= 90 - math_get_epsilon();
		
		self.target.x		-= _angle_is_cardinal ? _relative_target_x : round(_relative_target_x);		// round co-ordinates at odd relative angles to avoid jitteriness
		self.target.y		-= _angle_is_cardinal ? _relative_target_y : round(_relative_target_y);		// round co-ordinates at odd relative angles to avoid jitteriness
		
		self.x			= self.target.x;
		self.y			= self.target.y;
	};
	
	/// @description		For internal use. Clamps the camera position to be within boundary _rect.
	/// @param {struct,undefined}	[_rect=boundary]	The struct defining the boundary rectangle, or undefined for no clamping. Must contain x1, y1, x2, y2 values. Example: { x1=0, y1=0, x2=width, y2=height }
	/// @returns			N/A
	static __clamp_to_boundary = function(_rect = boundary) {
		if (_rect != undefined)
		{
			var _width_ratio	= abs( lengthdir_x(1, self.angle) );
			var _height_ratio	= abs( lengthdir_y(1, self.angle) );
			
			var _rotated_width	= (_width_ratio * self.view_width()) + (_height_ratio * self.view_height());
			var _rotated_height	= (_width_ratio * self.view_height()) + (_height_ratio * self.view_width());
			
			var _boundary_width	= _rect.x2 - _rect.x1;
			var _boundary_height	= _rect.y2 - _rect.y1;
			
			self.target.x		= (_rotated_width > _boundary_width)	? (_rect.x1 + _boundary_width/2)	: clamp(x, _rect.x1 + (_rotated_width/2), _rect.x2 - (_rotated_width/2));
			self.target.y		= (_rotated_height > _boundary_height)	? (_rect.y1 + _boundary_height/2)	: clamp(y, _rect.y1 + (_rotated_height/2), _rect.y2 - (_rotated_height/2));
			
			self.x			= self.target.x;
			self.y			= self.target.y;
		}
	};
	
	/// @description						For internal use. Updates the shake transform and intensity based on anchors and shake members.
	/// @param {struct,id.Instance,asset.GMObject,undefined}	[_angle.anchor=anchors.angle]	The angle anchor. Must contain an x and y value if not undefined.
	/// @param {struct,id.Instance,asset.GMObject,undefined}	[_zoom_anchor=anchors.zoom]	The zoom anchor. Must contain an x and y value if not undefined.
	///								Warning: if _zoom_anchor does not equal that of .__enforce_zoom_anchor(), the camera will drift when simultaneously zooming and shaking.
	/// @returns		N/A
	static __update_shake = function(_angle_anchor=self.anchors.angle, _zoom_anchor=self.anchors.zoom) {
		if (self.shake.intensity == 0)
		{
			return;
		}
		
		with (self.shake)
		{
			// set raw values
			self.raw.distance	+= self.coarseness * random_range(-self.limits.radius, self.limits.radius);
			self.raw.direction	+= self.coarseness * random_range(-180, 180);
			self.raw.angle		+= self.coarseness * random_range(-self.limits.angle, self.limits.angle);
			self.raw.zoom		+= self.coarseness * random_range(-self.limits.zoom, self.limits.zoom);
			
			self.raw.distance	= reflect(self.raw.distance, -self.limits.radius, self.limits.radius);
			self.raw.direction	= wrap(self.raw.direction, -180, 180);
			self.raw.angle		= reflect(self.raw.angle, 0, self.limits.angle);
			self.raw.zoom		= reflect(self.raw.zoom, -(self.limits.zoom/2), self.limits.zoom/2);
			
			// set output values
			self.x			= lengthdir_x(self.intensity * self.raw.distance, self.raw.direction);
			self.y			= lengthdir_y(self.intensity * self.raw.distance, self.raw.direction);
			self.angle		= (self.intensity * self.raw.angle) - (self.intensity * (self.limits.angle/2));
			self.zoom		= power(sqrt(2), self.intensity * self.raw.zoom);
			
			// enforce zoom anchor
			if (_zoom_anchor != undefined)
			{
				var _diff_width		= (other.view_width()/self.zoom) - other.view_width();
				var _diff_height	= (other.view_height()/self.zoom) - other.view_height();
				
				var _screen_ratio_w	= (_zoom_anchor.x-other.view_x()) / other.view_width();
				var _screen_ratio_h	= (_zoom_anchor.y-other.view_y()) / other.view_height();
				
				self.x			-= _screen_ratio_w * _diff_width;
				self.y			-= _screen_ratio_h * _diff_height;
			}
			
			// enforce angle anchor
			if (_angle_anchor != undefined)
			{
				var _distance	= point_distance(_angle_anchor.x, _angle_anchor.y, other.x, other.y);
				var _direction	= point_direction(_angle_anchor.x, _angle_anchor.y, other.x, other.y) - self.angle;
				
				var _relative_x	= lengthdir_x(_distance, _direction);
				var _relative_y	= lengthdir_y(_distance, _direction);
				
				self.x		+= (_angle_anchor.x + _relative_x) - other.x;
				self.y		+= (_angle_anchor.y + _relative_y) - other.y;
			}
			
			// intensity falloff
			self.intensity	= self.fn_intensity(self.intensity, 0, self.intensity_falloff_rate);
		}
		
		// reset transform
		if (abs(self.shake.intensity) <= math_get_epsilon())
		{
			self.shake.intensity	= 0;
			
			self.__shake_reset_transform();
		}
	};
	
	/// @description	For internal use. Resets the shake transform to initial values.
	/// @returns		N/A
	static __shake_reset_transform = function() {
		self.shake.raw.distance		= 0;
		self.shake.raw.direction	= random(360)-180;
		self.shake.raw.angle		= self.shake.limits.angle/2;
		self.shake.raw.zoom		= 0;
		
		self.shake.x			= 0;
		self.shake.y			= 0;
		self.shake.angle		= 0;
		self.shake.zoom			= 1;
	};
	
	/// @description	For internal use. Draws the debug display.
	/// @returns		N/A
	static __debug_draw = function() {
		if (!self.is_debugging())
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
			
		var _nav_dots_radius	= 2 / self.zoom;
		var _nav_ring_radius	= 16 / self.zoom;
		var _nav_dotring_radius	= _nav_ring_radius + (4 / self.zoom);
		var _dot_radius		= clamp(4, _nav_dots_radius, _nav_ring_radius);
			
		var _po			= 1; // pixel offset
			
		// boundary
		if (self.boundary != undefined)
		{
			draw_rectangle_colour(self.boundary.x1+0.5, self.boundary.y1+0.5, self.boundary.x2-1.5, self.boundary.y2-1.5, _col_boundary, _col_boundary, _col_boundary, _col_boundary, true);
		}
		
			// dots
		
		// rotation arc
		var _rot_arc_length = array_length(self.debug.rotation.points);
			
		if (_rot_arc_length >= 1)
		{
			draw_pointarray(0, 0, self.debug.rotation.points, false, pr_linestrip, _col_rot_arc);
			draw_circle_color(self.debug.rotation.points[0].x-_po, self.debug.rotation.points[0].y-_po, _dot_radius, _col_rot_arc, _col_rot_arc, false);
			draw_circle_color(self.debug.rotation.points[_rot_arc_length-1].x-_po, self.debug.rotation.points[_rot_arc_length-1].y-_po, _dot_radius, _col_rot_arc, _col_rot_arc, false);
		}
			
		// rotation anchor
		if (anchors.angle != undefined)
		{
			draw_circle_color(self.anchors.angle.x-_po, self.anchors.angle.y-_po, _dot_radius, _col_rot_anchor, _col_rot_anchor, false);
		}
		
		// pan line
		if (is_panning())
		{
			var _x1 = self.panning.start.x;
			var _y1 = self.panning.start.y;
			var _x2 = self.target.x + (self.panning.start.x - self.debug.panning.camera_start_x);
			var _y2 = self.target.y + (self.panning.start.y - self.debug.panning.camera_start_y);
			
			draw_line_color(_x1, _y1, _x2, _y2, _col_pan_line, _col_pan_line);
			draw_circle_color(_x1-_po, _y1-_po, _dot_radius, _col_pan_line, _col_pan_line, false);
			draw_circle_color(_x2-_po, _y2-_po, _dot_radius, _col_pan_line, _col_pan_line, false);
		}
			
		// zoom anchor
		if (self.anchors.zoom != undefined)
		{
			draw_circle_color(self.anchors.zoom.x-_po, self.anchors.zoom.y-_po, _dot_radius, _col_zoom_anchor, _col_zoom_anchor, false);
		}
			
		// view
		var _view_x = camera_get_view_x(id);
		var _view_y = camera_get_view_y(id);
			
		draw_circle_color(_view_x-_po, _view_y-_po, _dot_radius, _col_view, _col_view, false);
			
		// position target dot
		if (self.anchors.position != undefined)
		{
			draw_circle_color(self.anchors.position.x-_po, self.anchors.position.y-_po, _dot_radius, _col_target, _col_target, false);
		}
		
			// nav ring
		
		// dots
		if (_rot_arc_length >= 1)
		{
			self.__debug_draw_nav_dot(self.debug.rotation.points[0].x, debug.rotation.points[0].y, _nav_dots_radius, _nav_dotring_radius, _col_rot_arc);					// rotation arc start
			self.__debug_draw_nav_dot(self.debug.rotation.points[_rot_arc_length-1].x, self.debug.rotation.points[_rot_arc_length-1].y, _nav_dots_radius, _nav_dotring_radius, _col_rot_arc);	// rotation arc end
		}
		
		self.__debug_draw_nav_anchor_dot(self.anchors.angle, _nav_dots_radius, _nav_dotring_radius, _col_rot_anchor);	// rotation anchor
		self.__debug_draw_nav_anchor_dot(self.anchors.zoom, _nav_dots_radius, _nav_dotring_radius, _col_zoom_anchor);	// zoom anchor
		
		if (is_panning())
		{
			var _x2 = self.target.x + (self.panning.start.x - self.debug.panning.camera_start_x);
			var _y2 = self.target.y + (self.panning.start.y - self.debug.panning.camera_start_y);
			
			self.__debug_draw_nav_dot(self.panning.start.x, self.panning.start.y, _nav_dots_radius, _nav_dotring_radius, _col_pan_line);	// pan line start
			self.__debug_draw_nav_dot(_x2, _y2, _nav_dots_radius, _nav_dotring_radius, _col_pan_line);			// pan line end
		}
		
		__debug_draw_nav_dot(_view_x, _view_y, _nav_dots_radius, _nav_dotring_radius, _col_view);		// view
		
		if (is_struct(self.target) || instance_exists(self.target))
		{
			self.__debug_draw_nav_dot(self.target.x, self.target.y, _nav_dots_radius, _nav_dotring_radius, _col_target);	// target
		}
		
		// ring
		draw_circle_color(x-_po, y-_po, _nav_ring_radius, _col_pos, _col_pos, true);
		draw_line_color(x-_po, y-_po, x+_nav_ring_radius-_po, y-_po, _col_pos, _col_pos);
	};
	
	/// @description		For internal use. Draws a dot on the outer edge of the navigation ring of the debug display.
	/// @param {real}		_x			The x position to draw the dot.
	/// @param {real}		_x			The y position to draw the dot.
	/// @param {real}		_nav_dots_radius	The radius of the dot.
	/// @param {real}		_nav_dotring_radius	The distance from the center of the navigation ring that this dot should be drawn at.
	/// @param {constant.Color}	_col			The colour to draw the dot.
	/// @returns			N/A
	static __debug_draw_nav_dot = function(_x, _y, _nav_dots_radius, _nav_dotring_radius, _col) {
		if (_nav_dotring_radius < point_distance(self.x, self.y, _x, _y))
		{
			var _direction	= point_direction(self.x, self.y, _x, _y);
			
			var _point_x	= lengthdir_x(_nav_dotring_radius, _direction);
			var _point_y	= lengthdir_y(_nav_dotring_radius, _direction);
					
			draw_circle_color(self.x+_point_x-1, self.y+_point_y-1, _nav_dots_radius, _col, _col, false);
		}
	};
	
	/// @description						For internal use. Draws a dot on the outer edge of the navigation ring of the debug display, to represent an anchor object.
	/// @param {struct, id.Instance, Asset.GMObject, undefined}	_anchor			The anchor struct/object to derive x,y co-ordinates from, for where to draw the dot.
	/// @param {real}						_nav_dots_radius	The radius of the dot.
	/// @param {real}						_nav_dotring_radius	The distance from the center of the navigation ring that this dot should be drawn at.
	/// @param {constant.Color}					_col			The colour to draw the dot.
	/// @returns							N/A
	static __debug_draw_nav_anchor_dot = function(_anchor, _nav_dots_radius, _nav_dotring_radius, _col) {
		if (is_struct(_anchor) || instance_exists(_anchor))
		{
			self.__debug_draw_nav_dot(_anchor.x, _anchor.y, _nav_dots_radius, _nav_dotring_radius, _col);
		}
	};
	
	
	
		  /////////////////
		 // constraints //
		/////////////////
	
	
	
	/// @description						Sets the position anchor (target object or struct) for the camera to follow.
	///								Note: If the data type you pass is a copy and not a reference, the camera will remain anchored to the x,y position as when first set. In this case, consider setting the anchor each frame if its position is not static.
	/// @param {struct,id.Instance,asset.GMObject,undefined}	[_position_anchor=undefined]	The position anchor. Must contain an x and y value if not undefined. Pass undefined to remove anchor. Make sure to remove the anchor if it no longer exists, such as for destroyed instances.
	/// @returns							N/A
	static set_position_anchor = function(_position_anchor=undefined) {
		self.anchors.position = _position_anchor;
	};
	
	/// @description						Sets the angle anchor for the camera to pivot around when rotating. Useful for keeping a position at the same place on the screen, such as the player position, the mouse position, the center of the level or a Vector2.
	///								Note: If the data type you pass is a copy and not a reference, the camera will remain anchored to the x,y position as when first set. In this case, consider setting the anchor each frame if its position is not static.
	/// @param {struct,id.Instance,asset.GMObject,undefined}	[_angle_anchor=undefined]	The angle anchor. Must contain an x and y value if not undefined. Pass undefined to remove anchor. Make sure to remove the anchor if it no longer exists, such as for destroyed instances.
	/// @returns							N/A
	static set_angle_anchor = function(_angle_anchor=undefined) {
		self.anchors.angle = _angle_anchor;
	};
	
	/// @description						Sets the zoom anchor for the camera to zoom towards or away from. Useful for zooming towards or away from a point of interest, such as in cutscenes, or the mouse in an editor or strategy game.
	///								Note: If the data type you pass is a copy and not a reference, the camera will remain anchored to the x,y position as when first set. In this case, consider setting the anchor each frame if its position is not static.
	/// @param {struct,id.Instance,asset.GMObject,undefined}	[_zoom_anchor=undefined]	The zoom anchor. Must contain an x and y value if not undefined. Pass undefined to remove anchor. Make sure to remove the anchor if it no longer exists, such as for destroyed instances.
	/// @returns							N/A
	static set_zoom_anchor = function(_zoom_anchor=undefined) {
		self.anchors.zoom = _zoom_anchor;
	};
	
	/// @description						Sets the position, angle, and zoom anchors for the camera. See .set_position_anchor(), .set_angle_anchor() and .set_zoom_anchor() for details.
	///								Note: If the data type you pass is a copy and not a reference, the camera will remain anchored to the x,y position as when first set. In this case, consider setting the anchor each frame if it should not be static.
	/// @param {struct,id.Instance,asset.GMObject,undefined}	[_position_anchor=undefined]		The position anchor. Must contain an x and y value if not undefined. Pass undefined to remove anchor. Make sure to remove the anchor if it no longer exists, such as for destroyed instances.
	/// @param {struct,id.Instance,asset.GMObject,undefined}	[_angle_anchor=_position_anchor]	The angle anchor. Must contain an x and y value if not undefined. Pass undefined to remove anchor. Make sure to remove the anchor if it no longer exists, such as for destroyed instances.
	/// @param {struct,id.Instance,asset.GMObject,undefined}	[_zoom_anchor=_angle_anchor]		The zoom anchor. Must contain an x and y value if not undefined. Pass undefined to remove anchor. Make sure to remove the anchor if it no longer exists, such as for destroyed instances.
	/// @returns							N/A
	static set_anchors = function(_position_anchor=undefined, _angle_anchor=_position_anchor, _zoom_anchor=_angle_anchor) {
		self.set_position_anchor(_position_anchor);
		self.set_angle_anchor(_angle_anchor);
		self.set_zoom_anchor(_zoom_anchor);
	};
	
	/// @description	Sets the minimum and maximum limits for the camera zoom.
	/// @param {real}	[_zoom_min]	The minimum camera zoom. Limited to 1/(2^16), or 16 halvings of the base zoom amount. Defaults to min limit.
	/// @param {real}	[_zoom_max]	The maximum camera zoom. Limited to 2^16, or 16 doublings of the base zoom amount at most, and _zoom_min at least. Defaults to max limit.
	/// @returns		N/A
	static set_zoom_limits = function(_zoom_min = 1/power(2, 16), _zoom_max = power(2, 16)) {
		var _min = 1/power(2, 16);
		var _max = power(2, 16);
		
		self.zoom_min = clamp(_zoom_min, _min, _max);
		self.zoom_max = clamp(_zoom_max, max(_min, _zoom_min), _max);
	};
	
	/// @description	Defines the boundary for the camera to clamp to. Useful for keeping the camera within the bounds of a level or area. Unset with .unset_boundary(). Note: The outer bounds may be visible while the camera is rotating or zoomed out.
	/// @param {real}	[_x1=0]			The left edge of the boundary.
	/// @param {real}	[_y1=0]			The top edge of the boundary.
	/// @param {real}	[_x2=room_width]	The right edge of the boundary.
	/// @param {real}	[_y2=room_height]	The bottom edge of the boundary.
	/// @returns		N/A
	static set_boundary = function(_x1=0, _y1=0, _x2=room_width, _y2=room_height) {
		self.boundary = {
			x1 : _x1,
			y1 : _y1,
			x2 : _x2,
			y2 : _y2
		};
	};
	
	/// @description	Unsets the position boundary for the camera, ensuring the camera's position is not limited. Set with .set_boundary()
	/// @returns		N/A
	static unset_boundary = function() {
		self.boundary = undefined;
	};
	
	
	
		  ///////////////////////////////
		 // transformation - settings //
		///////////////////////////////
	
	
	
	/// @description	Sets the start values for the camera. These values are used by .reset(), so they are useful if you want to, for example, change where the camera should reset to.
	/// @param {real}	[_xstart=width/2]	The starting x position.
	/// @param {real}	[_ystart=height/2]	The starting y position.
	/// @param {real}	[_anglestart=0]		The starting angle.
	/// @param {real}	[_zoomstart=1]		The starting zoom.
	/// @returns		N/A
	static set_start_values = function(_xstart = self.width/2, _ystart = self.height/2, _anglestart = 0, _zoomstart = 1) {
		self.start.x		= _xstart;
		self.start.y		= _ystart;
		self.start.angle	= _anglestart;
		self.start.zoom		= _zoomstart;
	};
	
	/// @description	Sets the interpolation factor and function for transforming the x, y position towards target.x/.y. Essentially how fast x/y should approach target.x/.y.
	/// @param {real}	[_value=1]		The interpolation factor, as a fraction between 0 and 1. 1 = instant interpolation. 0 = no change.
	/// @param {function}	[_fn_interpolate=lerp]	Optional custom interpolation function for updating the camera's x and y values. Takes 3 arguments (_current, _target, _factor) and returns a real value, indicating the new _current value. Recommended that _factor of 0 returns _current and _factor of 1 returns _target.
	/// @returns		N/A
	static set_position_interpolation = function(_value=1, _fn_interpolate=lerp) {
		self.interpolation.position		= _value;
		self.interpolation.fn_position	= _fn_interpolate;
	};
	
	/// @description	Sets the interpolation factor and function for transforming the angle towards target.angle. Essentially how fast angle should approach target.angle.
	/// @param {real}	[_value=1]		The interpolation factor, as a fraction between 0 and 1. 1 = instant interpolation. 0 = no change.
	/// @param {function}	[_fn_interpolate=lerp]	Optional custom interpolation function for updating the camera's angle. Takes 3 arguments (_current, _target, _factor) and returns a real value, indicating the new _current value. Recommended that _factor of 0 returns _current and _factor of 1 returns _target.
	/// @returns		N/A
	static set_angle_interpolation = function(_value=1, _fn_interpolate=lerp) {
		self.interpolation.angle	= _value;
		self.interpolation.fn_angle	= _fn_interpolate;
	};
	
	/// @description	Sets the interpolation factor and function for transforming the zoom towards target.zoom. Essentially how fast zoom should approach target.zoom.
	/// @param {real}	[_value=1]		The interpolation factor, as a fraction between 0 and 1. 1 = instant interpolation. 0 = no change.
	/// @param {function}	[_fn_interpolate=lerp]	Optional custom interpolation function for updating the camera's zoom. Takes 3 arguments (_current, _target, _factor) and returns a real value, indicating the new _current value. Recommended that _factor of 0 returns _current and _factor of 1 returns _target.
	/// @returns		N/A
	static set_zoom_interpolation = function(_value=1, _fn_interpolate=lerp) {
		self.interpolation.zoom		= _value;
		self.interpolation.fn_zoom	= _fn_interpolate;
	};
	
	/// @description	Sets the interpolation factors for moving, rotating and zooming the camera. Does not change the interpolation functions. Essentially how fast x, y, angle and zoom should approach their respective target values.
	/// @param {real}	[_position_interpolation=1]	The position interpolation factor, as a fraction between 0 and 1. 1 = instant interpolation. 0 = no change.
	/// @param {real}	[_angle_interpolation=1]	The angle interpolation factor, as a fraction between 0 and 1. 1 = instant interpolation. 0 = no change.
	/// @param {real}	[_zoom_interpolation=1]		The zoom interpolation factor, as a fraction between 0 and 1. 1 = instant interpolation. 0 = no change.
	/// @returns		N/A
	static set_interpolation = function(_position_interpolation=1, _angle_interpolation=1, _zoom_interpolation=1) {
		self.set_position_interpolation(_position_interpolation, self.interpolation.fn_position);
		self.set_angle_interpolation(_angle_interpolation, self.interpolation.fn_angle);
		self.set_zoom_interpolation(_zoom_interpolation, self.interpolation.fn_zoom);
	};
	
	
	
		  ////////////////////
		 // transformation //
		////////////////////
	
	
	
	/// @description	Sets the target.x/.y for the camera.
	/// @param {real}	[_target_x=target.x]		The new target.x position for the camera.
	/// @param {real}	[_target_y=target.y]		The new target.y position for the camera.
	/// @returns		N/A
	static move_to = function(_target_x=self.target.x, _target_y=self.target.y) {
		self.target.x = _target_x;
		self.target.y = _target_y;
	};
	
	/// @description	Moves the camera target.x/.y by a relative amount.
	/// @param {real}	[_x=0]				The x value to move target.x by.
	/// @param {real}	[_y=0]				The y value to move target.y by.
	/// @returns		N/A
	static move_by = function(_x=0, _y=0) {
		self.move_to(self.target.x + _x, self.target.y + _y);
	};
	
	/// @description	Sets the target.angle for the camera.
	/// @param {real}	[_target_angle=target.angle]	The new target angle for the camera, in degrees.
	/// @returns		N/A
	static rotate_to = function(_target_angle=self.target.angle) {
		if (self.is_debugging())
		{
			self.debug.rotation.points = [];
		}
		
		self.target.angle	= _target_angle;
		
		// wrap angle values to interpolate in the correct direction
		if (abs(self.target.angle - self.angle) == 180)
		{
			self.target.angle = choose(self.angle-180, self.angle+180);
		}
		else
		{
			self.target.angle = wrap(self.target.angle, 0, 360);
			
			while (abs(self.target.angle - self.angle) > 180)
			{
				self.angle	= (self.angle < self.target.angle) ? self.angle + 360 : self.angle - 360;
			}
		}
	};
	
	/// @description	Increments camera's target.angle by _degrees.
	/// @param {real}	[_degrees=0]		How many degrees to rotate the camera by. >0 = clockwise, <0 = counter clockwise. 0 = no change.
	/// @returns		N/A
	static rotate_by = function(_degrees=0) {
		self.rotate_to(self.target.angle + _degrees);
	};
	
	/// @description	Sets the target.zoom factor for the camera.
	/// @param {real}	[_target_zoom=target.zoom]	The new target zoom for the camera. >1 = zoom in, else 1 = normal zoom, else >0 = zoom out.
	/// @returns		N/A
	static zoom_to = function(_target_zoom=self.target.zoom) {
		self.target.zoom = clamp(_target_zoom, self.zoom_min, self.zoom_max);
	};
	
	/// @description	Sets the target.zoom factor relative to the current target.zoom.
	/// @param {real}	[_zoom_factor=1]	The new relative target zoom for the camera. >1 = multiply (zoom in), >0 = divide (zoom out). Examples: 2 = double current zoom, 0.5 = halve current zoom.
	/// @returns		N/A
	static zoom_by = function(_zoom_factor=1) {
		self.zoom_to(self.target.zoom * _zoom_factor);
	};
	
	/// @description	Sets the target values for the camera.
	/// @param {real}	[_target_x=target.x]		The new target.x position for the camera.
	/// @param {real}	[_target_y=target.y]		The new target.y position for the camera.
	/// @param {real}	[_target_angle=target.angle]	The new target angle for the camera, in degrees.
	/// @param {real}	[_target_zoom=target.zoom]	The new target zoom for the camera. >1 = zoom in, else 1 = normal zoom, else >0 = zoom out.
	/// @returns		N/A
	static transform_to = function(_target_x=self.x, _target_y=self.y, _target_angle=self.angle, _target_zoom=self.zoom) {
		self.move_to(_target_x, _target_y);
		self.rotate_to(_target_angle);
		self.zoom_to(_target_zoom);
	};
	
	/// @description	Sets the camera target by a relative amount.
	/// @param {real}	[_x=0]			The x value to move target.x by.
	/// @param {real}	[_y=0]			The y value to move target.y by.
	/// @param {real}	[_degrees=0]		How many degrees to rotate the camera by. >0 = clockwise, <0 = counter clockwise. 0 = no change.
	/// @param {real}	[_zoom_factor=1]	The new relative target zoom for the camera. >1 = multiply (zoom in), >0 = divide (zoom out). Examples: 2 = double current zoom, 0.5 = halve current zoom.
	/// @returns		N/A
	static transform_by = function(_x=0, _y=0, _degrees=0, _zoom_factor=1) {
		self.move_by(_x, _y);
		self.rotate_by(_degrees);
		self.zoom_by(_zoom_factor);
	};
	
	/// @description	Resets the camera back to the start values and stops panning. See .set_start_values() and .stop_panning().
	///			Optionally resets shake and settings.
	/// @param {bool}	[_reset_shake=false]		Whether to reset the shake transform (true) or not (false).
	/// @param {bool}	[_reset_settings=false]		Whether to unset shake settings, anchors, limits, boundary, interpolation, and start values (true) or not (false).
	/// @returns		N/A
	static reset = function(_reset_shake=false, _reset_settings=false) {
		if (self.is_debugging())
		{
			self.debug.rotation.points = [];
		}
		
		self.stop_panning();
		
		if (_reset_shake)
		{
			self.shake_to(0, true);
		}
		
		if (_reset_settings)
		{
			self.set_position_anchor();		// unset position anchor
			self.set_angle_anchor();		// unset angle anchor
			self.set_zoom_anchor();			// unset zoom anchor
			self.set_zoom_limits();			// unset zoom limits
			self.unset_boundary();			// unset boundary
			
			self.set_start_values();		// unset custom start values
			self.set_position_interpolation();	// unset custom position interpolation value and function
			self.set_angle_interpolation();		// unset custom angle interpolation value and function
			self.set_zoom_interpolation();		// unset custom zoom interpolation value and function
			
			self.set_shake_limits();		// unset custom shake limits
			self.set_shake_interpolation();		// unset custom shake interpolation value and function
		}
		
		self.target.x		= self.start.x;
		self.target.y		= self.start.y;
		self.target.angle	= self.start.angle;
		self.target.zoom	= self.start.zoom;
		
		self.x			= self.target.x;
		self.y			= self.target.y;
		self.angle		= self.target.angle;
		self.zoom		= self.target.zoom;
	};
	
	
	
		  //////////////////////////////
		 // transformation - panning //
		//////////////////////////////
	
	
	
	/// @description	Checks if camera is in panning mode. Useful to check before using .pan_to(). Start panning mode with .start_panning(), stop panning mode with .stop_panning().
	/// @returns {bool}	Returns panning (true) or not (false).
	static is_panning = function() {
		return panning.active;
	};
	
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
	
	/// @description	Stops camera panning mode. Call this method when you have finished panning with .pan_to()
	/// @returns		N/A
	static stop_panning = function() {
		panning.active		= false;
	};
	
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
	
	
	
	/// @description	Sets the maximum radius, angle, and zoom for camera shake transformation. Additionally sets the courseness for transform value change. If you don't want shake to transform a particular way, set that transform limit to 0.
	/// @param {real}	[_radius=4]		The maximum distance from 0,0 the camera x,y can be transformed.
	/// @param {real}	[_angle=22.5]		The maximum angle range the camera can be rotated. Output angle is added to negative half of the range. For example, 20 will transform the camera between -10 to 10 degrees.
	/// @param {real}	[_zoom=1]		The maximum range the zoom factor can fluctuate in.
	/// @param {real}	[_coarseness=0.25]	The coarseness of the brownian step function for changing each transform value each frame. 0 = +-no change (not recommended), 1 = +-whole range (white noise).
	///						For intended results, input a value >0 and <=1. For white noise, input 1. For typical brown noise, try something between 0.1 and 0.5.
	/// @param {real}	[_intensity=1]		The maximum intensity of the shake. Supports any number below infinity. See .shake_to() and .shake_by()
	/// @returns		N/A
	static set_shake_limits = function(_radius=4, _angle=22.5, _zoom=0.25, _coarseness=0.25, _intensity=1) {
		shake.limits.radius	= _radius;
		shake.limits.angle	= _angle;
		shake.limits.zoom	= _zoom;
		shake.coarseness	= _coarseness;
		shake.limits.intensity	= _intensity;
	};
	
	/// @description	Sets the interpolation factor and function for reducing the intensity of the shake. Essentially how fast intensity should approach 0.
	/// @param {real}	[_value=0.05]		The interpolation factor, as a fraction between 0 and 1. 1 = instantly turn off intensity. 0 = maintain intensity.
	/// @param {function}	[_fn_interpolate=lerp]	Optional custom interpolation function for fading intensity. Takes 3 arguments (_current, _target, _factor) and returns a real value, indicating the new _current value. Recommended that _factor of 0 returns _current and _factor of 1 returns _target.
	/// @returns		N/A
	static set_shake_interpolation = function(_value=0.05, _fn_interpolate=lerp) {
		shake.intensity_falloff_rate	= _value;
		shake.fn_intensity		= _fn_interpolate;
	};
	
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
	
	/// @description	Adds _intensity on to the intensity for the shake. Useful for increasing the shake with consecutive hits.
	/// @param {real}	_intensity			The intensity to add on to the intensity level of the shake; a multiplier for the shake limits. See .set_shake_limits(), .shake_to()
	/// @param {bool}	[_reset_transform=false]	Whether to reset the initial transform values before the shake (true) or not (false).
	/// @returns		N/A
	static shake_by = function(_intensity, _reset_transform=false) {
		shake_to(shake.intensity+_intensity, _reset_transform);
	};
	
	
	
		  //////////////
		 // resizing //
		//////////////
	
	
	
	/// @description	Returns the camera's x co-ordinate, equivalent to the center of the screen.
	/// @returns {real}	Returns the camera's x co-ordinate, equivalent to the center of the screen.
	static get_x = function() {
		return x;
	};
	
	/// @description	Returns the camera's y co-ordinate, equivalent to the center of the screen.
	/// @returns {real}	Returns the camera's y co-ordinate, equivalent to the center of the screen.
	static get_y = function() {
		return y;
	};
	
	/// @description	Gets the base width of the camera, prior any scaling. See set_size() to set width or height.
	/// @returns {real}
	static get_width = function()
	{
		return width;
	};
	
	/// @description	Gets the base height of the camera, prior any scaling. See set_size() to set width or height.
	/// @returns {real}
	static get_height = function()
	{
		return height;
	};
	
	/// @description	Gets the scale that is applied to width*height to determine the current window size.
	/// @returns {real}
	static get_window_scale = function()
	{
		return window_scale;
	};
	
	/// @description	Gets the scale that is applied to the application surface to give more resolution to sub-pixels.
	///			Note: With a window scale of 1x, there is only 1 pixel on the monitor dedicated to each virtual pixel, so further divisions of that virtual pixel are not visible. Therefore, divisions of each virtual pixel, caused by pixel_scale being greater than 1, are only visible when window_scale is greater than 1.
	/// @returns {real}
	static get_pixel_scale = function()
	{
		return pixel_scale;
	};
	
	/// @description	Sets the base width and height of the camera.
	/// @param {real}	[_width=320]		The width of the display in pixels. Recomended to be a division of the width of your desired resolution, such as 1920/6=320, to suit 1920x1080 monitor resolution.
	/// @param {real}	[_height=180]		The height of the display in pixels. Recomended to be a division of the height of your desired resolution, such as 1080/6=180, to suit 1920x1080 monitor resolution.
	/// @returns		N/A
	static set_size = function(_width=320, _height=180)
	{
		width	= _width;
		height	= _height;
		
		reset_window();
	};
	
	/// @description	Sets the scale that is applied to width*height to determine the current window size, and then resets the window to that scale.
	/// @param {real}	[_window_scale=4]	The scale to draw the display at when in windowed mode, as a multiple of width and height.
	/// @returns		N/A
	static set_window_scale = function(_window_scale=4)
	{
		window_scale	= _window_scale;
		
		reset_window();
	};
	
	/// @description	Sets the scale that is applied to the application surface to give more resolution to sub-pixels.
	///			Note: With a window scale of 1x, there is only 1 pixel on the monitor dedicated to each virtual pixel, so further divisions of that virtual pixel are not visible. Therefore, divisions of each virtual pixel, caused by pixel_scale being greater than 1, are only visible when window_scale is greater than 1.
	/// @param {real}	[_pixel_scale=1]	The width and height of each pixel, in subpixels. _window_scale needs to be >= _pixel_scale for all sub-pixels to be visible.
	///						Examples: Pass `1` for true-to-size pixels, `2` for pixels with a resolution of 2x2 subpixels, or pass the same value as _window_scale to match the subpixel size to the actual pixel size on the display.
	/// @returns		N/A
	static set_pixel_scale = function(_pixel_scale=4)
	{
		pixel_scale	= _pixel_scale;
		
		reset_window();
	};
	
	/// @description	Gets the window, application surface, and GUi to match the internal width, height, pixel_scale and window_scale:
	///			GUI and window of 1x size matches width*height. Window is scaled to window_scale. Application surface is scaled by pixel_scale, to give greater resolution to pixels (when at a displayable window_scale).
	/// @returns		N/A
	static reset_window = function()
	{
		surface_resize(application_surface, width * pixel_scale, height * pixel_scale);
		display_set_gui_size(width, height);
		window_set_size(width * window_scale, height * window_scale);
		window_center();
	};
	
	
	
		  /////////////
		 // utility //
		/////////////
	
	
	
	/// @description	Gets the current angle of the camera, in degrees. See .rotate_to() or .rotate_by() to set the angle.
	/// @returns {real}
	static get_angle = function()
	{
		return angle;
	};
	
	/// @description	Gets the current zoom (magnification) of the camera, in multiples of length along each axis. See .zoom_to() or .zoom_by() to set the zoom.
	/// @returns {real}
	static get_zoom = function()
	{
		return zoom;
	};
	
	/// @description	Sets the view and id for this camera.
	/// @param {real}	[_view=0]	View number [0..7].
	/// @returns		N/A
	static set_view = function(_view=0)
	{
		view	= _view;
		id	= view_camera[view];
	};
	
	/// @description	Returns this camera's x position in the world.
	/// @returns {real}	camera x.
	static view_x = function()
	{
		return x - (view_width()/2);
	};
	
	/// @description	Returns this camera's y position in the world.
	/// @returns {real}	camera y.
	static view_y = function()
	{
		return y - (view_height()/2);
	};
	
	/// @description	Returns this camera's width scaled by zoom.
	/// @returns {real}	width scaled by zoom.
	static view_width = function()
	{
		return width/zoom;
	};
	
	/// @description	Returns this camera's height scaled by zoom.
	/// @returns {real}	height scaled by zoom.
	static view_height = function()
	{
		return height/zoom;
	};
	
	/// @description	Returns this camera's previous x position in the world.
	/// @returns {real}	camera x previous.
	static view_x_previous = function()
	{
		return previous.x - (view_width_previous()/2);
	};
	
	/// @description	Returns this camera's previous y position in the world.
	/// @returns {real}	camera y previous.
	static view_y_previous = function()
	{
		return previous.y - (view_height_previous()/2);
	};
	
	/// @description	Returns this camera's width scaled by previous zoom.
	/// @returns {real}	width scaled by previous zoom.
	static view_width_previous = function()
	{
		return width / previous.zoom;
	};
	
	/// @description	Returns this camera's height scaled by previous zoom.
	/// @returns {real}	height scaled by previous zoom.
	static view_height_previous = function()
	{
		return height / previous.zoom;
	};
	
	/// @description	Returns if debug mode is active (true) or not (false).
	/// @returns {bool}	Returns if debug mode is active (true) or not (false).
	static is_debugging = function() {
		return debug.active;
	};
	
	/// @description	Activates or deactivates debug mode. When debug mode is active, the debug display is drawn to the screen.
	/// @param {bool}	[_is_debugging]		Whether to turn debug mode on (true) or off (false). Toggles on/off by default.
	/// @returns		N/A
	static set_debugging = function(_is_debugging=!debug.active) {
		debug.active = _is_debugging;
	};
	
	/// @description	Finds the x position of the mouse on the GUI, rounded to the nearest pixel. Useful for drawing a mouse cursor to the GUI.
	/// @returns {real}	Returns an x position relative to the GUI.
	static find_gui_mouse_x = function() {
		return round_towards(window_mouse_get_x() / window_scale, -infinity);
	};
	
	/// @description	Finds the y position of the mouse on the GUI, rounded to the nearest pixel. Useful for drawing a mouse cursor to the GUI.
	/// @returns {real}	Returns an y position relative to the GUI.
	static find_gui_mouse_y = function() {
		return round_towards(window_mouse_get_y() / window_scale, -infinity);
	};
	
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