// draw level

_level_draw(global.world.level, global.world.cell_width, global.world.cell_height, 1);

// draw cell outline of cell at mouse position

var _x1 = (floor(mouse_x / global.world.cell_width) * (global.world.cell_width));
var _y1 = (floor(mouse_y / global.world.cell_height) * (global.world.cell_height));
var _x2 = _x1 + (global.world.cell_width-1);
var _y2 = _y1 + (global.world.cell_height-1);
			
draw_rectangle_colour(_x1, _y1, _x2, _y2, $CCCCCC, $CCCCCC, $CCCCCC, $CCCCCC, true);