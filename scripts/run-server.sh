#!/usr/bin/env bash
# Build and run the Java game server locally.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/server"

echo "==> Building server"
mvn -q -DskipTests package

echo "==> Starting server (TCP localhost:7777)"
java -jar target/mmo-server.jar
