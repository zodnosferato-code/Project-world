# MVP: Minimal Login + Movement (Terminal Client)

Goal: prove the client-server loop works with the thinnest possible client. No 3D graphics — a terminal client is enough. The thing being proven is communication and authoritative movement.

## Scope

- One Netty server, one zone, one thread.
- One proto message pair: `MoveIntent` (client → server) and `PositionUpdate` (server → client).
- One player, one fixed arena (e.g. 10×10 units) with AABB collision.
- Terminal client: connects over TCP, sends move intents, prints received positions.
- No persistence, no second player, no broadcast, no chunks yet.

## Step 1: Proto

From `protocol/game_messages proto`, keep only:

- `MoveIntent` — player id, direction or target, timestamp.
- `PositionUpdate` — player id, x, y, timestamp.

Generate Java classes with `protoc` (Java plugin) into `server/src/main/java/.../proto/`.

## Step 2: Server skeleton

- `Main.java` boots a Netty `ServerBootstrap` with the existing pipeline: `LengthFieldBasedFrameDecoder` → protobuf decoder → `GameServerHandler`.
- Outbound: protobuf encoder → length-field prepender.
- The handler does no game logic: it maps the channel to a session and hands the message to the zone executor.
- One zone, one thread. The zone thread validates the move (speed limit, AABB collision against arena bounds) and writes a `PositionUpdate` back to the channel.
- Player spawns at a fixed start position on connect.

## Step 3: Arena

- Fixed 10×10 unit plane. Bounds checked as simple AABB.
- No props, no NPCs, no loot. Collision = "is the new position inside the arena?"
- Invalid moves are rejected; the last valid position stands.

## Step 4: Terminal client

- Plain Java `main`: TCP connect, read lines from stdin.
- Each line (e.g. `move 1 0`) becomes a `MoveIntent` sent over the wire.
- Every received `PositionUpdate` is printed to stdout.
- This client is throwaway — it exists only to prove the loop. The Godot client will replace it later using the same proto.

## Step 5: Verify

- Run server, connect one terminal client, send several moves.
- Confirm: positions update correctly, out-of-bounds moves are rejected, the server remains the source of truth.
- Only when this loop is solid do we add: second client + broadcast, then persistence.

## Out of scope (for now)

- 3D rendering, Godot client, chunks, NPCs, loot, login/accounts, database.
- These come after the movement loop is proven.
