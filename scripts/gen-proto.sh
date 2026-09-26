#!/usr/bin/env bash
# Generate Protocol Buffer bindings for both server (Java) and client (GDScript).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROTO_DIR="$ROOT/protocol"

echo "==> Checking protoc"
if ! command -v protoc &>/dev/null; then
  echo "protoc not found. Install: https://protobuf.dev/installation/"
  exit 1
fi

echo "==> Generating Java classes -> server/src/main/java"
protoc --proto_path="$PROTO_DIR" \
  --java_out="$ROOT/server/src/main/java" \
  "$PROTO_DIR"/*.proto

echo "==> Generating GDScript bindings -> client/proto"
mkdir -p "$ROOT/client/proto"
# Requires protoc-gen-gdscript (install separately) or a custom plugin.
# protoc --proto_path="$PROTO_DIR" --gdscript_out="$ROOT/client/proto" "$PROTO_DIR"/*.proto

echo "==> Done. Remember to commit generated files alongside the .proto changes."
