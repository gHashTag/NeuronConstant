# IGLA On-Chain Integration — Deployment & Operations Guide

**Version:** 1.0.0-igla  
**Audience:** Protocol engineers, Railway operators, chip-owner administrators  
**Prerequisites:** `docs/igla/README.md`, Foundry, Node.js ≥ 18

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Step-by-Step Deployment](#2-step-by-step-deployment)
3. [IGLA Daemon Configuration](#3-igla-daemon-configuration)
4. [CLI Tool: igla-onchain](#4-cli-tool-igla-onchain)
5. [Event Monitoring](#5-event-monitoring)
6. [Gas Cost Reference](#6-gas-cost-reference)
7. [Upgrade Procedures](#7-upgrade-procedures)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Prerequisites

### 1.1 Tooling

```bash
# Foundry (Solidity compilation + deployment)
curl -L https://foundry.paradigm.xyz | bash && foundryup

# Node.js daemon dependencies
node --version  # >= 18.0.0
npm install ethers@6 axios dotenv

# IGLA daemon CLI
npm install -g igla-onchain
```

### 1.2 Environment Variables

Create `.env` in the Railway project root:

```bash
# ── Network ────────────────────────────────────────────────
RPC_URL=https://mainnet.infura.io/v3/<YOUR_KEY>
CHAIN_ID=1

# ── Oracle ────────────────────────────────────────────────
# IGLA daemon signing key (secp256k1 private key, hex)
# MUST match an address in IGLALedger.authorizedOracles
ORACLE_KEY=0x...

# ── Contract addresses (populated after deployment) ────────
IGLA_LEDGER_ADDRESS=0x...
TRAINING_PROVER_ADDRESS=0x...
TRI_BRIDGE_ADDRESS=0x...
TRI_TOKEN_ADDRESS=0x...
MOFN_ATTEST_ADDRESS=0x...

# ── IGLA RACE source ─────────────────────────────────────
# Path to local clone or Railway volume with seed_results.jsonl
IGLA_JSONL_PATH=/data/assertions/seed_results.jsonl
IGLA_CHAMPION_LOCK_PATH=/data/assertions/champion_lock.txt

# ── Reward recipient ──────────────────────────────────────
REWARD_TO=0x...   # Chip-owner wallet
```

---

## 2. Step-by-Step Deployment

### Step 1: Deploy TRIToken (if not already deployed)

```bash
cd /path/to/NeuronConstant

forge create contracts/src/TRIToken.sol:TRIToken \
  --constructor-args $TRI_BRIDGE_PLACEHOLDER_ADDR \
  --rpc-url $RPC_URL \
  --private-key $DEPLOYER_KEY \
  --verify
```

> If `TRIToken` is already deployed from `contracts/src/TRIToken.sol` (commit 07b84ec), skip this step and use the existing address.

### Step 2: Deploy TRIBridge

```bash
forge create contracts/src/TRIBridge.sol:TRIBridge \
  --constructor-args \
    $TRI_TOKEN_ADDRESS \
    "[${ORACLE_0},${ORACLE_1},${ORACLE_2}]" \
  --rpc-url $RPC_URL \
  --private-key $DEPLOYER_KEY \
  --verify
```

### Step 3: Deploy IGLALedger

```bash
forge create contracts/src/igla/IGLALedger.sol:IGLALedger \
  --constructor-args "[${ORACLE_ADDRESS}]" \
  --rpc-url $RPC_URL \
  --private-key $DEPLOYER_KEY \
  --verify
```

Record the deployed address as `IGLA_LEDGER_ADDRESS`.

### Step 4: Deploy MofNTrainingAttest (optional, for multi-chip setups)

```bash
forge create contracts/src/igla/MofNTrainingAttest.sol:MofNTrainingAttest \
  --constructor-args \
    "[${CHIP_OWNER_0},${CHIP_OWNER_1},${CHIP_OWNER_2}]" \
    2 \
  --rpc-url $RPC_URL \
  --private-key $DEPLOYER_KEY \
  --verify
```

### Step 5: Deploy TrainingProver

```bash
forge create contracts/src/igla/TrainingProver.sol:TrainingProver \
  --constructor-args \
    $IGLA_LEDGER_ADDRESS \
    $TRI_BRIDGE_ADDRESS \
    "[${ORACLE_ADDRESS}]" \
  --rpc-url $RPC_URL \
  --private-key $DEPLOYER_KEY \
  --verify
```

Record as `TRAINING_PROVER_ADDRESS`.

### Step 6: Wire Up Contracts

```bash
# Allow TrainingProver to call submitRowVerified on IGLALedger
cast send $IGLA_LEDGER_ADDRESS \
  "setTrainingProver(address)" $TRAINING_PROVER_ADDRESS \
  --rpc-url $RPC_URL \
  --private-key $DEPLOYER_KEY

# (Optional) Enable M-of-N attestation module
cast send $IGLA_LEDGER_ADDRESS \
  "setAttestModule(address)" $MOFN_ATTEST_ADDRESS \
  --rpc-url $RPC_URL \
  --private-key $DEPLOYER_KEY
```

### Step 7: Verify Champion Row (Smoke Test)

Submit the known champion row from `assertions/champion_lock.txt`:

```bash
igla-onchain submit \
  --rpc $RPC_URL \
  --oracle-key $ORACLE_KEY \
  --ledger $IGLA_LEDGER_ADDRESS \
  --chip-serial "$(igla-onchain chip-serial --auto)" \
  --bpb 2.2393 \
  --step 27000 \
  --seed 43 \
  --sha 2446855 \
  --jsonl-row 1 \
  --gate-status 1
```

Expected: transaction confirmed, `ChampionUpdated` event emitted.

---

## 3. IGLA Daemon Configuration

### 3.1 Daemon Architecture

The **IGLA daemon** is an off-chain Node.js process that:
1. Watches `$IGLA_JSONL_PATH` for new rows (inotify / polling)
2. Parses each new row into a `TrainingRow` struct
3. Signs the row with `$ORACLE_KEY` (EIP-191 personal-sign)
4. (Optional) Requests a ZK proof from the proving service
5. Submits to `IGLALedger.submitRow` or `TrainingProver.verifyAndSubmit`

### 3.2 Railway Environment Variables

In the Railway project dashboard, add:

```
IGLA_DAEMON_ENABLED=true
RPC_URL=<your RPC endpoint>
ORACLE_KEY=<oracle private key, hex without 0x prefix>
IGLA_LEDGER_ADDRESS=<deployed IGLALedger address>
TRAINING_PROVER_ADDRESS=<deployed TrainingProver address>
REWARD_TO=<chip-owner wallet address>
ZK_PROVER_ENDPOINT=http://prover-service:8080  # optional
POLL_INTERVAL_MS=5000
MIN_BPB_IMPROVEMENT=0.0001  # only submit if improvement > this
```

### 3.3 Daemon Pseudocode

```javascript
// igla-daemon.js
const { ethers } = require("ethers");
const fs = require("fs");

const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
const oracleWallet = new ethers.Wallet(process.env.ORACLE_KEY, provider);
const ledger = new ethers.Contract(
  process.env.IGLA_LEDGER_ADDRESS,
  IGLA_LEDGER_ABI,
  oracleWallet
);

let lastProcessedRow = 0;

async function processNewRows() {
  const jsonl = fs.readFileSync(process.env.IGLA_JSONL_PATH, "utf8");
  const rows = jsonl.trim().split("\n").slice(lastProcessedRow);

  for (const line of rows) {
    const entry = JSON.parse(line);
    const row = {
      chipSerial: ethers.solidityPackedKeccak256(["string"], [entry.chip_id]),
      step:       BigInt(entry.step),
      seed:       entry.seed,
      bpbE6:      Math.round(entry.bpb * 1e6),
      sha:        ethers.toUtf8Bytes(entry.sha).slice(0, 7),
      jsonlRow:   BigInt(lastProcessedRow + 1),
      gateStatus: entry.gate_status,
      timestamp:  0n  // set on-chain
    };

    // Build oracle signature
    const dataHash = ethers.solidityPackedKeccak256(
      ["bytes32","uint64","uint32","uint32","bytes7","uint64","uint8"],
      [row.chipSerial, row.step, row.seed, row.bpbE6,
       row.sha, row.jsonlRow, row.gateStatus]
    );
    const sig = await oracleWallet.signMessage(ethers.getBytes(dataHash));

    try {
      const tx = await ledger.submitRow(row, sig);
      await tx.wait();
      console.log(`Row submitted: step=${row.step} bpbE6=${row.bpbE6} txHash=${tx.hash}`);
    } catch (err) {
      console.error(`Row rejected: ${err.message}`);
    }

    lastProcessedRow++;
  }
}

setInterval(processNewRows, parseInt(process.env.POLL_INTERVAL_MS || "5000"));
```

---

## 4. CLI Tool: igla-onchain

### 4.1 Installation

```bash
npm install -g igla-onchain
# or from source:
cd tools/igla-onchain && npm install && npm link
```

### 4.2 Commands

#### `submit` — Submit a training row

```bash
igla-onchain submit \
  --rpc <RPC_URL> \
  --oracle-key <ORACLE_PRIVATE_KEY> \
  --ledger <IGLA_LEDGER_ADDRESS> \
  --chip-serial <bytes32_hex> \
  --bpb <float>       # e.g. 2.2393
  --step <int>        # e.g. 27000
  --seed <int>        # e.g. 43
  --sha <7char_hex>   # e.g. 2446855
  --jsonl-row <int>   # row index in seed_results.jsonl
  --gate-status <0|1|2>
  [--proof <path_to_proof.bin>]   # optional ZK proof
  [--reward-to <address>]         # required with --proof
```

**With ZK proof (via TrainingProver):**

```bash
igla-onchain submit \
  --rpc $RPC_URL \
  --prover $TRAINING_PROVER_ADDRESS \
  --oracle-key $ORACLE_KEY \
  --chip-serial 0xabc... \
  --bpb 2.2393 \
  --step 27000 \
  --seed 43 \
  --sha 2446855 \
  --jsonl-row 1 \
  --gate-status 1 \
  --loss-curve-hash 0xdef... \
  --weights-root 0x789... \
  --proof /tmp/training_proof.bin \
  --reward-to $REWARD_TO
```

#### `champion` — Query current champion

```bash
igla-onchain champion --rpc $RPC_URL --ledger $IGLA_LEDGER_ADDRESS
# Output:
# Champion: BPB=2.2393 step=27000 seed=43 chip=0xabc... ts=1703001234
```

#### `gate2` — Check gate-2 quorum for a BPB target

```bash
igla-onchain gate2 --rpc $RPC_URL --ledger $IGLA_LEDGER_ADDRESS --bpb 2.2393
# Output: Gate2 quorum for BPB=2.2393: YES (3/3 chips)
```

#### `chip-serial` — Derive chipSerial from hardware ID

```bash
igla-onchain chip-serial --chip-id "SKY26B-TRINITY-001"
# Output: 0x7c3a...
```

---

## 5. Event Monitoring

### 5.1 Key Events

| Contract | Event | Trigger |
|----------|-------|---------|
| `IGLALedger` | `RowSubmitted` | Any accepted training row |
| `IGLALedger` | `ChampionUpdated` | New global best BPB |
| `IGLALedger` | `Gate2QuorumReached` | 3rd chip hits a BPB target |
| `TrainingProver` | `TrainingProofVerified` | ZK proof accepted |
| `TrainingProver` | `TrainingRewardMinted` | $TRI reward issued |
| `MofNTrainingAttest` | `RowAttested` | Chip-owner attests a row |
| `MofNTrainingAttest` | `QuorumReached` | 2-of-3 threshold met |

### 5.2 ethers.js Listener

```javascript
const ledger = new ethers.Contract(IGLA_LEDGER_ADDRESS, ABI, provider);

ledger.on("ChampionUpdated", (chipSerial, step, seed, bpbE6, timestamp) => {
  const bpb = Number(bpbE6) / 1e6;
  console.log(`🏆 New champion: BPB=${bpb} step=${step} seed=${seed}`);
  // Update frontend, send notifications, etc.
});

ledger.on("Gate2QuorumReached", (targetBpbE6, chipCount) => {
  console.log(`✅ Gate-2 quorum reached for BPB=${Number(targetBpbE6)/1e6}`);
});
```

### 5.3 Subgraph (The Graph)

For historical queries and dashboards, deploy a subgraph:

```yaml
# subgraph.yaml (excerpt)
dataSources:
  - kind: ethereum/contract
    name: IGLALedger
    source:
      address: "0x..."
      abi: IGLALedger
    mapping:
      eventHandlers:
        - event: RowSubmitted(indexed bytes32,uint64,uint32,uint32,uint64,uint8,uint64)
          handler: handleRowSubmitted
        - event: ChampionUpdated(indexed bytes32,uint64,uint32,uint32,uint64)
          handler: handleChampionUpdated
```

---

## 6. Gas Cost Reference

| Operation | Gas estimate | Notes |
|-----------|-------------|-------|
| `IGLALedger.submitRow` | ~120_000 | Oracle sig verify + SSTORE × 6 |
| `IGLALedger.submitRowVerified` | ~100_000 | No sig verify, but SSTORE × 6 |
| `MofNTrainingAttest.attestRow` | ~65_000 | ecrecover + SSTORE × 2 |
| `MofNTrainingAttest.attestRowDirect` | ~45_000 | No ecrecover |
| `TrainingProver.verifyTrainingProof` (view) | ~250_000 | 4 BN254 pairings |
| `TrainingProver.verifyAndSubmit` | ~400_000 | ZK + oracle + submitRowVerified + mint |
| `TrainingProver.bpbToReward` (view) | ~2_000 | Pure computation |

**End-to-end cost (ZK path):**  
`verifyAndSubmit` → `submitRowVerified` → `mintTrainingReward` → `TRIToken.mint`  
≈ 400_000 + 30_000 = **~430_000 gas per champion row submission**

At 30 gwei gas price, $3_000 ETH: `430_000 × 30e-9 × 3_000 ≈ $0.039 per submission`

---

## 7. Upgrade Procedures

### 7.1 New Oracle Address

```bash
# Add new oracle
cast send $IGLA_LEDGER_ADDRESS \
  "setOracle(address,bool)" $NEW_ORACLE_ADDRESS true \
  --rpc-url $RPC_URL --private-key $DEPLOYER_KEY

# Remove old oracle (if rotating)
cast send $IGLA_LEDGER_ADDRESS \
  "setOracle(address,bool)" $OLD_ORACLE_ADDRESS false \
  --rpc-url $RPC_URL --private-key $DEPLOYER_KEY
```

### 7.2 New TrainingProver (VK Update after Trusted Setup)

1. Deploy new `TrainingProver` with production VK constants
2. `IGLALedger.setTrainingProver(newProver)` (owner only)
3. Update `TRAINING_PROVER_ADDRESS` in daemon config
4. Old prover remains deployed but ledger will reject its `submitRowVerified` calls

### 7.3 Chip-Owner Key Rotation

```bash
cast send $MOFN_ATTEST_ADDRESS \
  "setChipOwner(uint8,address)" 0 $NEW_CHIP_OWNER_0 \
  --rpc-url $RPC_URL --private-key $DEPLOYER_KEY
```

---

## 8. Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `IGLALedger: invalid oracle signature` | Wrong oracle key or wrong data hash | Check `ORACLE_KEY` env var matches authorized oracle |
| `IGLALedger: BPB does not improve best` | New bpbE6 >= current bestBPB | Only submit rows with strictly better BPB |
| `IGLALedger: step regression` | step <= lastStep | Training step must be monotonically increasing |
| `IGLALedger: not trainingProver` | Direct call to submitRowVerified | Use TrainingProver.verifyAndSubmit instead |
| `TrainingProver: invalid ZK proof` | VK placeholders not replaced | After ceremony, update VK constants and redeploy |
| `MofNAttest: signer not a chip-owner` | Attesting with non-registered key | Check chipOwners[0..2] in MofNTrainingAttest |
| `TRIBridge: caller not authorized` | mintTrainingReward called by wrong address | Ensure TRIBridge authorizes TrainingProver for mint |

---

*See also: [docs/igla/README.md](./README.md), [docs/igla/THREAT_MODEL.md](./THREAT_MODEL.md), [docs/zk/INTEGRATION.md](../zk/INTEGRATION.md)*
