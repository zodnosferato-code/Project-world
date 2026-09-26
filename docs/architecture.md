# MMO Architecture Plan

Technology stack and architecture for the MMO project. This document covers the client and server design only — no implementation details yet.

## Overview

- **Client:** Godot 4 (GDScript), cross-platform (Windows + Linux), OpenGL rendering, low-spec 3D targeting ~2005-2010 visual fidelity
- **Server:** Java 21, Netty (TCP), PostgreSQL
- **Shared protocol:** Protocol Buffers (`.proto` files generate code for both Java and GDScript)
- **Goal:** minimize the number of languages and tools — one client engine, one server language, one database

## Client (Godot 4)

### Layers

1. **Render layer** — Godot's built-in 3D renderer (Forward+), OpenGL under the hood. Simple low-poly models, flat colors, small textures, static lighting. No dynamic shadows or post-processing. Target: runs on a 2-4 core laptop without a dedicated GPU.
2. **Network layer** — autoload singleton managing the TCP connection to the server. Encodes/decodes Protocol Buffer messages. Handles connect, disconnect, reconnect, and heartbeat.
3. **Game logic** — player movement, animation, combat, inventory. GDScript.
4. **UI layer** — Godot Control nodes: chat, inventory window, character sheet, login screen.
5. **Audio** — built-in AudioServer.

### Communication with the server

- Persistent TCP connection per client (Netty on the server side).
- All messages are Protocol Buffer binary payloads framed with a 4-byte length prefix.
- Message types: login, logout, movement, chat, combat actions, inventory changes, world state updates.
- Server is authoritative: the client sends *intent* (e.g. "move to X"), the server validates and broadcasts the resulting *state*.
- Client-side prediction for movement to hide latency; server corrects on mismatch.
- Heartbeat every 30 seconds; idle timeout on the server.

### Performance targets

- 2D-style 3D: low polygon counts, no per-pixel lighting, baked lightmaps only.
- Cap draw calls; use simple shaders.
- Designed to run at 60 FPS on integrated graphics.

## Server (Java 21)

### Layers

1. **Network layer** — Netty event loop, one thread group for accept, one for I/O. Each connected client gets a `Channel` with a pipeline: length-frame decoder → protobuf decoder → handler.
2. **Session layer** — maps channels to player sessions (account, character, zone). Handles login flow and disconnection cleanup.
3. **Game logic layer** — authoritative simulation: movement validation, combat resolution, inventory, NPC AI (simple state machines / behavior trees).
4. **World layer** — zone management. The world is split into zones; each zone runs on its own thread (or a small pool). Players are assigned to a zone; cross-zone movement is coordinated.
5. **Persistence layer** — PostgreSQL via JDBC (or jOOQ). Characters, inventory, and world state are persisted. Writes are batched/async where possible.
6. **Admin/ops** — simple HTTP or TCP admin interface for monitoring (player count, TPS, errors).

### Threading model

- Netty I/O threads never block on game logic — messages are handed to a per-zone executor.
- One logical thread per zone for deterministic simulation.
- Database access via a small connection pool (HikariCP), async where latency matters.

### Scalability path

- Start with a single JVM process hosting all zones.
- Later: split zones across multiple server processes behind a lightweight gateway, still Java.

## Shared contract

- `protocol/game_messages.proto` — single source of truth for all client-server messages.
- Generated Java classes for the server; generated GDScript (via a small codegen step or manual mapping) for the client.
- Version field in every message for protocol compatibility checks.

## Out of scope (for now)

- Client-side prediction edge cases, anti-cheat hardening, production deployment, monitoring stack.
