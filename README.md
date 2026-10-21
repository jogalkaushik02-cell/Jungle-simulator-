# Stillwild

A peaceful realistic-style 3D nature game made with **Godot 4.6**.
Explore a small bush airstrip, walk or drive through a jungle with a river,
and climb into snowy mountains. Playable on Android phones with a
PUBG / Free Fire style touch interface.

## What's inside

- **Terrain:** procedural 400 m x 400 m island. South = airstrip plateau,
  middle = jungle + carved river, north = snowy mountains. Slope- and
  height-blended ground shader using real scanned textures.
- **Hiker:** animated third/first-person character with footstep sounds.
- **Jeep** and **ATV quad:** drivable, wheels spin, engine sound.
- **Helicopter:** real physics model (rotor spin-up, collective, gravity,
  drag, tilt) with dedicated fly controls.
- **Touch HUD:** left virtual joystick, right drag-look, round CAM / USE /
  JUMP / UP / DN buttons.
- **Ambience:** wind, forest, river and bird sounds that fade by location.

## Controls

Phone (landscape): left joystick = move/drive/fly, drag right side = look,
CAM = view, USE = enter/exit vehicle, JUMP = jump, UP/DN = helicopter climb.

Desktop: WASD/arrows to move, Space jump, E enter/exit, C camera, R/F heli lift.

## Getting the APK (no PC needed)

This repo ships two GitHub Actions workflows. The game uses the first one.

**Build the APK in the cloud:**

1. Push to `main` (or open the **Actions** tab and run
   **Build Stillwild APK** manually).
2. Open the finished run.
3. Download the **Stillwild-APK** artifact.
4. Copy `Stillwild.apk` to your phone and tap to install.

## Running in the Godot editor

Open `project.godot` in Godot 4.6 and press Play.
See `OPEN_IN_GODOT.txt` for details.

## Also in this repo

- `UNITY_LICENSE.md` — how to generate a free Unity Personal `.ulf`
  license with the **Acquire Unity License** workflow.

## Assets

Free / CC0 models and textures (Grab3D, Poly Haven, Kenney, poly.pizza) and
CC0 sounds. See `CREDITS.txt`.
