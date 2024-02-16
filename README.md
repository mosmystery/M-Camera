# M-Camera
A flexible camera system for GMS 2.3+, focused on quick setup and ease of use.
This has been designed with single-view pixel art games in mind, however it may well work (or grow to work) beyond those contexts.
Special thanks to Pixelated Pope and Shaun Spalding for their camera tutorials on YouTube.
### Features:
- Optionally self-managed host object, to streamline setup.
- Camera movement, panning, rotation and zoom.
- Set interpolation values for smooth translation.
- Set a target object to follow.
- Set rotation and zoom anchor points.
- Define window scale and pixel scale, for pixel-perfect pixel art or visible subpixels.
- Set a boundary rectangle to clamp the camera within a room or rectangle.
## Quickstart Guide
1. Download the latest release of the M-Camera package.
2. Import it into your GMS 2.3+ project via "Tools"->"Import Local Package".
3. In the create event of the first room, create and set up the camera:
```gml
global.camera = new MCamera(320, 180, 4, 1);

// optionally define other camera settings here
global.camera.set_target(objPlayer);
global.camera.set_interpolation_values(1/8, 1/4, 1/16);
```
4. During the game, translate the camera or access any other methods like so:
```gml
// example settings
global.camera.set_start_values(room_width/2, room_height/2, 0, 1);
global.camera.set_interpolation_values(1/8, 1/4, 1);
global.camera.set_debug_mode(true);

// example translation
global.camera.move_to(x, y);
global.camera.rotate_by(90);
global.camera.zoom_by(2);
global.camera.reset();

// example anchoring
global.camera.set_target(undefined);
global.camera.set_rotation_anchor({x: room_width/2, y: room_height/2});
global.camera.set_zoom_anchor(objMouse);
global.camera.set_position_boundary(0, 0, room_width, room_height);
global.camera.unset_position_boundary();

// see the full list of methods and their documentation in MCamera.gml
```
## End
Thank you for your interest in this project. I hope it serves you well.
### Feature requests, bug reports, help:
- Open an issue or ping me `@__mos` in the GameMaker Discord or `@mos_mystery` on Twitter.