# M-Camera

A flexible camera system for GameMaker, focused on quick setup and ease of use.

### Features

- Optionally self-managed host object, to streamline setup.
- Define window scale and pixel scale, for pixel-perfect pixel art or visible subpixels.
- Camera movement, panning, rotation and zoom.
- Set interpolation values for smooth translation.
- Set a target object to follow.
- Set rotation and zoom anchor points.
- Set a boundary rectangle to clamp the camera within a room or rectangle.

### Limitations

- Designed with single-view pixel art games in mind.
- No screenshake currently, however there are plans to implement it.

## Quickstart Guide

### Setting up M-Camera in your project

1. Download the latest package file (ending in `.yymps`) from the [Releases](https://github.com/mosmystery/M-Camera/releases) page.
2. Import it into your GameMaker project via "Tools"->"Import Local Package".
3. In the create event of the first room, create and set up the camera:

```gml
global.camera = new MCamera(320, 180, 4, 1);

// optionally define other camera settings here
global.camera.set_position_anchor(objPlayer);
global.camera.set_interpolation_values(1/8, 1/4, 1);
```

4. During the game, translate the camera or access any other methods like so:

```gml
// example settings
global.camera.set_start_values(room_width/2, room_height/2, 0, 1);
global.camera.set_interpolation_values(1/8, 1/4, 1);
global.camera.set_debugging(true);

// example translation
global.camera.move_to(x, y);
global.camera.rotate_by(90);
global.camera.zoom_by(2);
global.camera.reset();

// example anchoring
global.camera.set_position_anchor(objPlayer);
global.camera.set_angle_anchor({x: room_width/2, y: room_height/2});
global.camera.set_zoom_anchor(objMouse);
global.camera.set_boundary(0, 0, room_width, room_height);
global.camera.unset_boundary();

// see the full list of methods and their documentation in MCamera.gml
```

### Viewing the M-Camera example

1. Download the latest source code file from the [Releases](https://github.com/mosmystery/M-Camera/releases) page.
2. Unzip the source code file and open `m_camera.yyp` in GameMaker.
3. Run the build.

## Credits

- Created by [mos_mystery](https://twitter.com/mos_mystery).
- Originally submitted to [TabularElf](https://twitter.com/TabularElf)'s [GameMaker Kitchen Cookbook Jam #1](https://itch.io/jam/cookbook-jam-1).
- Special thanks to [Pixelated Pope](https://www.youtube.com/@PixelatedPope) and [Shaun Spalding](https://www.youtube.com/@ShaunJS) for their camera tutorials.
- Thank *you*!

## Help, Feature Requests, Bug Reports

- Ping `@__mos` in the [GameMaker Kitchen](https://discord.gg/8krYCqr) or [GameMaker](https://discord.com/invite/gamemaker) Discords.
- Ping or DM [mos_mystery](https://twitter.com/mos_mystery) on Twitter.
- [Open an issue](https://github.com/mosmystery/M-Camera/issues) on GitHub.