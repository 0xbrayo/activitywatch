#!/usr/bin/env bash
# Stage aw-awatcher + aw-sync into aw-tauri/src-tauri/modules/ so
# `make -C aw-tauri build` can inject them via bundle.resources.
#
# Makes Linux deb/rpm/AppImage self-contained (ActivityWatch/aw-tauri#232).
# Must run after awatcher and aw-server-rust (aw-sync) are built, and before
# aw-tauri is built.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

MODULES_DIR="$ROOT/aw-tauri/src-tauri/modules"
mkdir -p "$MODULES_DIR"
rm -f "$MODULES_DIR/aw-awatcher" "$MODULES_DIR/aw-sync"

TARGETDIR="${targetdir:-release}"
if [ "${RELEASE:-true}" = "false" ]; then
    TARGETDIR="debug"
fi

# awatcher cargo binary is "awatcher"; AW packaging renames it to aw-awatcher
# so module discovery (aw-* prefix) and default config match.
AWATCHER_SRC=""
for candidate in \
    "awatcher/target/${TARGETDIR}/awatcher" \
    "awatcher/dist/awatcher/aw-awatcher" \
    "awatcher/target/package/aw-awatcher"
do
    if [ -f "$candidate" ]; then
        AWATCHER_SRC="$candidate"
        break
    fi
done

if [ -z "$AWATCHER_SRC" ]; then
    echo "ERROR: awatcher binary not found (build awatcher first)" >&2
    echo "  looked under awatcher/target/${TARGETDIR}/awatcher and package outputs" >&2
    exit 1
fi

AWSYNC_SRC=""
for candidate in \
    "aw-server-rust/target/${TARGETDIR}/aw-sync" \
    "aw-server-rust/target/${TARGETDIR}/aw-sync/aw-sync"
do
    if [ -f "$candidate" ]; then
        AWSYNC_SRC="$candidate"
        break
    fi
done

if [ -z "$AWSYNC_SRC" ]; then
    echo "ERROR: aw-sync binary not found (build aw-server-rust aw-sync first)" >&2
    echo "  looked under aw-server-rust/target/${TARGETDIR}/aw-sync" >&2
    exit 1
fi

cp -f "$AWATCHER_SRC" "$MODULES_DIR/aw-awatcher"
cp -f "$AWSYNC_SRC" "$MODULES_DIR/aw-sync"
chmod +x "$MODULES_DIR/aw-awatcher" "$MODULES_DIR/aw-sync"

echo "Staged Linux Tauri modules:"
ls -la "$MODULES_DIR/aw-awatcher" "$MODULES_DIR/aw-sync"
