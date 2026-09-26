# AGENTS.md — Instructions for AI coding agents

This file is the primary instruction set for any AI agent working on this repository.
It is read automatically by Claude Code, Cursor, Codex, and similar tools.

## Project summary

An MMO (massively multiplayer online game) in early planning/scaffolding phase.

| Layer | Technology |
| --- | --- |
| Client | Godot 4 (GDScript), OpenGL, Windows + Linux |
| Server | Java 21, Netty (TCP), PostgreSQL |
| Protocol | Protocol Buffers (shared `.proto` files) |

## Repository layout (target)

```
Project-world/
├── AGENTS.md              ← this file (agent instructions)
├── CLAUDE.md              ← symlink/copy of AGENTS.md for Claude Code
├── .cursorrules           ← Cursor-specific rules
├── README.md
├── docs/                  ← architecture and design docs (source of truth)
│   ├── architecture.md
│   ├── client.md
│   ├── server.md
│   └── protocol.md
├── protocol/              ← shared .proto files (single source of truth)
│   └── game_messages.proto
├── client/                ← Godot 4 project
│   ├── project.godot
│   ├── scenes/
│   ├── scripts/
│   ├── assets/
│   └── proto/             ← generated GDScript bindings
├── server/                ← Java 21 / Maven project
│   ├── pom.xml
│   ├── src/main/java/com/example/mmo/
│   │   ├── Main.java
│   │   ├── net/
│   │   ├── session/
│   │   ├── game/
│   │   ├── world/
│   │   ├── persistence/
│   │   └── admin/
│   ├── src/main/resources/
│   └── proto/             ← generated Java classes
└── scripts/               ← dev tooling (codegen, test helpers)
    ├── gen-proto.sh
    └── run-server.sh
```

## Hard rules (never break these)

1. **Read `docs/` before writing code.** The docs are the design source of truth. If code would contradict a doc, update the doc first (or ask).
2. **One language per layer.** GDScript in `client/`, Java in `server/`. No C#, no C++, no Rust in these trees.
3. **Server is authoritative.** The client sends *intents*; the server validates and broadcasts *state*. Never trust client-reported positions, damage, or inventory.
4. **Shared protocol only via `protocol/`.** All client-server messages live in `.proto` files. Both sides consume generated code. Never hand-write message serialization.
5. **Small, reviewable commits.** One logical change per commit. Commit message format: `<type>: <short summary>` (e.g. `feat: add login handler`).
6. **No secrets in the repo.** Database passwords, tokens go in environment variables or a local `server/src/main/resources/application-local.properties` (gitignored).
7. **Test before claiming done.** See Testing section.

## How to work on a task

1. Pick a task from `docs/` or from the issue tracker. Prefer the smallest vertical slice that produces something runnable.
2. Check which files are affected (client, server, protocol, docs).
3. If the protocol changes, regenerate bindings on both sides before touching handlers.
4. Implement the smallest working version. No premature abstraction, no extra features.
5. Run the relevant tests (see below).
6. Commit with a clear message. Do not push unless explicitly asked.

## Coding conventions

### GDScript (client)

- 4-space indentation.
- `snake_case` for variables/functions, `PascalCase` for classes.
- One class per file; filename matches class name.
- Prefer signals for cross-node communication; avoid autoload singletons except `NetworkManager`.
- Type-hint function signatures where reasonable (`func move_player(id: int, pos: Vector3) -> void:`).
- Keep scripts short; extract helpers when a file exceeds ~150 lines.

### Java (server)

- Java 21, Maven build.
- Package: `com.example.mmo.<layer>`.
- 4-space indentation, Google Java Style.
- Prefer records for immutable DTOs; prefer `Optional` over null returns in public APIs.
- Netty handlers must never block — hand work to the zone executor.
- Database access only through the persistence layer; no raw SQL scattered in game logic.

### Protocol Buffers

- Message names: `PascalCase` verbs/nouns (`LoginRequest`, `PositionUpdate`).
- Field numbers are permanent — never reuse or renumber. Add new fields with new numbers.
- Every message includes or inherits a `protocol_version` for compatibility checks.

## Testing

### Server

```bash
cd server && mvn test
```

- Unit tests for game logic (movement validation, combat math, inventory) — no network, no DB.
- Integration tests with an embedded Netty server + a fake client for protocol round-trips.
- DB tests use Testcontainers (PostgreSQL) when persistence code is touched.

### Client

- Godot headless test mode: `godot --headless --path client -s scripts/run_tests.gd` (once test harness exists).
- Until then: manual smoke test — launch client, connect to local server, verify login + movement echo.

### Protocol

- After any `.proto` change: regenerate both sides and run at least one round-trip test (client sends, server echoes).

### Manual smoke test (minimum bar for any network feature)

1. Start PostgreSQL (docker: `docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=dev postgres:16`).
2. Start server: `./scripts/run-server.sh`.
3. Start client from Godot editor.
4. Log in with a test account, move the character, confirm the server broadcasts the position.

## Running the project

```bash
# Database
docker run -d --name mmo-db -p 5432:5432 -e POSTGRES_PASSWORD=dev postgres:16

# Server (from repo root)
./scripts/run-server.sh

# Client: open client/ in the Godot 4 editor and press F5
```

Default local endpoints: server TCP `localhost:7777`, PostgreSQL `localhost:5432`.

## What NOT to do

- Do not add dependencies without justification in the commit message.
- Do not refactor unrelated code while fixing a bug.
- Do not implement features not described in `docs/` without updating the docs first.
- Do not commit generated protobuf Java/GDScript files that are out of sync with `.proto` sources.
- Do not write long files; split by responsibility.
