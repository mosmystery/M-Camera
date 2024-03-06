// feather ignore all



/// @function		game_init()
/// @description	This function initialises the game. It is ran in the creation code of rmExample
/// @returns		N/A
function game_init()
{
	// camera init
	
	global.camera	= new MCamera(320, 180, 4, 1);	// Create MCamera. View MCamera() for parameter descriptions. Try setting different parameters.
	
	global.camera.set_debugging(true);		// Turn debug mode on. Try setting to false or removing line.
	
	// example init
	
	global.loader	= new ExampleLoader();		// Create ExampleLoader, a console for installing and loading Examples
	
	global.loader.install(new ExampleEditor());	// Install example editor.
}