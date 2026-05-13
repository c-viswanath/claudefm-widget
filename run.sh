#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "Building Claude FM widget..."
swift build -c release

echo "Launching..."
.build/release/ClaudeFMWidget
