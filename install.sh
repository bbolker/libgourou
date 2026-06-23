#!/usr/bin/env bash
# Install libgourou libraries, headers, and utility binaries system-wide.
# Requires sudo. Run from the libgourou directory after build_all.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GOUROU_BUILD="$SCRIPT_DIR/build"
PREFIX="${PREFIX:-/usr/local}"

if [ ! -f "$GOUROU_BUILD/libgourou.a" ]; then
    echo "ERROR: build directory not found or incomplete. Run build_all.sh first." >&2
    exit 1
fi

echo "=== Installing to $PREFIX ==="

sudo cmake --install "$GOUROU_BUILD" --prefix "$PREFIX"

echo "=== Done ==="
echo "Binaries: $PREFIX/bin/{acsmdownloader,adept_activate,adept_loan_mgt,adept_remove,launcher}"
echo "Libraries: $PREFIX/lib/libgourou.a  $PREFIX/lib/libgourou_utils.a"
echo "Headers: $PREFIX/include/"
