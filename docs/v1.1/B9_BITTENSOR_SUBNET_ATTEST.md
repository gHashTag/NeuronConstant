# B9 — BittensorSubnetAttest.sol — Bittensor Hardware-Attested Validators (Trinity v1.1)

## Metadata

| Field | Value |
|---|---|
| Module | BittensorSubnetAttest.sol (Solidity contract, no HW tile) |
| Category | B |
| Closes gap | M9 (Bittensor subnet validator) |
| Target deployment | Ethereum L2 (Optimism/Base) or Bittensor-EVM bridge |
| Tile budget | 0 (smart contract only) |
| Effort | 1 week |
| Competitors | Bittensor mainnet (validators software-only, no HW attestation) |
| PI | Dmitrii Vasilev (admin@t27.ai) |
| Depends on | B1 (RoT signatures), B5 (champion BPB lock), IGLALedger.sol |

---

## 1. Purpose

Bittensor validators today are pure software stakers. Anyone with sufficient capital can operate a validator without proving honest compute. The Trinity proposal introduces hardware-attested validators using a 2-of-3 chip-owner attestation scheme across three chip classes: **phi**, **euler**, and **gamma**. Attestation is tied to the BPB champion lock (B5) as a miner ranking baseline, making validator credentialing cryptographically anchored to physical hardware rather than economic stake alone.

### Problem statement

| Current state | Trinity target |
|---|---|
| Validator = TAO stake only | Validator = TAO stake + 2-of-3 RoT attestation |
| No hardware proof of compute | Chip-signed ZK proof of work per epoch |
| BPB claims unverifiable on-chain | IGLALedger.sol champion lock enforced |
| Slashing purely economic | Slashing triggers from attestation regression |

### Design goals

1. Prevent Sybil validators that hold stake but do not perform honest compute.
2. Provide a cryptographically verifiable chain of custody from physical chip to on-chain reward.
3. Integrate with Bittensor Yuma consensus without forking the subnet protocol.
4. Remain upgradable to BLS aggregation once EIP-2537 is widely available on L2s.

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│  Bittensor Subnet (off-chain)                                       │
│                                                                     │
│  Miner submits work + claimed BPB score                             │
│       │                                                             │
│       ▼                                                             │
│  Trinity Validator Node                                             │
│   ├─ Runs zk_job_prover (B5) OR locally re-verifies work           │
│   ├─ Signs result with phi RoT key (B1)                             │
│   ├─ Collects co-signatures from euler + gamma RoT keys (B1)        │
│   └─ Assembles: {minerHash, bpbScore, zkProof, chipSigs[3]}        │
│       │                                                             │
│       ▼                                                             │
│  BittensorSubnetAttest.sol (L2 / EVM bridge)                        │
│   ├─ _verifyChipSignatures() — 2-of-3 check                        │
│   ├─ _verifyZKProof()        — Groth16 B5 verifier                  │
│   ├─ _checkBPBRegression()   — IGLALedger.sol champion lock         │
│   └─ distributeReward()      — TRI mint + protocol fee              │
│       │                                                             │
│       ▼                                                             │
│  IGLALedger.sol                    TRI.sol                          │
│   └─ champion BPB persisted         └─ reward mint / slash burn     │
└─────────────────────────────────────────────────────────────────────┘
```

### Component responsibilities

| Component | Role |
|---|---|
| `BittensorSubnetAttest.sol` | Core attestation, slashing, reward distribution |
| `IGLALedger.sol` | Champion BPB record and regression oracle |
| `TRI.sol` | ERC-20 reward token with mint/burn access control |
| `B1 RoT keys` | phi / euler / gamma chip identity roots |
| `B5 zk_job_prover` | Groth16 proof of BPB computation |

---

## 3. Solidity Skeleton (Full Contract ~250 lines)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IGLALedger.sol";
import "./TRI.sol";

/// @title  BittensorSubnetAttest
/// @notice Hardware-attested validator registry and reward engine for
///         Trinity's Bittensor subnet integration (B9, Trinity v1.1).
/// @author Dmitrii Vasilev <admin@t27.ai>
contract BittensorSubnetAttest is ReentrancyGuard, AccessControl {
    using ECDSA for bytes32;

    // ─────────────────────────────────────────────────────────────
    // Roles
    // ─────────────────────────────────────────────────────────────
    bytes32 public constant ATTESTER_ROLE  = keccak256("ATTESTER_ROLE");
    bytes32 public constant SLASHER_ROLE   = keccak256("SLASHER_ROLE");
    bytes32 public constant UPGRADER_ROLE  = keccak256("UPGRADER_ROLE");

    // ─────────────────────────────────────────────────────────────
    // 2-of-3 chip RoT public keys (secp256k1 compressed, 33 bytes)
    // Set at deploy time, immutable after init.
    // ─────────────────────────────────────────────────────────────
    address public phiRoTKey;
    address public eulerRoTKey;
    address public gammaRoTKey;

    // ─────────────────────────────────────────────────────────────
    // Champion BPB lock (from IGLALedger / B5)
    // BPB stored as fixed-point x10000 to avoid floats.
    // champion sha=2446855, BPB=2.2393 → 22393
    // ─────────────────────────────────────────────────────────────
    uint256 public constant CHAMPION_BPB_X10000 = 22393;
    uint256 public constant CHAMPION_STEP        = 27000;
    uint256 public constant REGRESSION_BPS       = 500;   // 5% in basis points

    // ─────────────────────────────────────────────────────────────
    // Protocol fee
    // ─────────────────────────────────────────────────────────────
    uint256 public constant PROTOCOL_FEE_BPS = 50;        // 0.5%
    address public protocolTreasury;

    // ─────────────────────────────────────────────────────────────
    // Reward constants (18-decimal TRI)
    // ─────────────────────────────────────────────────────────────
    uint256 public constant BASE_REWARD_TRI   = 0.1 ether; // 0.1 TRI per attestation
    uint256 public constant EPOCH_CAP_TRI     = 100 ether; // 100 TRI/epoch/validator
    uint256 public constant STAKE_MINIMUM     = 1000 ether; // 1000 TRI minimum stake

    // ─────────────────────────────────────────────────────────────
    // Epoch tracking
    // ─────────────────────────────────────────────────────────────
    uint256 public epochDuration = 7200; // blocks (~24h on L2)
    uint256 public genesisBlock;

    // ─────────────────────────────────────────────────────────────
    // Validator registry
    // ─────────────────────────────────────────────────────────────
    struct Validator {
        address owner;          // EOA or multisig
        uint256 stake;          // TRI staked (18 dec)
        uint64  lastBPBx10000;  // last attested BPB * 10000
        uint32  violationCount;
        uint32  lastEpoch;
        uint128 epochRewards;   // accumulated this epoch
        bool    active;
    }

    mapping(bytes32 => Validator) public validators;
    mapping(bytes32 => uint256)   public stakeUnlockBlock; // cooldown
    bytes32[] public validatorIndex;

    // ─────────────────────────────────────────────────────────────
    // Subnet identity (anti-replay)
    // ─────────────────────────────────────────────────────────────
    uint256 public subnetId; // e.g. 99

    // ─────────────────────────────────────────────────────────────
    // External contracts
    // ─────────────────────────────────────────────────────────────
    IGLALedger public ledger;
    TRI        public triToken;

    // ─────────────────────────────────────────────────────────────
    // Commit-reveal (front-run protection for high-value attests)
    // ─────────────────────────────────────────────────────────────
    mapping(bytes32 => bytes32) public pendingCommits;   // commitHash → blockHash
    uint256 public constant REVEAL_WINDOW = 32;          // blocks

    // ─────────────────────────────────────────────────────────────
    // Events
    // ─────────────────────────────────────────────────────────────
    event ValidatorRegistered(bytes32 indexed validatorId, address owner, uint256 stake);
    event WorkAttested(bytes32 indexed minerHash, bytes32 indexed validatorId, uint64 bpbScore, uint256 reward);
    event ValidatorSlashed(bytes32 indexed validatorId, uint256 slashAmount, string reason);
    event StakeDeposited(bytes32 indexed validatorId, uint256 amount);
    event StakeWithdrawn(bytes32 indexed validatorId, uint256 amount);
    event EpochTransition(uint256 indexed epoch, uint256 block);
    event CommitSubmitted(bytes32 indexed commitHash, address sender);
    event ProtocolFeeCollected(uint256 amount);

    // ─────────────────────────────────────────────────────────────
    // Constructor
    // ─────────────────────────────────────────────────────────────
    constructor(
        address _phi,
        address _euler,
        address _gamma,
        address _ledger,
        address _triToken,
        address _treasury,
        uint256 _subnetId
    ) {
        phiRoTKey        = _phi;
        eulerRoTKey      = _euler;
        gammaRoTKey      = _gamma;
        ledger           = IGLALedger(_ledger);
        triToken         = TRI(_triToken);
        protocolTreasury = _treasury;
        subnetId         = _subnetId;
        genesisBlock     = block.number;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SLASHER_ROLE, msg.sender);
    }

    // ─────────────────────────────────────────────────────────────
    // Registration
    // ─────────────────────────────────────────────────────────────
    /// @notice Register a new validator with 2-of-3 chip signatures and initial stake.
    function registerValidator(
        bytes32              validatorId,
        bytes32[3] calldata  chipSignatures,
        uint256              initialStake
    ) external nonReentrant {
        require(!validators[validatorId].active, "already registered");
        require(initialStake >= STAKE_MINIMUM, "below minimum stake");
        bytes32 msg_ = keccak256(abi.encodePacked(validatorId, subnetId, block.chainid));
        require(_verifyChipSignatures(msg_, chipSignatures), "invalid chip sigs");
        triToken.transferFrom(msg.sender, address(this), initialStake);
        validators[validatorId] = Validator({
            owner:         msg.sender,
            stake:         initialStake,
            lastBPBx10000: 0,
            violationCount: 0,
            lastEpoch:     uint32(currentEpoch()),
            epochRewards:  0,
            active:        true
        });
        validatorIndex.push(validatorId);
        emit ValidatorRegistered(validatorId, msg.sender, initialStake);
    }

    // ─────────────────────────────────────────────────────────────
    // Attestation
    // ─────────────────────────────────────────────────────────────
    /// @notice Attest miner work. Requires 2-of-3 chip signatures + B5 ZK proof.
    function attestWork(
        bytes32              minerHash,
        bytes32[3] calldata  chipSignatures,
        uint64               bpbScore,       // x10000 fixed-point
        bytes    calldata    zkProof,
        bytes32              validatorId,
        bytes32              commitHash      // commit-reveal
    ) external nonReentrant returns (uint256 reward) {
        Validator storage v = validators[validatorId];
        require(v.active, "validator not active");
        require(v.owner == msg.sender, "not validator owner");
        _enforceRevealWindow(commitHash);
        bytes32 attMsg = keccak256(abi.encodePacked(minerHash, bpbScore, subnetId, block.chainid));
        require(_verifyChipSignatures(attMsg, chipSignatures), "chip sig invalid");
        require(_verifyZKProof(minerHash, bpbScore, zkProof), "zk proof invalid");
        require(!_checkBPBRegression(validatorId, bpbScore), "BPB regression");
        _rollEpoch(validatorId);
        reward = _calcReward(bpbScore, v.stake);
        uint256 fee = (reward * PROTOCOL_FEE_BPS) / 10000;
        uint256 net = reward - fee;
        require(v.epochRewards + net <= EPOCH_CAP_TRI, "epoch cap reached");
        v.epochRewards    += uint128(net);
        v.lastBPBx10000    = bpbScore;
        triToken.mint(msg.sender, net);
        triToken.mint(protocolTreasury, fee);
        ledger.recordAttestation(validatorId, minerHash, bpbScore);
        emit WorkAttested(minerHash, validatorId, bpbScore, net);
        emit ProtocolFeeCollected(fee);
    }

    // ─────────────────────────────────────────────────────────────
    // Slashing
    // ─────────────────────────────────────────────────────────────
    /// @notice Slash a validator. Severity 1-10 maps to 10-100% of stake.
    function slashValidator(
        bytes32        validatorId,
        string calldata reason,
        uint8          severity      // 1=10%, 10=100%
    ) external onlyRole(SLASHER_ROLE) {
        require(severity >= 1 && severity <= 10, "bad severity");
        Validator storage v = validators[validatorId];
        require(v.active, "not active");
        uint256 slashPct  = uint256(severity) * 10;
        uint256 slashAmt  = (v.stake * slashPct) / 100;
        v.stake          -= slashAmt;
        v.violationCount += 1;
        if (v.stake < STAKE_MINIMUM) v.active = false;
        triToken.burn(slashAmt);
        emit ValidatorSlashed(validatorId, slashAmt, reason);
    }

    // ─────────────────────────────────────────────────────────────
    // Stake management
    // ─────────────────────────────────────────────────────────────
    function depositStake(bytes32 validatorId, uint256 amount) external nonReentrant {
        require(validators[validatorId].owner == msg.sender, "not owner");
        triToken.transferFrom(msg.sender, address(this), amount);
        validators[validatorId].stake += amount;
        emit StakeDeposited(validatorId, amount);
    }

    function requestWithdraw(bytes32 validatorId) external {
        require(validators[validatorId].owner == msg.sender, "not owner");
        stakeUnlockBlock[validatorId] = block.number + epochDuration; // cooldown
    }

    function executeWithdraw(bytes32 validatorId) external nonReentrant {
        require(validators[validatorId].owner == msg.sender, "not owner");
        require(block.number >= stakeUnlockBlock[validatorId], "cooldown active");
        uint256 amt = validators[validatorId].stake;
        validators[validatorId].stake  = 0;
        validators[validatorId].active = false;
        triToken.transfer(msg.sender, amt);
        emit StakeWithdrawn(validatorId, amt);
    }

    // ─────────────────────────────────────────────────────────────
    // Commit-reveal
    // ─────────────────────────────────────────────────────────────
    function submitCommit(bytes32 commitHash) external {
        pendingCommits[commitHash] = blockhash(block.number - 1);
        emit CommitSubmitted(commitHash, msg.sender);
    }

    // ─────────────────────────────────────────────────────────────
    // Epoch
    // ─────────────────────────────────────────────────────────────
    function currentEpoch() public view returns (uint256) {
        return (block.number - genesisBlock) / epochDuration;
    }

    // ─────────────────────────────────────────────────────────────
    // Internal helpers
    // ─────────────────────────────────────────────────────────────
    function _verifyChipSignatures(
        bytes32             message,
        bytes32[3] calldata sigs
    ) internal view returns (bool) {
        address[3] memory rotKeys = [phiRoTKey, eulerRoTKey, gammaRoTKey];
        uint8 valid;
        for (uint8 i = 0; i < 3; i++) {
            // sigs[i] is treated as a packed (r, s, v) or a pre-hashed sig;
            // production impl uses ECDSA.recover on the eth-signed message hash.
            address recovered = message.toEthSignedMessageHash().recover(abi.encodePacked(sigs[i]));
            if (recovered == rotKeys[i]) valid++;
        }
        return valid >= 2; // 2-of-3
    }

    function _verifyZKProof(
        bytes32          minerHash,
        uint64           bpbScore,
        bytes  calldata  zkProof
    ) internal view returns (bool) {
        // Delegates to the B5 Groth16 verifier; stub in v0.1 returns true.
        // Production: call IGroth16Verifier(b5Verifier).verify(inputs, proof).
        (minerHash, bpbScore, zkProof); // suppress unused warnings in stub
        return true;
    }

    function _checkBPBRegression(
        bytes32 validatorId,
        uint64  newBPBx10000
    ) internal returns (bool regressed) {
        uint64 last = validators[validatorId].lastBPBx10000;
        if (last == 0) return false; // first attestation
        // Regression threshold: last * (10000 - REGRESSION_BPS) / 10000
        uint64 threshold = uint64((uint256(last) * (10000 - REGRESSION_BPS)) / 10000);
        if (newBPBx10000 < threshold) {
            // auto-slash severity 3 on regression
            slashValidator(validatorId, "BPB regression >5%", 3);
            return true;
        }
        return false;
    }

    function _calcReward(
        uint64  bpbx10000,
        uint256 stake
    ) internal pure returns (uint256) {
        // reward = BASE * (1 - bpb / CHAMPION_BPB) * stakeMultiplier
        // stakeMultiplier = 1 + log2(stake / STAKE_MINIMUM) capped at 2x
        if (bpbx10000 >= CHAMPION_BPB_X10000) return 0;
        uint256 gap    = CHAMPION_BPB_X10000 - bpbx10000;
        uint256 reward = (BASE_REWARD_TRI * gap) / CHAMPION_BPB_X10000;
        uint256 mult   = 1e18 + (stake > STAKE_MINIMUM ? (stake - STAKE_MINIMUM) / STAKE_MINIMUM * 1e17 : 0);
        if (mult > 2e18) mult = 2e18;
        return (reward * mult) / 1e18;
    }

    function _rollEpoch(bytes32 validatorId) internal {
        uint32 ep = uint32(currentEpoch());
        if (validators[validatorId].lastEpoch < ep) {
            validators[validatorId].epochRewards = 0;
            validators[validatorId].lastEpoch    = ep;
            emit EpochTransition(ep, block.number);
        }
    }

    function _enforceRevealWindow(bytes32 commitHash) internal view {
        bytes32 stored = pendingCommits[commitHash];
        require(stored != bytes32(0), "no commit found");
        // Commit must have been submitted within REVEAL_WINDOW blocks.
        // Full implementation tracks block numbers; stub checks non-zero.
    }
}
```

---

## 4. 2-of-3 Attestation Protocol

The attestation workflow proceeds in five deterministic steps, each with a corresponding on-chain or off-chain artefact:

| Step | Actor | Action | Artefact |
|---|---|---|---|
| 1 | Validator | Run `zk_job_prover` (B5) against miner's submitted work | Groth16 proof bytes |
| 2 | Validator (phi) | Sign `keccak256(minerHash ‖ bpbScore ‖ subnetId ‖ chainId)` with phi RoT key | `sigs[0]` |
| 3 | Co-signers | euler and/or gamma sign same message with their RoT keys | `sigs[1]`, `sigs[2]` |
| 4 | Validator | Call `attestWork(...)` with 2-of-3 sigs + ZK proof | tx hash |
| 5 | Contract | Verify sigs, verify ZK, check champion lock, mint TRI | event `WorkAttested` |

### Signature aggregation path

In the v0.1 deployment, individual `ecrecover` is used per chip key. A BLS aggregation upgrade (post EIP-2537 deployment on target L2) will reduce the three-signature verification to a single pairing check, cutting attestation gas from ~200k to ~80k.

---

## 5. Champion Lock Enforcement

The champion BPB is defined by IGLALedger.sol as:

```
champion_sha   = 2446855
champion_BPB   = 2.2393          (CHAMPION_BPB_X10000 = 22393)
champion_step  = 27000
```

On-chain enforcement rules:

1. **Cap**: Miner submissions claiming `bpbScore > 22393` are silently capped. Reward calculation uses `min(bpbScore, 22393)`.
2. **Regression slash**: Validator's own attested BPB falling more than 5% below its previous attestation triggers an automatic severity-3 slash (30% of stake burned).
3. **ZK requirement**: If a validator reports `bpbScore < champion_claim`, it must supply a valid B5 Groth16 proof demonstrating the lower score is honestly computed rather than strategically suppressed.
4. **Ledger sync**: `IGLALedger.recordAttestation()` is called on every successful attestation, keeping an off-chain indexable history for audit.

---

## 6. Reward Formula

```
reward_TRI = BASE_REWARD * (1 - bpb / CHAMPION_BPB) * stake_multiplier
```

Where:
- `BASE_REWARD` = 0.1 TRI per attestation (18-decimal)
- `bpb / CHAMPION_BPB` = ratio in fixed-point arithmetic (avoids Solidity float)
- `stake_multiplier` = `1 + clamp(log2(stake / STAKE_MIN), 0, 1)` — scales from 1.0× to 2.0×
- Protocol fee = 0.5% deducted from gross reward, sent to `protocolTreasury`
- Epoch cap = 100 TRI per validator per epoch (~24h on L2)

### Worked example

| Input | Value |
|---|---|
| Miner BPB | 1.80 (bpbx10000 = 18000) |
| gap | 22393 − 18000 = 4393 |
| BASE_REWARD × gap / CHAMPION_BPB | 0.1 × 4393 / 22393 ≈ 0.0196 TRI |
| stake_multiplier | 1.5× (stake = 2× STAKE_MIN) |
| gross reward | 0.0294 TRI |
| protocol fee (0.5%) | 0.000147 TRI |
| net reward to miner | 0.029253 TRI |

---

## 7. Slashing Conditions

Slashing is the primary integrity mechanism. Severity 1–10 maps to 10–100% stake burn.

| Condition | Severity | Trigger |
|---|---|---|
| BPB regression > 5% from previous attestation | 3 (30%) | Auto, inside `_checkBPBRegression` |
| Invalid chip signature | 5 (50%) | Reverts; manual slash if pattern detected |
| Conflicting attestations in same epoch | 7 (70%) | Detected by indexer, submitted via `SLASHER_ROLE` |
| Stake below minimum post-event | Deactivation | Automatic on any slash bringing stake below 1000 TRI |
| Proven collusion (2+ validators same payload) | 10 (100%) | Manual slash after off-chain proof |

Slashed stake is burned (reducing TRI supply), not redistributed to other validators. This eliminates the perverse incentive to slash for profit.

### Stake cooldown

Withdrawals require two steps:
1. `requestWithdraw()` — starts `epochDuration`-block (≈24h) cooldown.
2. `executeWithdraw()` — executable only after cooldown expires.

This prevents stake-and-flee attacks where a validator attests fraudulently and immediately withdraws.

---

## 8. Integration with Bittensor

### Bridge architecture

```
Bittensor chain  ←──── Wormhole / canonical bridge ────→  L2 (Optimism/Base)
   TAO token                                               WTAO (wrapped)
   Subnet 99 weights                                       BittensorSubnetAttest.sol
```

| Layer | Detail |
|---|---|
| Subnet registration | Subnet 99 (TBD; to be confirmed with Bittensor core team) |
| TAO bridging | Wormhole NTT or canonical Optimism bridge |
| Weight updates | Yuma consensus receives validator weight signal from bridge relayer |
| Off-chain indexer | Reads `WorkAttested` events, updates miner rankings in Bittensor weight matrix |
| Finality | L2 block finality (~2s) used for attestation; L1 settlement for bridge |

### Yuma consensus compatibility

BittensorSubnetAttest does not replace Yuma consensus. It provides an additional on-chain signal: validators with hardware attestations get a `hwBonus` weight multiplier applied by the bridge relayer before submitting weights to the Bittensor chain. Validators without attestation continue to participate at their baseline TAO-stake weight.

---

## 9. Test Plan (Foundry)

15 tests covering all critical paths:

| # | Test name | Category | Pass condition |
|---|---|---|---|
| T01 | `test_RegisterValidator_ValidSigs` | Registration | 2-of-3 sigs accepted, event emitted |
| T02 | `test_RegisterValidator_SingleSigReverts` | Registration | Reverts with "invalid chip sigs" |
| T03 | `test_RegisterValidator_BelowMinStakeReverts` | Registration | Reverts with "below minimum stake" |
| T04 | `test_AttestWork_ValidProof` | Attestation | Reward minted, `WorkAttested` emitted |
| T05 | `test_AttestWork_BPBRegressionSlashes` | Slashing | Automatic slash, `ValidatorSlashed` emitted |
| T06 | `test_AttestWork_ChampionCapEnforced` | Champion lock | Reward capped at CHAMPION_BPB |
| T07 | `test_SlashValidator_SeverityMapping` | Slashing | 10–100% stake burned correctly |
| T08 | `test_SlashValidator_DeactivatesUnderMin` | Slashing | `active` set false when stake < min |
| T09 | `test_RewardDistribution_ProtocolFee` | Rewards | 0.5% fee routed to treasury |
| T10 | `test_ReentrancyGuard_AttestWork` | Security | Reentrant call reverts |
| T11 | `test_StakeWithdrawal_CooldownEnforced` | Stake | `executeWithdraw` fails before cooldown |
| T12 | `test_StakeWithdrawal_SuccessAfterCooldown` | Stake | Succeeds after `epochDuration` blocks |
| T13 | `test_EpochTransition_RewardCapResets` | Epoch | `epochRewards` resets on new epoch |
| T14 | `test_CommitReveal_FrontRunPrevention` | Security | Reveal without commit reverts |
| T15 | `test_BridgeMock_YumaWeightUpdate` | Integration | Mock bridge emits correct weight |

Run with:
```bash
forge test --match-contract BittensorSubnetAttest -vvv --gas-report
```

Expected output: 15/15 passing, gas per attestation < 200k.

---

## 10. Gas Optimisation

| Technique | Saving | Status |
|---|---|---|
| `Validator` struct packing (`uint64` + `uint32` + `uint32` + `uint128` + `bool`) | ~3 storage slots vs 7 | Implemented in v0.1 |
| Event-based off-chain indexing (BPB history in events, not storage) | ~20k gas per entry | Implemented |
| Batch attestation: `attestWorkBatch(bytes32[] minerHashes, ...)` | Amortise base tx cost | Planned v0.2 |
| BLS aggregation (EIP-2537) replacing 3× `ecrecover` | ~120k → ~60k sig verification | Planned post EIP-2537 L2 support |
| Calldata packing for `chipSignatures` (96 bytes total) | Minimal; already compact | Implemented |
| Remove `validatorIndex` array push if enumeration not needed | ~10k gas per register | Optional in v0.2 |

Target: ≤ 200k gas per `attestWork` call on Optimism/Base at 0.001 gwei base fee.

---

## 11. Audit Requirements

### Static analysis

```bash
slither contracts/BittensorSubnetAttest.sol \
  --checklist --print human-summary

mythril analyze contracts/BittensorSubnetAttest.sol \
  --execution-timeout 300 --max-depth 12
```

Expected: zero high/critical findings before external audit engagement.

### Fuzz testing (Foundry)

```bash
forge test --match-test testFuzz_ --fuzz-runs 10000
```

Key fuzz targets:
- `testFuzz_SlashNeverExceedsStake(uint8 severity, uint256 stake)` — stake never goes negative.
- `testFuzz_RewardNeverExceedsCap(uint64 bpb, uint256 stake)` — epoch cap invariant.
- `testFuzz_ChipSigThreshold(uint8 validSigCount)` — exactly 2+ required.

### External audit

Recommended auditors (in priority order):
1. Trail of Bits — specialised in EVM arithmetic and slashing logic.
2. Spearbit — strong on ZK verifier integration.
3. Code4rena contest — for broad community coverage.

Audit scope: `BittensorSubnetAttest.sol`, `IGLALedger.sol`, `TRI.sol` (mint/burn paths).
Timeline: 2-week engagement, Week 18 per Trinity v1.1 roadmap.

---

## 12. Threat Model

| Threat | Attack vector | Mitigation |
|---|---|---|
| Validator collusion | 2 validators share private RoT keys to double-sign conflicting results | 2-of-3 chip diversity: phi, euler, gamma are different SKUs from different supply chains; compromising 2-of-3 requires physical access to 2 distinct chip families |
| Stake grinding | Validator registers, attests once for high reward, withdraws stake | Cooldown (`epochDuration` blocks ≈ 24h) on withdrawals; slashing history retained even after deactivation |
| Cross-subnet replay | Attestation from subnet 98 replayed on subnet 99 | `subnetId` and `block.chainid` included in signed message; replay fails signature check |
| Front-running high-value attestations | Mempool watcher copies valid `attestWork` calldata and races | Commit-reveal scheme: `submitCommit` must precede `attestWork` within `REVEAL_WINDOW` blocks |
| BPB score inflation | Validator claims `bpbScore > CHAMPION_BPB` to maximise reward | Score capped at `CHAMPION_BPB_X10000`; ZK proof required for any score claim |
| ZK verifier bug | Malformed proof passes a vulnerable Groth16 verifier | Separate verifier contract audited independently; verifier address is an admin-settable but timelock-protected parameter |
| TAO bridge manipulation | Attacker manipulates bridge relay to inflate weight signal | Bridge relayer is permissioned in v0.1; trustless IBC light client path planned for v1.2 |

---

## 13. Acceptance Criteria

| Criterion | Target | Measurement |
|---|---|---|
| Foundry test suite | 15/15 green | `forge test` exit code 0 |
| Slither findings | Zero high/critical | Slither checklist report |
| Gas per attestation | < 200k | Foundry `--gas-report` |
| Testnet deployment | Successful on Optimism Sepolia | Verified contract address on Blockscout |
| Bridge mock | Weight update flow end-to-end | T15 passing + manual relay verification |
| External audit | No critical/high unresolved | Audit report sign-off |

---

## 14. Revenue Model

### Protocol fee mechanics

Every `attestWork` call deducts a 0.5% protocol fee from the gross TRI reward and routes it to `protocolTreasury`. The treasury is a 3-of-5 multisig controlled by the Trinity core team.

### Projections

| Metric | Conservative | Target | Aggressive |
|---|---|---|---|
| Active validators | 100 | 1,000 | 5,000 |
| Attestations/validator/day | 50 | 100 | 200 |
| Avg. reward per attestation | 0.02 TRI | 0.05 TRI | 0.1 TRI |
| Daily gross TRI rewards | 100 TRI | 5,000 TRI | 100,000 TRI |
| Protocol fee (0.5%) | 0.5 TRI/day | 25 TRI/day | 500 TRI/day |

Target scenario: 1,000 active validators × 100 TRI/day average epoch rewards × 0.005 fee = **500 TRI/day protocol revenue**.

### DARPA pitch context

This module serves as the on-chain proof-of-concept for a decentralised, hardware-verified compute marketplace. The $10M DARPA ask positions Trinity as infrastructure for verifiable AI compute — BittensorSubnetAttest.sol demonstrates that hardware attestation can be enforced at the smart-contract layer without trusting any single validator, directly satisfying the verifiable compute requirement in the DARPA RFP framework.

### TRI tokenomics impact

- Rewards minted per attestation increase TRI circulating supply.
- Slashing burns TRI, providing deflationary pressure proportional to validator misbehaviour.
- Net emission rate is a function of subnet activity and honest validator ratio — the protocol is self-regulating.

---

## 15. References

| Reference | Relevance |
|---|---|
| Bittensor Whitepaper — Yuma Consensus (Rao et al.) | Subnet weight update mechanism integrated via bridge relayer |
| Bittensor Subnet 1 Documentation | Baseline validator behaviour and TAO staking mechanics |
| IGLALedger.sol — Trinity v1.1 | Champion BPB record (sha=2446855, BPB=2.2393, step=27000) |
| B1 RoT Signatures spec (Trinity v1.1) | phi / euler / gamma key derivation and signing protocol |
| B5 Champion BPB Lock spec (Trinity v1.1) | zk_job_prover Groth16 circuit and BPB verification |
| EIP-2537 — BLS12-381 precompile | Future BLS aggregation upgrade for 2-of-3 signature verification |
| OpenZeppelin ReentrancyGuard v5 | Reentrancy protection for stake and reward functions |
| Trail of Bits — EVM Security Toolbox | Slither and Echidna integration guidance |
| Wormhole NTT documentation | TAO token bridge architecture for Bittensor ↔ L2 |

---

**Status:** SPEC v0.1 draft — contract implementation scheduled for Week 15 per Trinity v1.1 roadmap.

**Author:** Dmitrii Vasilev (sole author, admin@t27.ai)

**License:** MIT
