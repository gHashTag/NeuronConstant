#!/usr/bin/env bash
# export_tt_project.sh — Export NeuronConstant tile to Tiny Tapeout-compatible flat structure
#
# Usage: export_tt_project.sh <tile-name> <output-dir>
#   tile-name : phi-anchor | e-engine | gamma-surface
#   output-dir: destination directory (will be created)
#
# The exported directory follows the standard TT layout:
#   src/       — RTL source files (.v)
#   test/      — testbenches (cocotb)
#   docs/      — documentation
#   info.yaml  — Tiny Tapeout submission metadata
#
# Example:
#   bash scripts/export_tt_project.sh phi-anchor /tmp/export/tt-phi-anchor
#
# NeuronConstant canonical hardware catalog
# DOI: 10.5281/zenodo.19227877 · Apache-2.0

set -euo pipefail

TILE="${1:?usage: export_tt_project.sh <tile-name> <output-dir>}"
OUT="${2:?usage: export_tt_project.sh <tile-name> <output-dir>}"

# Resolve script location to find repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="$REPO_ROOT/tiles/$TILE"

# Validate tile name
case "$TILE" in
    phi-anchor|e-engine|gamma-surface) ;;
    *)
        echo "ERROR: Unknown tile '$TILE'. Valid: phi-anchor, e-engine, gamma-surface" >&2
        exit 1
        ;;
esac

# Validate tile directory exists
if [[ ! -d "$SRC" ]]; then
    echo "ERROR: Tile directory not found: $SRC" >&2
    exit 1
fi

echo "Exporting $TILE → $OUT ..."

mkdir -p "$OUT"/{src,test,docs}

# Copy RTL sources
if [[ -d "$SRC/rtl" ]] && [[ "$(ls -A "$SRC/rtl" 2>/dev/null)" ]]; then
    cp -r "$SRC/rtl/"* "$OUT/src/"
    echo "  ✓ RTL: $(ls "$SRC/rtl/" | wc -l) files → $OUT/src/"
else
    echo "  WARNING: no RTL files in $SRC/rtl/" >&2
fi

# Copy testbenches
if [[ -d "$SRC/tb" ]] && [[ "$(ls -A "$SRC/tb" 2>/dev/null)" ]]; then
    cp -r "$SRC/tb/"* "$OUT/test/"
    echo "  ✓ TB:  $(ls "$SRC/tb/" | wc -l) files → $OUT/test/"
else
    echo "  WARNING: no testbench files in $SRC/tb/" >&2
fi

# Copy docs
if [[ -d "$SRC/docs" ]] && [[ "$(ls -A "$SRC/docs" 2>/dev/null)" ]]; then
    cp -r "$SRC/docs/"* "$OUT/docs/"
    echo "  ✓ Docs: $(ls "$SRC/docs/" | wc -l) files → $OUT/docs/"
fi

# Copy TT metadata
if [[ -f "$SRC/tt/info.yaml" ]]; then
    cp "$SRC/tt/info.yaml" "$OUT/info.yaml"
    echo "  ✓ info.yaml → $OUT/info.yaml"
else
    echo "  WARNING: no info.yaml found at $SRC/tt/info.yaml" >&2
fi

echo ""
echo "Exported $TILE → $OUT"
echo "Structure:"
find "$OUT" -type f | sort | sed "s|$OUT/||"
