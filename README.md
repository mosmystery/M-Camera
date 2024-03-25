# M-Camera

A flexible camera system for GameMaker, focused on quick setup and ease of use.

### Features

- Optionally self-managed host object, to streamline setup.
- Define window scale and pixel scale, for pixel-perfect pixel art or visible subpixels.
- Camera movement, panning, rotation and zoom, with custom interpolation values and functions for smooth translation.
- Follow a position anchor, rotate around an angle anchor, or zoom towards a zoom anchor.
- Set a boundary rectangle to clamp the camera within a rectangle, such as the current room.
- Shake the camera by position, angle, and/or zoom, around/towards anchor points, with arcade-style jitter or realistic brownian motion.

### Limitations

- Designed with single-view games in mind.

## Quickstart Guide

### Setting up M-Camera in your project

1. Download the latest package file (ending in `.yymps`) from the [Releases](https://github.com/mosmystery/M-Camera/releases) page.
2. Import it into your GameMaker project via "Tools"->"Import Local Package".
3. In the create event of the first room, create and set up the camera:

```gml
global.camera = new MCamera(320, 180, 4, 1);

// optionally define other camera settings here
global.camera.set_position_anchor(objPlayer);
global.camera.set_interpolation(1/8, 1/4, 1);
```

4. During the game, translate the camera or access any other methods like so:

```gml
// example settings
global.camera.set_start_values(room_width/2, room_height/2, 0, 1);
global.camera.set_interpolation(1/8, 1/4, 1);
global.camera.set_debugging(true);
global.camera.set_shake_limits(4, 22.5, 2);
global.camera.set_size(320, 180);
global.camera.set_window_scale(4);
global.camera.set_pixel_scale(1);

// example translation
global.camera.move_to(x, y);
global.camera.rotate_by(90);
global.camera.zoom_by(2);
global.camera.reset();
global.camera.shake_to(0.5);

// example anchoring
global.camera.set_position_anchor(objPlayer);
global.camera.set_angle_anchor({x: room_width/2, y: room_height/2});
global.camera.set_zoom_anchor(objMouse);
global.camera.set_boundary(0, 0, room_width, room_height);
global.camera.unset_boundary();

// see the full list of methods and their documentation in MCamera.gml
```

### Viewing the M-Camera example

For the latest released Windows executable of the M-Camera example demo, download and unzip the latest `m_camera_demo` zip file from the [Releases](https://github.com/mosmystery/M-Camera/releases) page.

## Credits

- Created by [mos_mystery](https://twitter.com/mos_mystery).
- Originally submitted to [TabularElf](https://twitter.com/TabularElf)'s [GameMaker Kitchen Cookbook Jam #1](https://itch.io/jam/cookbook-jam-1).
- Special thanks to [Pixelated Pope](https://www.youtube.com/@PixelatedPope) and [Shaun Spalding](https://www.youtube.com/@ShaunJS) for their camera tutorials.
- Thank *you*!

## Help, Feature Requests, Bug Reports

- Ping `@__mos` in the [GameMaker Kitchen](https://discord.gg/8krYCqr) or [GameMaker](https://discord.com/invite/gamemaker) Discords.
- Ping or DM [mos_mystery](https://twitter.com/mos_mystery) on Twitter.
- [Open an issue](https://github.com/mosmystery/M-Camera/issues) on GitHub.