#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="$DIR/murchi"

echo "Compiling Murchi..."
swiftc "$DIR/Murchi.swift" \
    -framework AppKit \
    -framework Foundation \
    -o "$BIN" \
    -swift-version 5 \
    -O \
    2>&1

echo "Launching Murchi!"
"$BIN"
