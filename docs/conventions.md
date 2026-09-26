# Coding Conventions

## General

- 4-space indentation everywhere (GDScript, Java, shell, markdown).
- UTF-8, LF line endings.
- English for code identifiers and comments; Hungarian is fine for personal notes outside the repo.
- Prefer clarity over cleverness. A boring, obvious implementation beats a clever one.

## GDScript (client/)

- Variables and functions: `snake_case`. Classes: `PascalCase`. Files: `snake_case.gd` matching the class.
- Type-hint public function signatures.
- Use signals for node-to-node events; `call_deferred` when crossing thread boundaries.
- Autoloads are reserved: `NetworkManager` is the only planned autoload.
- Scene-specific logic lives in the scene's script; reusable logic goes to `scripts/`.
- Max ~150 lines per script; extract helpers when exceeded.

## Java (server/)

- Package layout: `com.example.mmo.net`, `.session`, `.game`, `.world`, `.persistence`, `.admin`.
- Immutable data: Java `record`s. Public APIs return `Optional`, never null.
- Netty I/O threads must not block: delegate to the per-zone executor.
- SQL only inside `persistence/`; game logic never touches the DB directly.
- Logging via SLF4J; log at INFO for lifecycle events, DEBUG for per-message traffic.

## Protocol Buffers (protocol/)

- One file per domain area is fine; keep total message count small.
- Field numbers are immutable: append new fields, never reuse numbers.
- Include `protocol_version` in the handshake for compatibility.
- After editing: run `./scripts/gen-proto.sh` and commit generated outputs together with the `.proto`.

## Git

- Commit format: `<type>: <imperative summary>` where type is feat/fix/docs/chore/test/refactor.
- One logical change per commit.
- Never commit: `*.local.properties`, `.env`, IDE files, build outputs (`target/`, `.godot/` except `export_presets.cfg`).
