// feather ignore all



/// @function				ExampleLoader() constructor
/// @description			A loader to manage loading and unloading of examples. Automatically creates a host object for running of event code. Useage:
///					1. Create an instance of this loader, such as with `global.loader = new ExampleLoader();`. (game_init() already does this.)
///					2. Create an Example. See Example() for creating examples that are compatable with this loader. See ExampleEditor() for an example of how to do this.
///					3. Install the example into the loader such as with .install(new ExampleName()). See game_init() for where to do this.
///					4. load the first and consequent examples with .load_next(). (game_init() already does this.)
/// @returns {struct.ExampleLoader}
function ExampleLoader() constructor
{
	// config
	
	host		= undefined;	// See .create()
	
	example		= undefined;	// currently loaded example
	
	examples	= [];		// installed examples
	index		= -1;		// index of currently installed example
	num_examples	= 0;		// number of installed examples. Increments when an example is installed
	
	show_help_text	= true;		// Whether to display help text on gui (true) or not (false)
	
	
	
	  /////////////
	 // methods //
	/////////////
	
	
	
		  ////////////
		 // events //
		////////////
	
	
	
	/// @description	The create event, for ExampleLoader itself. Sets up the loader by creating a host object. 
	/// @returns		N/A
	static create = function() {
		host		??= instance_create_depth(0, 0, 0, objExampleLoader);
		host.loader	= self;
	};
	
	/// @description	The destroy event, for ExampleLoader itself. Cleans up the loader and destroys the host object.
	/// @returns		N/A
	static destroy = function() {
		unload();
		
		for (i = 0; i < num_examples; i++)
		{
			examples[i].destroy();
			
			delete examples[i];
			
			examples[i] = undefined;
		}
		
		examples = undefined;
		
		if (host != undefined)
		{
			instance_destroy(host, false);
			
			host = undefined;
		}
	};
	
	/// @description	The step event. Steps through the currently loaded example and loads the next example on vk_enter keypress.
	/// @returns		N/A
	static step = function() {
		// controls
		
		if (keyboard_check_pressed(vk_enter))
		{
			load_next();				// load next example
		}
		
		if (keyboard_check_pressed(vk_tab))
		{
			global.camera.set_debugging();		// toggle camera debugging
		}
		
		if (keyboard_check_pressed(vk_f1))
		{
			show_help_text = !show_help_text;	// toggle help text
		}
		
		// example
		
		if (example == undefined)
		{
			return;
		}
		
		example.step();
	};
	
	/// @description	The draw event. Draws the currently loaded example.
	/// @returns		N/A
	static draw = function() {
		if (example == undefined)
		{
			return;
		}
		
		example.draw();
	};
	
	/// @description	The draw event. Draws the currently loaded example's draw_gui event, and draws the ExampleLoader text to the gui.
	/// @returns		N/A
	static draw_gui = function() {
		// draw gui text
		if (show_help_text)
		{
			draw_set_font(fntSystem);
			
			var _name	= "Welcome to M-Camera.";
			var _ui_text	= "";
			var _next_name	= "... N/A. No installed examples.";
			
			if (num_examples >= 1)
			{
				var _next_index = (index+1) % num_examples;
				
				_name		= (example == undefined) ? _name	: example.name;
				_ui_text	= (example == undefined) ? _ui_text	: example.ui_text;
				_next_name	= (examples[_next_index] == undefined) ? "N/A. No installed examples." : examples[_next_index].name;
			}
			
			var _margin	= 8;
			
			// draw help text
			draw_set_colour(c_dkgrey);
			
			draw_set_valign(fa_bottom);
			draw_text(_margin, global.camera.height-_margin, "F1: toggle help\nTab: toggle debug\nEnter: load " + _next_name);
			
			draw_set_valign(fa_top);
			draw_text(_margin, _margin, "\n\n" + _ui_text);
			
			// draw name text
			draw_set_colour(c_black);
			draw_text(_margin-1, _margin+1, _name);
			
			draw_set_colour(c_white);
			draw_text_color(_margin, _margin, _name, c_purple, c_maroon, c_yellow, c_orange, 1);
		}
		
		// draw example gui
		if (example == undefined)
		{
			return;
		}
		
		example.draw_gui();
	};
	
	
	
		  ////////////////////////
		 // example management //
		////////////////////////
	
	
	
	/// @description		Installs an Example
	/// @param {struct.Example}	_example	A struct defining the example to install. See Example().
	/// @returns			N/A
	static install	= function(_example) {
		array_push(examples, _example);
		
		num_examples++;
	};
	
	/// @description	Load the next example in `examples`, relative to `index`. (Autimatically unloads the current example beforehand.)
	/// @returns		N/A
	static load_next = function() {
		if (num_examples <= 0)
		{
			return;
		}
		
		index = (index+1) % num_examples;
		
		load(examples[index]);
	};
	
	/// @description		Load an example. (Automatically unloads the current example beforehand.)
	/// @param {struct.Example}	_example	A struct defining the example to load. See Example().
	/// @returns			N/A
	static load = function(_example) {
		unload();
		
		example = _example;
		
		example.create();
	};
	
	/// @description	Unload an example.
	/// @returns		N/A
	static unload = function() {
		global.camera.reset(true, true);
		
		if (example == undefined)
		{
			return;
		}
		
		example.destroy();
		
		delete example;
		
		example = undefined;
	};
	
	
	
	  //////////
	 // init //
	//////////
	
	
	
	create();
}



/// @function			Example() constructor
/// @description		Base Example object template to use for new examples. The event methods are automatically run by ExampleLoader(). Useage:
///				1. Define a new example with `function ExampleName() : Example() constructor` and then override and add any struct members you need in it.
///					- The struct members outlined in this constructor are recognised and used by ExampleLoader(). `name` and `ui_text` are drawn to the gui, and the events are ran by ExampleLoader() when loaded.
///				2. Install the example into ExampleLoader(). See ExampleLoader().
///				3. Run the example with ExampleLoader(). See ExampleLoader().
/// @returns {struct.Example}
function Example() constructor
{
	// config
	
	name		= "WIP Example";
	ui_text		= "Controls:\nAction: key";
	
	// events
	
	/// @description	The create event, for setting up the camera and example.
	/// @returns		N/A
	create		= function() {};
	
	/// @description	The destroy event, for cleaning up the example.
	/// @returns		N/A
	destroy		= function() {};
	
	/// @description	The step event, for code that needs to run every frame.
	/// @returns		N/A
	step		= function() {};
	
	/// @description	The draw event, for drawing the example.
	/// @returns		N/A
	draw		= function() {};
	
	/// @description	The draw gui event, for any drawing to the gui.
	/// @returns		N/A
	draw_gui	= function() {};
}