# Project World

An MMO project. This repository holds architecture plans and (eventually) source code.

## Stack

| Layer | Technology |
| --- | --- |
| Client | Godot 4 (GDScript), OpenGL, Windows + Linux |
| Server | Java 21, Netty, PostgreSQL |
| Protocol | Protocol Buffers (shared `.proto`) |

## Docs

- [Architecture overview](docs/architecture.md) — full client + server plan
- [Client plan](docs/client.md) — Godot client layers and communication
- [Server plan](docs/server.md) — Java server architecture
- [Protocol](docs/protocol.md) — shared protobuf contract

## Status

Planning phase. No implementation yet.
