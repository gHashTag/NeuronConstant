# Trinity Network — Base Sepolia Deployment Runbook

**Author:** Dmitrii Vasilev (PI, admin@t27.ai)
**Network:** Base Sepolia (chainId 84532) → Base Mainnet (8453, later)
**Date:** 2026-05-18

> This document is the PI runbook for taking the dry-run-validated Trinity v2 contracts live on Base Sepolia testnet. The deploy script (`contracts/v2/script/Deploy.s.sol`) has been validated against a local Anvil fork with chain-id `84532` and all post-deploy invariants pass (see `DRY_RUN_SIMULATION.md`).

---

## TL;DR — one command after setup

```bash
cd contracts/v2
cp .env.example .env       # then edit .env with YOUR keys
./deploy.sh
```

---

## Prerequisites

### 1. Install Foundry (one-time)

```bash
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc            # or restart shell
foundryup                   # installs forge, cast, anvil, chisel
forge --version
```

Confirmed working with **Forge 1.7.1+** and **Solc 0.8.24**.

### 2. Get Base Sepolia ETH (need ~0.02 ETH)

Faucets (any one works):
- [Alchemy Base Sepolia faucet](https://www.alchemy.com/faucets/base-sepolia)
- [Coinbase Sepolia faucet](https://www.coinbase.com/faucets/base-ethereum-sepolia-faucet)
- [QuickNode Base Sepolia faucet](https://faucet.quicknode.com/base/sepolia)

Estimated cost: **0.0107 ETH** at 2 gwei (see DRY_RUN_SIMULATION.md). 0.05 ETH from faucet leaves comfortable margin.

### 3. Get Basescan API key (for `--verify`)

1. Register at https://basescan.org/register
2. Visit https://basescan.org/myapikey
3. Click "Add" → name it "trinity-deploy" → copy the key

(Same key works for `sepolia.basescan.org` and `basescan.org`.)

---

## Setup

```bash
cd /path/to/NeuronConstant/contracts/v2

# 1. Install Solidity dependencies
mkdir -p lib
git clone --depth 1 --branch v1.9.7 \
  https://github.com/foundry-rs/forge-std.git lib/forge-std
git clone --depth 1 --branch v5.1.0 \
  https://github.com/OpenZeppelin/openzeppelin-contracts.git lib/openzeppelin-contracts

# 2. Verify build
forge build --sizes

# 3. Run tests (must show 7/7 PASS)
forge test -vv

# 4. Create your .env (NEVER commit this)
cp .env.example .env
$EDITOR .env
#   PRIVATE_KEY=0x<your funded key>
#   BASESCAN_API_KEY=<your key>
#   BASE_SEPOLIA_RPC=https://sepolia.base.org   (default)
```

## Deploy

```bash
./deploy.sh
```

What this runs:

```bash
forge script script/Deploy.s.sol:DeployTrinity \
    --rpc-url   $BASE_SEPOLIA_RPC \
    --broadcast \
    --verify \
    --etherscan-api-key $BASESCAN_API_KEY \
    --slow \
    -vvv
```

`--slow` adds a brief delay between transactions so the RPC sees each receipt before the next call (Base Sepolia occasionally rate-limits batched submissions).

## Expected output

```
==== Trinity Network -- Genesis Deployment ====
Deployer:           0xYOURADDRESS
Chain ID:           84532
Expected supply:    7,625,597,484,987 TRI (3^27)
Predicted TriToken: 0x...

[anvil tx 1] EmissionController deployed
[anvil tx 2] MockChipRegistry deployed
[anvil tx 3] MiningPool deployed
[anvil tx 4] TriToken deployed (mints to MiningPool, renounces ownership)
[anvil tx 5] MiningPool.renounceOwnership

==== Deployment Successful ====
TriToken:            0x...
MiningPool:          0x...
EmissionController:  0x...
MockChipRegistry:    0x...
Total supply (wei):  7625597484987000000000000000000
Locked in pool:      7625597484987000000000000000000
Ownerships renounced (token+pool): YES
```

All addresses get auto-verified on Basescan within ~30 seconds.

## Post-deploy actions

1. **Save addresses** — append to `docs/tokenomics/v2/DEPLOYMENT_BASE_SEPOLIA.md`:
   ```
   - TriToken:            0x...   [Basescan](https://sepolia.basescan.org/address/0x...)
   - MiningPool:          0x...
   - EmissionController:  0x...
   - MockChipRegistry:    0x...   (Sepolia only)
   - Tx hash:             0x...
   - Block:               12345678
   - Genesis timestamp:   1779109987
   ```

2. **Spot-check on Basescan:**
   - Open `https://sepolia.basescan.org/token/<TriToken address>`
   - Verify Total Supply reads `7,625,597,484,987` TRI
   - Holders tab → MiningPool holds 100%
   - Read Contract → `owner()` returns zero address

3. **Commit deployment record:**
   ```bash
   git add docs/tokenomics/v2/DEPLOYMENT_BASE_SEPOLIA.md
   git commit -m "feat(deploy): Trinity v2 live on Base Sepolia"
   git push origin main
   ```

4. **Tweet announcement** — update `TWITTER_LAUNCH_THREAD.md` tweet 8 with the Basescan link.

5. **Update whitepaper §7** with the live contract addresses.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `insufficient funds for gas` | Top up faucet — need ~0.02 ETH on Base Sepolia |
| `nonce too low` | `cast nonce $DEPLOYER --rpc-url $BASE_SEPOLIA_RPC` and pass `--nonce N` |
| `code too large` | Already validated, shouldn't happen — but reduce optimizer_runs in foundry.toml |
| `verification failed` | Re-run with `forge verify-contract <addr> <Contract> --watch` |
| `TriToken address mismatch` | Deployer nonce changed mid-script — re-run from fresh nonce |

## Production (Base mainnet) checklist — NOT for Sepolia

When ready for mainnet:

- [ ] Replace `MockChipRegistry` with real Trinity chip registry (post tape-out)
- [ ] Switch `--rpc-url` to `https://mainnet.base.org`
- [ ] Set `--gas-price` explicitly (mainnet gas market more dynamic)
- [ ] Multisig the deployer key OR use Safe + hardware wallet
- [ ] External audit of all contracts before mainnet deploy
- [ ] Set `GENESIS_TIMESTAMP` env var to the intended fair-launch moment
- [ ] Coordinate with Bittensor EVM bridge + Solana SPL mirror deploys

## Security notes

- **Private key never leaves `.env`** — `.gitignore` blocks the file from git.
- **Ownerships renounced automatically** — no admin key risk post-deploy.
- **Source verified on Basescan** — open-source from minute one.
- **Dry-run validated** — full deployment sequence tested on local Anvil; see `DRY_RUN_SIMULATION.md`.

---

## DOI & Authorship

Project: [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)
Author: **Dmitrii Vasilev** (sole author, admin@t27.ai)

*Last updated 2026-05-18.*
