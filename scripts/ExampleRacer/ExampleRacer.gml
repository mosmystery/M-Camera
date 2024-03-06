// feather ignore all



/// @function			ExampleRacer() : Example() constructor
/// @description		A camera example for a basic level or graphics editor, showcasing pan and zoom with the mouse.
/// @returns {struct.Example}
function ExampleRacer() : Example() constructor
{
	// config
	
	name	= "Racer Example";
	ui_text	= "W / up: Accelerate\nS / down: Decelerate\nA / left: turn left\nD / right: turn right";
	
	
	
	  /////////////
	 // methods //
	/////////////
	
	
	
		  ////////////
		 // events //
		////////////
	
	
	
	/// @description	The create event, for setting up the camera and example.
	/// @returns		N/A
	create	= function() {
		// camera init
		
		global.camera.set_position_anchor(undefined);		// unset the position anchor in case a previously loaded example had it set. Normally this would be redundant in your own usage.
		global.camera.set_angle_anchor(undefined);		// ensure the camera rotates around the center of the level.
		global.camera.set_zoom_anchor(undefined);		// ensure camera zooms towards and away from objMouseControl.
		global.camera.set_zoom_limits(1/16, 4);			// Sets max and min zoom limits to a reasonable expectation for level editing. Try other values or removing this line for wider default range.
		global.camera.set_shake_limits(4, 22.5, 2);		// Define the shake limits. Try different settings! Try 0 to turn off a parameter.
		global.camera.set_interpolation_values(1/4, 1/4, 1/4);	// Try setting interpolation values to different interpolation values, such as other fractions or 1 for instant change.
		
		global.camera.unset_boundary();				// Remove the camera boundary in case it was set by a previous example. Normally this would be redundant in your own usage.
		global.camera.set_start_values(0, 0);			// sets the camera startx and starty to 0,0 in case it was set by a previous example. Normally this would be redundant in your own usage.
		global.camera.reset();					// resets the camera to the new start values.
	};
	
	/// @description	The destroy event, for cleaning up the example.
	/// @returns		N/A
	destroy	= function() {
		
	};
	
	/// @description	The step event, for code that needs to run every frame.
	/// @returns		N/A
	step	= function() {
		// get inputs
		
		var _input = {
			// controls
			accelerate	: keyboard_check_pressed(ord("W")) || keyboard_check_pressed(vk_up),
			decelerate	: keyboard_check_pressed(ord("S")) || keyboard_check_pressed(vk_down),
			turn_left	: keyboard_check_pressed(ord("A")) || keyboard_check_pressed(vk_left),
			turn_right	: keyboard_check_pressed(ord("D")) || keyboard_check_pressed(vk_right)
		};
	};
	
	/// @description	The draw event, for drawing the example.
	/// @returns		N/A
	draw	= function() {
		
	};
	
	/// @description	The draw gui event, for any drawing to the gui.
	/// @returns		N/A
	draw_gui = function() {
		
	};
	
	
	
		  ////////////////////////
		 // supporting methods //
		////////////////////////
	
	
	
	
}