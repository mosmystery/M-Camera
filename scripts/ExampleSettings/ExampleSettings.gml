// feather ignore all



/// @function			ExampleSettings() : Example() constructor
/// @description		A "settings" screen, showcasing camera changes reflected in the application surface.
/// @returns {struct.Example}
function ExampleSettings() : Example() constructor
{
	// config
	
	name		= "Settings Example";
	ui_text		= "Mouse L: click";
	
	sections	= [];
	num_sections	= 0;
	
	time		= 0;		// timer for drawing moving shapes, to showcase pixel_scale
	loop_frame	= 600;		// how many frames afterwhich to loop time
	
	match_scales	= false;	// whether to match Subpixels per Pixel to the Window Scale (true) or not (false)
	
	
	
	  /////////////
	 // methods //
	/////////////
	
	
	
		  ////////////
		 // events //
		////////////
	
	
	
	/// @description	The create event, for setting up the camera and example.
	/// @returns		N/A
	create	= function() {
		// sections
		var _line_width		= 96;
		var _line_height	= 10;
		
		var _x			= -(_line_width/2);
		
		sections		= [
			new Section(_x, -(_line_height * 7), _line_width, _line_height, "Base Resolution", [
				new Button("240x180 (4:3)",  function(){global.camera.set_size(240, 180)}, function(){return global.camera.get_width() == 240}),
				new Button("320x180 (16:9)", function(){global.camera.set_size(320, 180)}, function(){return global.camera.get_width() == 320}),
				new Button("426x180 (21:9)", function(){global.camera.set_size(426, 180)}, function(){return global.camera.get_width() == 426})
			]),
			new Section(_x, -(_line_height * 2), _line_width, _line_height, "Window Scale", [
				new Button("1", function(){global.camera.set_window_scale(1); if (match_scales){global.camera.set_pixel_scale(1)}}, function(){return global.camera.get_window_scale() == 1}),
				new Button("2", function(){global.camera.set_window_scale(2); if (match_scales){global.camera.set_pixel_scale(2)}}, function(){return global.camera.get_window_scale() == 2}),
				new Button("4", function(){global.camera.set_window_scale(4); if (match_scales){global.camera.set_pixel_scale(4)}}, function(){return global.camera.get_window_scale() == 4}),
				new Button("6", function(){global.camera.set_window_scale(6); if (match_scales){global.camera.set_pixel_scale(6)}}, function(){return global.camera.get_window_scale() == 6})
			]),
			new Section(_x, _line_height * 4, _line_width, _line_height, "Subpixels per Pixel", [
				new Button("1x1", function(){match_scales = false; global.camera.set_pixel_scale(1)}, function(){return global.camera.get_pixel_scale() == 1}),
				new Button("2x2", function(){match_scales = false; global.camera.set_pixel_scale(2)}, function(){return global.camera.get_pixel_scale() == 2}),
				new Button("3x3", function(){match_scales = false; global.camera.set_pixel_scale(3)}, function(){return global.camera.get_pixel_scale() == 3}),
				new Button("Window Scale", function(){match_scales = true; global.camera.set_pixel_scale(global.camera.get_window_scale())}, function(){return global.camera.get_pixel_scale() == global.camera.get_window_scale()})
			])
		];
		
		num_sections	= array_length(sections);
	};
	
	/// @description	The destroy event, for cleaning up the example.
	/// @returns		N/A
	destroy	= function() {
		// sections
		for (var i = 0; i < num_sections; i++)
		{
			sections[i].destroy();
			
			delete sections[i];
			
			sections[i] = undefined;
		}
		
		sections	= [];
		num_sections	= 0;
	};
	
	/// @description	The step event, for code that needs to run every frame.
	/// @returns		N/A
	step	= function() {
		time = (time + 1) % loop_frame;
		
		// sections
		for (var i = 0; i < num_sections; i++)
		{
			sections[i].step();
		}
	};
	
	/// @description	The draw event, for drawing the example.
	/// @returns		N/A
	draw	= function() {
		var _t	= time / loop_frame; // time, normalised
		
		// shapes for demonstrating pixel_scale		
		var _demo_center_x	= global.camera.get_x() + 87;
		var _demo_center_y	= global.camera.get_y();
		
		// circles
		draw_set_colour(c_dkgrey);
		
		for (var i = 1; i <= 10; i++)
		{
			draw_circle(_demo_center_x, (_demo_center_y - (16*5.5)) + (i * 16), i, false);
		}
		
		// scaling tile
		var _scale = 1.5 + (cos(degtorad((_t*2) * 360)) * 0.5);
		
		draw_sprite_ext(sprBlock, 0, (_demo_center_x - 3) - ((_scale-1)*4), (_demo_center_y - 43) - ((_scale-1)*4), _scale, _scale, 0, c_white, 1);
		
		// guy on tiles
		for (var i = -3; i <= 3; i++)
		{
			draw_sprite(sprBlock, 0, (_demo_center_x - 4) + (i*8), _demo_center_y + 5);
		}
		
		draw_sprite(sprGuy, 0, (_demo_center_x) + (sin(degtorad((_t*2) * 360)) * 16), _demo_center_y + 1);
		
		// car
		var _x = lengthdir_x(6, _t * 360);
		var _y = lengthdir_y(6, _t * 360);
		
		draw_sprite_ext(sprCar, 0, _x + (_demo_center_x) + 1, _y + (_demo_center_y) + 57, 1, 1, (_t * 360) + 90, c_white, 1);
	};
	
	/// @description	The draw gui event, for any drawing to the gui.
	/// @returns		N/A
	draw_gui = function() {
		// sections
		for (var i = 0; i < num_sections; i++)
		{
			sections[i].draw();
		}
		
		// cursor
		draw_sprite(sprMouse, 0, global.camera.find_gui_mouse_x(), global.camera.find_gui_mouse_y());
	};
	
	
	
		  /////////////////////
		 // UI constructors //
		/////////////////////
	
	
	
	/// @description		A section of UI settings
	/// @param {real}		_x		The x co-ordinate of the top-left of the first button, relative to the center of the gui.
	/// @param {real}		_y		The y co-ordinate of the top_left of the first button, relative to the center of the gui.
	/// @param {real}		_line_width	The max width of each button.
	/// @param {real}		_line_height	The height of each 
	/// @param {string}		_name		The name of the section.
	/// @returns {struct.Button}
	static Section = function(_x, _y, _line_width, _line_height, _name="Section", _buttons=[]) constructor {
		name		= _name;
		x		= _x;
		y		= _y;
		buttons		= _buttons;
		num_buttons	= array_length(buttons);
		
		line_width	= _line_width
		line_height	= _line_height;
		
		outline_padding	= line_height / 2;
		
		gui_center_x	= 0;	// automatically updated in .step()
		gui_center_y	= 0;
		
		static destroy = function() {
			for (var i = 0; i < num_buttons; i++)
			{
				delete buttons[i];
			
				buttons[i] = undefined;
			}
		
			buttons		= [];
			num_buttons	= 0;
		};
		
		static step = function() {
			gui_center_x	= global.camera.get_width() / 2;
			gui_center_y	= global.camera.get_height() / 2;
			
			var _view_x	= global.camera.view_x();
			var _view_y	= global.camera.view_y();
			
			// buttons
			for (var i = 0; i < num_buttons; i++)
			{
				buttons[i].step(_view_x + gui_center_x + x, _view_y + gui_center_y + y + (i*line_height), line_width, line_height);
			}
		};
		
		static draw = function() {
			var _x		= gui_center_x + x;
			var _y		= gui_center_y + y;
			
			var _x1		= _x - outline_padding;
			var _y1		= _y - outline_padding;
			var _x2		= _x + line_width + outline_padding;
			var _y2		= _y + (line_height * num_buttons) + outline_padding;
			
			// outline
			draw_set_color(c_white);
			draw_rectangle(_x1, _y1, _x2, _y2, false);
			
			draw_set_color(c_black);
			draw_rectangle(_x1 + 1, _y1 + 1, _x2 - 1, _y2 - 1, false);
			
			// heading
			var _text_width = string_width(name);
			var _text_height = string_height(name);
			
			var _reset_halign	= draw_get_halign();
			var _reset_valign	= draw_get_valign();
			
			draw_set_halign(fa_left);
			draw_set_valign(fa_bottom);
			
			draw_set_color(c_black);
			draw_rectangle(_x - 1, _y - _text_height, _x + _text_width + 1, _y, false);
			
			draw_set_color(c_white);
			draw_text(_x, _y, name);
			
			draw_set_halign(_reset_halign);
			draw_set_valign(_reset_valign);
			
			// buttons
			for (var i = 0; i < num_buttons; i++)
			{
				buttons[i].draw(_x, _y + (i*line_height), line_width, line_height);
			}
		};
	};
	
	/// @description		A UI button to click.
	/// @param {string}		_text		The text on the button.
	/// @param {function}		_fn_click	The function to call when the button is clicked.
	/// @param {function}		_fn_active	The function to check whether the button is visually active or not. For example, if the screen is currently 360x180, then that button may appear active.
	/// @returns {struct.Button}
	static Button = function(_text="Button", _fn_click=function(){}, _fn_active=function(){return true}) constructor {
		x		= 0;	// The x co-ordinate of the button. If button part of a section, then relative to its place in the section. (See .Section())
		y		= 0;	// The y co-ordinate of the button. If button part of a section, then relative to its place in the section. (See .Section())
		width		= 0;
		height		= 0;
		text		= _text;
		fn_click	= _fn_click;
		fn_active	= _fn_active;
		
		state		= 0;
		hover		= false;
		active		= false;
		
		static step = function(_x = x, _y = y, _width = width, _height = height) {
			state	= mouse_check_button(mb_left) + mouse_check_button_pressed(mb_left) - mouse_check_button_released(mb_left);	// -1 = released, 0 = none, 1 = held, 2 = pressed
			hover	= (mouse_x == clamp(mouse_x, _x, _x+(_width-1))) && (mouse_y == clamp(mouse_y, _y, _y+(_height-1)));
			active	= fn_active();
			
			if (state == 2 && hover)
			{
				fn_click();
			}
		};
		
		static draw = function(_x = x, _y = y, _width = width, _height = height) {
			var _reset_halign	= draw_get_halign();
			var _reset_valign	= draw_get_valign();
			
			var _x1		= _x;
			var _y1		= _y;
			var _x2		= _x + _width;
			var _y2		= _y + _height;
			
			draw_set_halign(fa_center);
			draw_set_valign(fa_middle);
			
			// hover rect
			if (hover)
			{
				draw_set_color(c_white);
				draw_rectangle(_x1, _y1, _x2, _y2, false);
				
				draw_set_color(c_black);
				draw_rectangle(_x1 + 1, _y1 + 1, _x2 - 1, _y2 - 1, false);
			}
			
			// text
			draw_set_color(active ? c_white : c_dkgrey);
			draw_text(_x+(_width/2), _y+(_height/2)+1, text);
			
			draw_set_halign(_reset_halign);
			draw_set_valign(_reset_valign);
		};
	};
}