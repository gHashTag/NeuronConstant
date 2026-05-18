# Dry-Run Simulation Report — Trinity Tokenomics v2

**Author:** Dmitrii Vasilev (admin@t27.ai)
**Date:** 2026-05-18
**Method:** `forge script` against local `anvil --chain-id 84532` fork
**Status:** ✅ SUCCESSFUL — production deploy script verified end-to-end

---

## Summary

The full genesis deployment sequence was executed against a local Anvil EVM with the Base Sepolia chain-id (`84532`). All four contracts deployed in correct order, all post-deploy invariants passed, and the predicted TriToken address from `vm.computeCreateAddress(deployer, nonce+3)` exactly matched the on-chain deployment address — confirming the CREATE-nonce circular-dependency resolution works.

## Simulated addresses (anvil first deployer)

| Contract | Anvil Address |
|---|---|
| EmissionController | `0x5FbDB2315678afecb367f032d93F642f64180aa3` |
| MockChipRegistry | `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512` |
| MiningPool | `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0` |
| TriToken | `0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9` |
| **Predicted TriToken** | `0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9` ✓ MATCH |

> On real Base Sepolia, addresses will differ (depend on deployer + nonce), but the same prediction logic applies.

## Invariants verified on simulation

✅ Total supply on-chain: `7,625,597,484,987,000,000,000,000,000,000,000 wei`
   = 7,625,597,484,987 TRI × 10^18 (3^27 ternary-exact)
✅ MiningPool balance: same as total supply (100% locked)
✅ TriToken owner: `0x0000000000000000000000000000000000000000` (renounced in constructor)
✅ MiningPool owner: `0x0000000000000000000000000000000000000000` (renounced post-deploy)
✅ Predicted address == actual deployed address

## Gas estimates

| Metric | Value |
|---|---:|
| Estimated total gas | **5,364,040** gas |
| Estimated gas price | 2.000000001 gwei |
| Estimated ETH cost | **0.01072808 ETH** |
| At $0.00 testnet ETH | $0.00 (Sepolia is free) |
| Mainnet equivalent @ 30 gwei | ~0.161 ETH (~$580 at $3,600/ETH) |

PI must hold at least **~0.02 ETH** on Base Sepolia for safety margin (faucet provides 0.05 ETH).

## Deploy sequence executed

```
nonce + 0 → EmissionController(genesisTs)
nonce + 1 → MockChipRegistry()                  ← Sepolia testnet only
nonce + 2 → MiningPool(predictedTriToken, registry, genesisTs)
nonce + 3 → TriToken(pool)                      ← mints 3^27 TRI, auto-renounces
post     → MiningPool.renounceOwnership()
```

## Production deploy notes

**Base mainnet:** Replace `MockChipRegistry` deployment step with the address of the real Trinity hardware chip registry. Recommend pre-deploying registry, then this script consumes its address from env (`CHIP_REGISTRY_ADDRESS`).

**Determinism via CREATE2:** For predictable addresses across networks, switch from `new Contract()` to `new Contract{salt: ...}()` in a future iteration. Not required for v1 deployment.

---

*Generated from a successful Anvil dry-run on 2026-05-18.*
