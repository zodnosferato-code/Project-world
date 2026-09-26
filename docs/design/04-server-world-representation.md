# World Representation on the Server

## Three layers

The server-side world is represented in three layers:

1. **Chunk geometry** — static, read-only collision and navigation data.
2. **Entity list** — dynamic content: players, NPCs, loot, farmable resources.
3. **Persistence** — player state only (position, inventory, level). The world itself is static and never written.

## Chunks (static geometry)

- Each chunk is a static, in-memory object loaded on the zone thread at startup.
- Geometry includes: AABB collision boxes, heightmap, navigation mesh.
- Chunks are immutable at runtime — no synchronization needed between zone threads for geometry.
- The world is split into chunks per zone; each zone loads its chunk group.
- Neighboring chunks have an overlapping edge band so geometry transitions smoothly across chunk boundaries.
- Chunks are loaded and unloaded by the zone thread as players move between zones.

## Entities (dynamic content)

- Dynamic content lives in a per-zone entity list managed by the zone thread.
- Every entity has a position, velocity, and optionally an AI state.
- Entity types: players, NPCs, loot drops, farmable resources (gold veins, ore nodes, herb patches).
- Interactions (pickup, attack, trade) are resolved on the zone thread and broadcast to entities within visibility range.

## Farmable resources (gold, ore, herbs)

- A resource node is an entity: position, remaining quantity, respawn timer.
- The player sends a **PickupIntent**; the zone thread validates distance and quantity, deducts the amount, and removes or respawns the node.
- Two spawn strategies:
  - **Fixed spawn points** — you mark locations in the layout; resources appear periodically. Deterministic, easy to balance.
  - **Continuous spawn** — the zone thread places new nodes randomly within the chunk area. Harder to balance, more organic feel.
- Loot is an inventory entry attached to the player entity — part of the existing persistence model.

## Persistence

- Only player state is persisted: position, inventory, level, gold.
- Loaded on login, saved on logout and periodically via the HikariCP pool.
- The world geometry and static props are never written — they are loaded once from chunk files.

## Client relationship

- The server is always the source of truth; the client sends intents only.
- The client renders other entities purely from server updates; only the player's own movement is predicted locally.
