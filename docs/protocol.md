# Shared Protocol (Protocol Buffers)

## Principle

One `.proto` file is the single source of truth for client-server communication. Both the Java server and the Godot client consume generated code from it.

## File

`protocol/game_messages.proto`

## Framing

- Every TCP message is a 4-byte big-endian length prefix followed by the protobuf payload.
- This allows the Netty decoder and the Godot client to split the stream into messages reliably.

## Message categories (planned)

- **Auth:** LoginRequest, LoginResponse, Logout
- **Movement:** MoveIntent, PositionUpdate, Teleport
- **Combat:** AttackIntent, DamageEvent, DeathEvent
- **Inventory:** InventorySnapshot, ItemAdd, ItemRemove, UseItemIntent
- **Chat:** ChatMessage
- **World:** ZoneInfo, EntitySpawn, EntityDespawn, EntityUpdate
- **System:** Heartbeat, ProtocolVersion

## Versioning

- Every message (or the connection handshake) carries a protocol version.
- Mismatch → server rejects the connection with a clear error; client shows an update prompt.

## Code generation

- **Server:** `protoc` with the Java plugin → classes under `server/src/main/java/.../proto/`.
- **Client:** `protoc` with a GDScript plugin (or a small custom codegen step) → GDScript files under `client/proto/`.
- Both sides must be regenerated from the same `.proto` on every protocol change.
