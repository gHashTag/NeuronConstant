#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
# Trinity Network — Base Sepolia deployment one-command launcher
# Author: Dmitrii Vasilev (admin@t27.ai)
# Usage:  cp .env.example .env  # fill in YOUR keys
#         ./deploy.sh
# ────────────────────────────────────────────────────────────────
set -euo pipefail

if [ ! -f .env ]; then
    echo "ERROR: .env not found. Run: cp .env.example .env && edit it."
    exit 1
fi

# shellcheck disable=SC1091
source .env

: "${PRIVATE_KEY:?PRIVATE_KEY not set in .env}"
: "${BASE_SEPOLIA_RPC:?BASE_SEPOLIA_RPC not set in .env}"
: "${BASESCAN_API_KEY:?BASESCAN_API_KEY not set in .env}"

export PRIVATE_KEY BASE_SEPOLIA_RPC BASESCAN_API_KEY

echo "════════════════════════════════════════════════════════════"
echo "  Trinity Network — Genesis Deployment to Base Sepolia"
echo "  Supply: 7,625,597,484,987 TRI = 3^27"
echo "  Author: Dmitrii Vasilev (admin@t27.ai)"
echo "════════════════════════════════════════════════════════════"
echo ""

forge script script/Deploy.s.sol:DeployTrinity \
    --rpc-url "$BASE_SEPOLIA_RPC" \
    --broadcast \
    --verify \
    --etherscan-api-key "$BASESCAN_API_KEY" \
    --slow \
    -vvv

echo ""
echo "✓ Deployed. Update docs/tokenomics/v2/DEPLOYMENT_BASE_SEPOLIA.md"
echo "  with the printed addresses + Basescan links."
