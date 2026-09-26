# Server Plan (Java 21)

## Why Java

- Mature, well-documented, huge ecosystem.
- Netty provides high-performance async TCP networking.
- PostgreSQL via JDBC/jOOQ for persistence.
- Protocol Buffers have first-class Java support.
- Single language for server + backend logic; no extra runtime beyond the JVM.

## Project structure (planned)

```
server/
  src/main/java/com/example/mmo/
    Main.java                 # entry point, boots Netty + world
    net/                      # Netty pipeline, handlers, session management
    session/                  # player sessions, login flow
    game/                     # authoritative game logic: movement, combat, inventory
    world/                    # zones, zone threads, cross-zone coordination
    persistence/              # PostgreSQL access (HikariCP pool, jOOQ)
    admin/                    # ops/monitoring endpoint
  src/main/resources/
    application.properties
  proto/                      # shared .proto files
```

## Network layer

- Netty `ServerBootstrap` with two event loop groups (boss + worker).
- Pipeline per channel: `LengthFieldBasedFrameDecoder` → protobuf decoder → `GameServerHandler`.
- Outbound: protobuf encoder → length-field prepender.
- Idle-state handler for heartbeat/timeout.

## Session & login

- On connect: client sends login request (username/password hash or token).
- Server validates against PostgreSQL, loads character, assigns to a starting zone.
- On disconnect: persist character state, remove from zone, broadcast logout.

## Action handling (intent → validate → broadcast)

The core principle: the client sends *intent*, the server decides what happens, and only the resulting *state* is broadcast. The client never tells the server the outcome.

1. **Netty I/O thread** receives the framed protobuf message. The `GameServerHandler` does no game logic — it only maps the channel to a player session and hands the message off.
2. **Handoff to zone executor.** The handler submits the action to the executor of the zone the player belongs to. This guarantees the Netty I/O threads never block on game logic, and every action for a given zone is processed in a single, deterministic order.
3. **Zone thread validates and applies.** Speed checks, collision, zone bounds, combat resolution, inventory rules — all run here, sequentially. Because one thread owns the zone, there are no locks between actions in the same zone.
4. **Broadcast.** The resulting state change is sent only to players within visibility range (interest management), not to the whole server.

### Client-side prediction

- The client predicts its own movement locally to hide latency.
- The server is always authoritative: on mismatch, the server's correction overwrites the client's prediction.
- Prediction applies to the player's own actions only; other entities are rendered purely from server updates.

## Game logic (authoritative)

- Client sends intents (move, attack, use item); server validates and applies.
- Movement: server checks speed, collision, and zone bounds; broadcasts position updates to nearby players.
- Combat: server rolls damage, applies to target, broadcasts results.
- Inventory: server is source of truth; changes are persisted and broadcast.
- NPC AI: simple state machines or behavior trees per NPC; runs on the zone thread.

## World / zones

- World split into zones; each zone has one simulation thread for determinism.
- Players and NPCs belong to exactly one zone at a time.
- Cross-zone movement: hand off entity between zone threads with a queue.
- Interest management: only send updates to players within visibility range.

## Persistence

- PostgreSQL schema: accounts, characters, inventory, world state.
- HikariCP connection pool; writes batched or async.
- Load character on login, save on logout and periodically.

## Admin

- Lightweight HTTP endpoint (e.g. Javalin or embedded Netty) exposing: player count, TPS, zone stats, recent errors.

## Scalability path

- v1: single JVM, all zones in-process.
- Later: multiple JVM processes, one per zone group, behind a small Java gateway. Still one language.
