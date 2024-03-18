// feather ignore all



/// @function			ExampleSettings() : Example() constructor
/// @description		A "settings" screen, showcasing camera changes reflected in the application surface.
/// @returns {struct.Example}
function ExampleSettings() : Example() constructor
{
	// config
	
	name		= "Settings Example";
	ui_text		= "Mouse L: click";
	
	buttons		= [];
	num_buttons	= 0;
	
	
	
	  /////////////
	 // methods //
	/////////////
	
	
	
		  ////////////
		 // events //
		////////////
	
	
	
	/// @description	The create event, for setting up the camera and example.
	/// @returns		N/A
	create	= function() {
		array_push(buttons, new Button(64, 64, 64, 16, "426x180", function(){global.camera.set_size(426, 180)}));
		
		num_buttons = array_length(buttons);
	};
	
	/// @description	The destroy event, for cleaning up the example.
	/// @returns		N/A
	destroy	= function() {
		for (var i = 0; i < num_buttons; i++)
		{
			delete buttons[i];
			
			buttons[i] = undefined;
		}
		
		buttons	= [];
	};
	
	/// @description	The step event, for code that needs to run every frame.
	/// @returns		N/A
	step	= function() {
		for (var i = 0; i < num_buttons; i++)
		{
			buttons[i].step();
		}
	};
	
	/// @description	The draw event, for drawing the example.
	/// @returns		N/A
	draw	= function() {
		for (var i = 0; i < num_buttons; i++)
		{
			buttons[i].draw();
		}
	};
	
	/// @description	The draw gui event, for any drawing to the gui.
	/// @returns		N/A
	draw_gui = function() {
		draw_sprite(sprMouse, 0, global.camera.find_gui_mouse_x(), global.camera.find_gui_mouse_y());
	};
	
	
	
		  ////////////////////////
		 // supporting methods //
		////////////////////////
	
	
	
	/// @description		A UI button to click.
	/// @param {real}		_x		The x co-ordinate of the button.
	/// @param {real}		_y		The y co-ordinate of the button.
	/// @param {real}		_width		The width of the button.
	/// @param {real}		_height		The height of the button.
	/// @param {string}		_text		The text on the button.
	/// @param {function}		_fn_click	The function to call when the button is clicked.
	/// @returns {struct.Button}
	static Button = function(_x, _y, _width, _height, _text="Click me", _fn_click=function(){}) constructor {
		x		= _x;
		y		= _y;
		width		= _width;
		height		= _height;
		text		= _text;
		fn_click	= _fn_click;
		
		state		= 0;
		hover		= false;
		
		static step = function() {
			state	= mouse_check_button(mb_left) + mouse_check_button_pressed(mb_left) - mouse_check_button_released(mb_left);	// -1 = released, 0 = none, 1 = held, 2 = pressed
			hover	= (mouse_x == clamp(mouse_x, x, x+width)) && (mouse_y == clamp(mouse_y, y, y+height));
			
			if (state == 2 && hover)
			{
				fn_click();
			}
		};
		
		static draw = function() {
			var _reset_halign	= draw_get_halign();
			var _reset_valign	= draw_get_valign();
			var _y_offset		= hover ? real(state>=1)*2 : 0;
			
			draw_set_halign(fa_center);
			draw_set_valign(fa_middle);
			
			// hole
			draw_set_color(c_grey);
			draw_rectangle(x, y+2, x+width, y+height+2, true);
			
			// button rect
			draw_set_color(hover ? $CCCCCC : c_dkgrey);
			draw_rectangle(x, y+_y_offset, x+width, y+height+_y_offset, false);
			
			// button outline
			draw_set_color($CCCCCC);
			draw_rectangle(x, y+_y_offset, x+width, y+height+_y_offset, true);
			
			// text
			draw_set_color(hover ? c_black : c_grey);
			draw_text(x+(width/2), y+(height/2)+_y_offset, text);
			
			draw_set_halign(_reset_halign);
			draw_set_valign(_reset_valign);
		};
	};
}