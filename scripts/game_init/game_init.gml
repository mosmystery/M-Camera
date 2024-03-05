/// @function		game_init()
/// @description	This function initialises the game. It is ran in the creation code of Room1
/// @returns		N/A
function game_init()
{
	draw_set_font(fntSystem);
	
	// world init
	
	global.world	= {
		width		: 16,
		height		: 16,
		cell_width	: 8,
		cell_height	: 8,
		width_scaled : function() {
			return cell_width * width;
		},
		height_scaled : function() {
			return cell_height * height;
		}
	};
	
	global.world.level = level_create(global.world.width, global.world.height)			// create the array2d representation of the level.
	
	// create mouse controller
	
	instance_create_depth(0, 0, 0, objMouseControl);						// create objMouseControl which houses the demo code.
	
	// camera init
	
	global.camera	= new MCamera(320, 180, 4, 1);							// Create MCamera. View MCamera() for parameter descriptions. Try setting different parameters.
	
	global.camera.set_interpolation_values(1/4, 1/4, 1/4);						// See MCamera.gml for full list of methods and documentation. Try setting zoom interpolation to a fraction.
	global.camera.set_start_values(global.world.width_scaled()/2, global.world.height_scaled()/2);	// sets the camera startx and starty to the center of global.world. Also takes optional parameters for anglestart and zoomstart.
	global.camera.reset();										// resets the camera to the new start values.
	
	var _angle_anchor = {										// targets and anchors simply need to include an x and y value to work, whether that is an object or a struct (such as a Vector2).
		x : global.world.width_scaled() / 2,
		y : global.world.height_scaled() / 2,
	};
	
	global.camera.set_angle_anchor(_angle_anchor);							// ensure the camera rotates around the center of the level.
	global.camera.set_zoom_anchor(objMouseControl);							// ensure camera zooms towards and away from objMouseControl.
	global.camera.set_zoom_limits(1/16, 4);								// Sets max and min zoom limits to a reasonable expectation for level editing. Try other values or removing this line for wider default range.
	
	var _border	= 1024;
	
	global.camera.set_boundary(-_border, -_border, global.world.width_scaled()+_border, global.world.height_scaled()+_border);	// sets a boundary for the camera. Try .set_debug_mode(true) to see it, or try removing this line or calling .unset_boundary() to remove it.
	
	global.camera.set_debugging(true);								// Turn debug mode on. Try setting to false or removing line.
	
	global.camera.set_shake_limits(4, 22.5, 2);							// Define the shake limits. Try different settings! Try 0 to turn off a parameter.
}