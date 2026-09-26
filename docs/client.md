# Client Plan (Godot 4)

## Why Godot

- Free, open source (MIT), native Windows + Linux export.
- Built-in OpenGL renderer; 3D projects use Forward+ with GLES3 fallback.
- GDScript is Python-like, small surface area, well documented, and well supported by AI coding tools.
- Scene files (`.tscn`) and resources (`.tres`) are plain text — easy to read, diff, and generate.
- Large, active community; Asset Library for assets and addons.
- Low runtime footprint; suitable for low-spec hardware.

## Project structure (planned)

```
client/
  project.godot
  scenes/        # main menu, world, UI screens
  scripts/       # GDScript: network, game logic, UI controllers
  assets/        # models (.glb), textures, audio
  proto/         # shared .proto files + generated GDScript bindings
```

## Rendering approach

- 3D world with low-poly models (target: 2005-2010 fidelity, e.g. early WoW).
- Flat or lightly shaded materials, small textures (256-512 px), no dynamic shadows.
- Static/baked lighting only.
- Simple custom shaders where needed (e.g. water, foliage wind).
- UI built with Control nodes (CanvasLayer), resolution-independent scaling.

## Network layer (planned)

- Autoload singleton `NetworkManager`.
- Uses Godot's `StreamPeerTCP` (or a small GDExtension if raw socket control is needed).
- Connects to the Java/Netty server, sends length-prefixed protobuf messages.
- Receives and dispatches messages to game systems via signals.
- Handles reconnection with exponential backoff.

## UI (planned)

- Login/register screen.
- In-game HUD: health/mana bars, target frame, chat window, minimap.
- Inventory and character sheet windows.
- Settings menu (graphics, audio, controls).

## Non-goals for v1

- No multiplayer voice, no complex particle effects, no cinematic cameras.
