// feather ignore all



/// @function			ExampleRacer() : Example() constructor
/// @description		A racer example for a basic top-down racing game, showcasing camera rotation and shake.
/// @returns {struct.Example}
function ExampleRacer() : Example() constructor
{
	// config
	
	name	= "Racer Example";
	ui_text	= "W / up: Accelerate\nS / down: Decelerate\nA / left: turn left\nD / right: turn right";
	
	racer	= undefined;		// racer object. See .create()
	
	
	
	  /////////////
	 // methods //
	/////////////
	
	
	
		  ////////////
		 // events //
		////////////
	
	
	
	/// @description	The create event, for setting up the camera and example.
	/// @returns		N/A
	create	= function() {
		racer ??= instance_create_depth(0, 0, 0, objCar);
		
		// camera init
		global.camera.set_interpolation(1/4, 1/4, 1/16);
		
		global.camera.set_position_anchor(racer);
		global.camera.set_angle_anchor(racer);
		
		global.camera.set_start_values(racer.x, racer.y);
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
		
		racer = undefined;
		
		global.camera.set_position_anchor();	// unset position anchor, as racer no longer exists
		global.camera.set_angle_anchor();	// unset angle anchor, as racer no longer exists
		global.camera.set_zoom_anchor();	// unset zoom anchor, as rocer no longer exists
	};
	
	/// @description	The step event, for code that needs to run every frame.
	/// @returns		N/A
	step	= function() {
		
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