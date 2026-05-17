#!/usr/bin/env bash
# sync_from_trinity.sh — Pull latest RTL from upstream tt-trinity-* submission repos
#                        into NeuronConstant tiles/
#
# Usage: bash scripts/sync_from_trinity.sh [tile-name]
#   tile-name: phi-anchor | e-engine | gamma-surface (optional; all if omitted)
#
# This script syncs NeuronConstant tiles/ from the canonical tt-trinity-* submission
# repos. The submission repos are the current upstream (until gHashTag/trinity
# hardware/ is refactored into NeuronConstant — see issue #1).
#
# Requires: gh CLI authenticated, rsync
#
# IMPORTANT: Do NOT run this during active development in NeuronConstant tiles/.
#            Local changes will be overwritten.
#
# NeuronConstant canonical hardware catalog
# DOI: 10.5281/zenodo.19227877 · Apache-2.0

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

declare -A MAP=(
    [phi-anchor]="tt-trinity-phi"
    [e-engine]="tt-trinity-euler"
    [gamma-surface]="tt-trinity-gamma"
)

# Determine which tiles to sync
if [[ $# -gt 0 ]]; then
    TILES=("$1")
    # Validate
    if [[ -z "${MAP[$1]+_}" ]]; then
        echo "ERROR: Unknown tile '$1'. Valid: phi-anchor, e-engine, gamma-surface" >&2
        exit 1
    fi
else
    TILES=("phi-anchor" "e-engine" "gamma-surface")
fi

echo "NeuronConstant sync_from_trinity.sh"
echo "====================================="

for tile in "${TILES[@]}"; do
    upstream="gHashTag/${MAP[$tile]}"
    echo ""
    echo "Syncing $tile from $upstream ..."

    TMP=$(mktemp -d)
    trap "rm -rf $TMP" EXIT

    # Shallow clone of upstream
    gh repo clone "$upstream" "$TMP/repo" -- --depth 1 --quiet

    # Sync RTL
    if [[ -d "$TMP/repo/src" ]]; then
        mkdir -p "$REPO_ROOT/tiles/$tile/rtl"
        rsync -a --delete "$TMP/repo/src/" "$REPO_ROOT/tiles/$tile/rtl/"
        echo "  ✓ RTL synced: $(ls "$REPO_ROOT/tiles/$tile/rtl/" | wc -l) files"
    else
        echo "  WARNING: no src/ directory in $upstream" >&2
    fi

    # Sync testbenches
    if [[ -d "$TMP/repo/test" ]]; then
        mkdir -p "$REPO_ROOT/tiles/$tile/tb"
        rsync -a --delete "$TMP/repo/test/" "$REPO_ROOT/tiles/$tile/tb/"
        echo "  ✓ TB  synced: $(ls "$REPO_ROOT/tiles/$tile/tb/" | wc -l) files"
    else
        echo "  WARNING: no test/ directory in $upstream" >&2
    fi

    # Sync TT metadata
    if [[ -f "$TMP/repo/info.yaml" ]]; then
        mkdir -p "$REPO_ROOT/tiles/$tile/tt"
        cp "$TMP/repo/info.yaml" "$REPO_ROOT/tiles/$tile/tt/info.yaml"
        echo "  ✓ info.yaml synced"
    fi

    # Also update common/constants if syncing phi-anchor (single source of truth)
    if [[ "$tile" == "phi-anchor" ]]; then
        if [[ -f "$TMP/repo/src/sacred_constants_rom.v" ]]; then
            cp "$TMP/repo/src/sacred_constants_rom.v" "$REPO_ROOT/common/constants/sacred_constants_rom.v"
            echo "  ✓ common/constants/sacred_constants_rom.v updated"
        fi
        if [[ -f "$TMP/repo/src/crown47_rom.v" ]]; then
            cp "$TMP/repo/src/crown47_rom.v" "$REPO_ROOT/common/constants/crown47_rom.v"
            echo "  ✓ common/constants/crown47_rom.v updated"
        fi
    fi

    trap - EXIT
    rm -rf "$TMP"
    echo "  ✓ $tile sync complete"
done

echo ""
echo "All syncs complete. Review changes with: git diff tiles/"
echo ""
echo "NOTE: After sync, run R-SI-1 audit:"
echo "  bash common/verification/r_si_1_check.sh tiles/phi-anchor/rtl"
echo "  bash common/verification/r_si_1_check.sh tiles/e-engine/rtl"
echo "  bash common/verification/r_si_1_check.sh tiles/gamma-surface/rtl"
