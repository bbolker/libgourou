#!/usr/bin/env bash
# Build libgourou and its local dependencies (pugixml, updfparser).
# Run from the libgourou directory; the three repos must be siblings:
#
#   <parent>/
#     libgourou/    <- run this script from here
#     pugixml/
#     updfparser/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

PUGIXML_SRC="$PARENT_DIR/pugixml"
PUGIXML_BUILD="$PUGIXML_SRC/build-cmake"

UPDF_SRC="$PARENT_DIR/updfparser"
UPDF_BUILD="$UPDF_SRC/build-cmake"
UPDF_INSTALL="$UPDF_SRC/install"

GOUROU_BUILD="$SCRIPT_DIR/build"

BUILD_TYPE="${BUILD_TYPE:-Release}"

echo "=== Installing system packages (if needed) ==="
APT_PKGS=()
for pkg in build-essential cmake pkg-config libssl-dev libcurl4-openssl-dev libzip-dev; do
    dpkg -s "$pkg" &>/dev/null || APT_PKGS+=("$pkg")
done
if [ "${#APT_PKGS[@]}" -gt 0 ]; then
    sudo apt-get install -y "${APT_PKGS[@]}"
fi

echo "=== Cloning dependencies (if needed) ==="
if [ ! -d "$PUGIXML_SRC" ]; then
    git clone https://github.com/zeux/pugixml.git "$PUGIXML_SRC"
fi
if [ ! -d "$UPDF_SRC" ]; then
    git clone -b cmake https://github.com/SamuelMarks/updfparser.git "$UPDF_SRC"
    # GCC 13 removed transitive includes that previously provided uint64_t etc.
    sed -i 's|#include <map>|#include <cstdint>\n#include <map>|' "$UPDF_SRC/include/uPDFTypes.h"
fi

echo "=== Building pugixml ==="
cmake -DCMAKE_BUILD_TYPE="$BUILD_TYPE" -S "$PUGIXML_SRC" -B "$PUGIXML_BUILD"
cmake --build "$PUGIXML_BUILD"

echo "=== Building updfparser ==="
cmake -DCMAKE_BUILD_TYPE="$BUILD_TYPE" -S "$UPDF_SRC" -B "$UPDF_BUILD"
cmake --build "$UPDF_BUILD"
cmake --install "$UPDF_BUILD" --prefix "$UPDF_INSTALL"

echo "=== Building libgourou ==="
cmake -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
      -DCMAKE_PREFIX_PATH="$PUGIXML_BUILD;$UPDF_INSTALL" \
      -S "$SCRIPT_DIR" \
      -B "$GOUROU_BUILD"
cmake --build "$GOUROU_BUILD"

echo "=== Done ==="
echo "Outputs in: $GOUROU_BUILD"
