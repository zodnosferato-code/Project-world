# World & Entity Management

## Coordinate system

- Continuous 2D plane with floating-point XY coordinates (no grid, no hexagon).
- Each entity stores `pos_x`, `pos_y` as floats.
- Movement is velocity-based: each simulation tick the zone thread computes the new position from velocity × delta time.
- The server validates every resulting position: speed limits, collision, zone bounds. Invalid moves are rejected or clamped.

## Collision

- No full physics engine. Static world geometry (walls, rocks, props) is stored as simple shapes: **AABB boxes** or circles.
- On each move the server checks whether the new position intersects any static shape.
- If it does: the move is rejected or the entity is stopped at the boundary.
- Dynamic collision between entities (players, NPCs) is handled by the game logic layer (e.g. combat range checks), not by a physics solver.

## Zones

- The world is split into **zones**; each zone runs on its own simulation thread.
- One thread per zone = deterministic processing order, no locks between actions inside the same zone.
- Players and NPCs belong to exactly one zone at a time.
- Cross-zone movement: the entity is handed off between zone threads via a queue; from that point the destination zone's thread owns it.
- Interest management: state updates are sent only to players within visibility range, not to the whole server.

## Entities & actors

- An **entity** is anything with a position in the world: players, NPCs, (later) projectiles or interactive objects.
- Each entity lives in its zone's in-memory list and carries: position, velocity, and optionally an AI state.
- **Players:** controlled by client intents; the server validates and applies.
- **NPCs:** driven by simple **state machines** or **behavior trees**, running on the zone thread alongside player actions.
- Static world geometry is loaded once into memory at zone startup — it is not written to the database per tick.

## Persistence

- World geometry: static, in-memory only.
- Character state (position, inventory, level, gold): loaded on login, saved on logout and periodically.
- Writes go through the HikariCP pool, batched or async where latency matters.

## Interaction model

- Player-to-player and player-to-NPC interactions (attack, trade, chat) are resolved on the zone thread.
- Results are broadcast to entities within visibility range.
- The client renders other entities purely from server updates; only the player's own movement is predicted locally.
