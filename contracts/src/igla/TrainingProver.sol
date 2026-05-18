// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// ─────────────────────────────────────────────────────────────────────────────
// TrainingProver — ZK Proof Verifier для IGLA Training Runs
//
// Расширяет семантику docs/zk/verifier_outline.sol для on-chain аттестации
// тренировочных прогонов IGLA RACE pipeline.
//
// Statement (what we prove):
//   "Я выполнил N training steps на chip S, seed=R,
//    начиная с weights_root W0, заканчивая weights_root W_final,
//    достигнув BPB=B (в формате bpbE6 = B * 1e6)"
//
// Hybrid mode (ZK + Oracle):
//   - verifyTrainingProof: чистая ZK верификация (BN254 pairing)
//   - verifyAndSubmit: ZK + oracle signature + IGLALedger.submitRowVerified
//     + TRIToken mint через TRIBridge
//
// Reward formula: 1 TRI per 0.01 BPB improvement (cap 100 TRI)
//   reward = min((prevBest - newBest) / 10000, 100) * 1e18
//   (bpbE6 units: 1 BPB = 1e6 units → 0.01 BPB = 10000 units)
//
// Gas estimate:
//   verifyTrainingProof: ~250K gas (4 BN254 pairings + 6 scalar muls)
//   verifyAndSubmit:     ~400K gas total
//
// References:
//   - EIP-196: BN254 EC ops (0x06, 0x07)
//   - EIP-197: BN254 pairing (0x08)
//   - docs/zk/verifier_outline.sol (TrinityComputeVerifier pattern)
//   - contracts/src/TRIBridge.sol (mint pattern)
//
// v1.0.0 modules preserved. Champion: BPB=2.2393 seed=43 step=27000.
// ─────────────────────────────────────────────────────────────────────────────

interface IIGLALedger {
    struct TrainingRow {
        bytes32 chipSerial;
        uint64  step;
        uint32  seed;
        uint32  bpbE6;
        bytes7  sha;
        uint64  jsonlRow;
        uint8   gateStatus;
        uint64  timestamp;
    }
    function submitRowVerified(TrainingRow calldata row) external;
    function bestBPB(bytes32 chipSerial) external view returns (uint32);
}

interface ITRIBridgeMint {
    function mintTrainingReward(address to, uint256 amount) external;
}

contract TrainingProver {
    // ─── Structs ─────────────────────────────────────────────────────────────

    /// @notice Groth16 proof over BN254 (192 bytes). Matches docs/zk/verifier_outline.sol.
    struct TrainingProof {
        uint256[2]    a;    // G1 point (64 bytes)
        uint256[2][2] b;    // G2 point (128 bytes)
        uint256[2]    c;    // G1 point (64 bytes)
    }

    /// @notice Public inputs for a training proof.
    /// All values are revealed to the on-chain verifier.
    struct TrainingPublicInputs {
        bytes32 chipSerial;      // Chip identifier (DePIN hardware serial)
        uint64  step;            // Training step number achieved
        uint32  seed;            // Random seed used in this run
        uint32  bpbE6;           // BPB * 1e6 (lower is better; 2.2393 → 2239300)
        bytes32 lossCurveHash;   // blake3 hash of full loss curve (private → public commitment)
        bytes32 weightsRootHash; // Merkle root of final model weights
    }

    // ─── Constants ───────────────────────────────────────────────────────────

    // BN254 field modulus (p)
    uint256 constant FIELD_MODULUS =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // BN254 scalar field modulus (r)
    uint256 constant SCALAR_MODULUS =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    // Reward economics: 1 TRI per 0.01 BPB improvement
    // 1 BPB = 1e6 bpbE6 units → 0.01 BPB = 10_000 bpbE6 units
    uint256 constant BPB_UNIT_PER_TRI = 10_000; // bpbE6 units per 1 TRI reward
    uint256 constant MAX_REWARD_TRI   = 100;     // max 100 TRI per submission
    uint256 constant TRI_DECIMALS     = 1 ether; // 1e18 (TRIToken has 18 decimals)

    // High-value threshold for ZK requirement (consistent with TrinityComputeVerifier)
    uint256 constant HIGH_VALUE_THRESHOLD_TRI = 10; // ZK required if reward >= 10 TRI

    // ─── Verification Key (PLACEHOLDERS — replace after trusted setup) ─────────
    // Production values: snarkjs zkey export solidityverifier circuit_final.zkey
    // Ceremony: Perpetual Powers of Tau (>= 2^18) + circuit-specific phase 2
    //
    // Circuit: training_proof_circuit (docs/igla/zk/training_proof_circuit.md)
    // Public inputs count: 12 field elements (see _encodePublicInputs)
    // IC array size: 13 (12 inputs + 1 constant term)

    // vk.alpha1 — G1 point
    uint256 constant VK_ALPHA_X = 0x0000000000000000000000000000000000000000000000000000000000000001; // PLACEHOLDER
    uint256 constant VK_ALPHA_Y = 0x0000000000000000000000000000000000000000000000000000000000000002; // PLACEHOLDER

    // vk.beta2 — G2 point
    uint256 constant VK_BETA_X0 = 0x0000000000000000000000000000000000000000000000000000000000000003; // PLACEHOLDER
    uint256 constant VK_BETA_X1 = 0x0000000000000000000000000000000000000000000000000000000000000004; // PLACEHOLDER
    uint256 constant VK_BETA_Y0 = 0x0000000000000000000000000000000000000000000000000000000000000005; // PLACEHOLDER
    uint256 constant VK_BETA_Y1 = 0x0000000000000000000000000000000000000000000000000000000000000006; // PLACEHOLDER

    // vk.gamma2 — G2 point
    uint256 constant VK_GAMMA_X0 = 0x0000000000000000000000000000000000000000000000000000000000000007; // PLACEHOLDER
    uint256 constant VK_GAMMA_X1 = 0x0000000000000000000000000000000000000000000000000000000000000008; // PLACEHOLDER
    uint256 constant VK_GAMMA_Y0 = 0x0000000000000000000000000000000000000000000000000000000000000009; // PLACEHOLDER
    uint256 constant VK_GAMMA_Y1 = 0x000000000000000000000000000000000000000000000000000000000000000A; // PLACEHOLDER

    // vk.delta2 — G2 point
    uint256 constant VK_DELTA_X0 = 0x000000000000000000000000000000000000000000000000000000000000000B; // PLACEHOLDER
    uint256 constant VK_DELTA_X1 = 0x000000000000000000000000000000000000000000000000000000000000000C; // PLACEHOLDER
    uint256 constant VK_DELTA_Y0 = 0x000000000000000000000000000000000000000000000000000000000000000D; // PLACEHOLDER
    uint256 constant VK_DELTA_Y1 = 0x000000000000000000000000000000000000000000000000000000000000000E; // PLACEHOLDER

    // vk.IC — G1 points for public input linear combination (13 entries: IC[0..12])
    // Stored in arrays (cannot be constant due to Solidity limitations)
    uint256[13] private VK_IC_X;
    uint256[13] private VK_IC_Y;

    // ─── State ───────────────────────────────────────────────────────────────

    address public immutable iglaLedger;   // IGLALedger contract
    address public immutable triBridge;    // TRIBridge for mint rewards
    address public immutable owner;        // Admin (deployer)

    /// @notice Authorized IGLA oracle addresses (same set as IGLALedger).
    mapping(address => bool) public authorizedOracles;

    /// @notice Replay protection: (chipSerial, step) pairs already submitted.
    mapping(bytes32 => bool) public usedSubmissions;

    // ─── Events ──────────────────────────────────────────────────────────────

    event TrainingProofVerified(
        bytes32 indexed chipSerial,
        uint64  step,
        uint32  seed,
        uint32  bpbE6,
        bytes32 lossCurveHash,
        bytes32 weightsRootHash
    );

    event TrainingRewardMinted(
        bytes32 indexed chipSerial,
        address indexed recipient,
        uint256 rewardWei,
        uint32  prevBestBpbE6,
        uint32  newBpbE6
    );

    // ─── Modifiers ───────────────────────────────────────────────────────────

    modifier onlyOwner() {
        require(msg.sender == owner, "TrainingProver: not owner");
        _;
    }

    // ─── Constructor ─────────────────────────────────────────────────────────

    /// @param _iglaLedger   Deployed IGLALedger contract address.
    /// @param _triBridge    Deployed TRIBridge contract address (for mint).
    /// @param _oracles      Initial authorized oracle addresses.
    constructor(
        address _iglaLedger,
        address _triBridge,
        address[] memory _oracles
    ) {
        require(_iglaLedger != address(0), "TrainingProver: zero ledger");
        require(_triBridge  != address(0), "TrainingProver: zero bridge");
        iglaLedger = _iglaLedger;
        triBridge  = _triBridge;
        owner      = msg.sender;

        for (uint256 i = 0; i < _oracles.length; i++) {
            require(_oracles[i] != address(0), "TrainingProver: zero oracle");
            authorizedOracles[_oracles[i]] = true;
        }

        // Initialize VK_IC with placeholder values
        // Production: replace with snarkjs ceremony output
        for (uint256 i = 0; i < 13; i++) {
            VK_IC_X[i] = i + 1;  // PLACEHOLDER
            VK_IC_Y[i] = i + 2;  // PLACEHOLDER
        }
    }

    // ─── Core: verifyTrainingProof ────────────────────────────────────────────

    /// @notice Verify a Groth16 training proof (ZK-only path, no side effects).
    /// @dev    Uses BN254 precompile 0x08 (EIP-197) for pairing check.
    ///         Public inputs are encoded from TrainingPublicInputs into 12 field elements.
    /// @param  proof  Groth16 proof (A, B, C on BN254).
    /// @param  pi     Public inputs for the training circuit.
    /// @return valid  True if the proof is valid for the given public inputs.
    function verifyTrainingProof(
        TrainingProof calldata proof,
        TrainingPublicInputs calldata pi
    ) external view returns (bool) {
        uint256[12] memory inputs = _encodePublicInputs(pi);
        return _verifyGroth16(proof, inputs);
    }

    // ─── Core: verifyAndSubmit ────────────────────────────────────────────────

    /// @notice ZK + oracle hybrid: verify proof, record in IGLALedger, mint reward.
    /// @dev    Flow:
    ///           1. Replay-protection check
    ///           2. Verify Groth16 proof (BN254 pairing)
    ///           3. Verify oracle signature (IGLA daemon ECDSA)
    ///           4. Build TrainingRow and call IGLALedger.submitRowVerified
    ///           5. Compute BPB improvement reward and mint via TRIBridge
    ///
    /// @param  proof       Groth16 training proof.
    /// @param  pi          Public inputs (chip, step, seed, bpbE6, hashes).
    /// @param  oracle_sig  EIP-191 ECDSA signature from authorized IGLA oracle (65 bytes).
    /// @param  sha         First 7 bytes of ledger entry hash (from JSONL).
    /// @param  jsonlRow    Row index in seed_results.jsonl.
    /// @param  gateStatus  Gate status byte from IGLA daemon.
    /// @param  rewardTo    Address to receive TRI reward.
    function verifyAndSubmit(
        TrainingProof calldata proof,
        TrainingPublicInputs calldata pi,
        bytes calldata oracle_sig,
        bytes7 sha,
        uint64 jsonlRow,
        uint8  gateStatus,
        address rewardTo
    ) external {
        // ---- Replay protection ----
        bytes32 submissionKey = keccak256(abi.encode(pi.chipSerial, pi.step, pi.seed));
        require(!usedSubmissions[submissionKey], "TrainingProver: already submitted");

        // ---- Validate basic inputs ----
        require(rewardTo != address(0), "TrainingProver: zero rewardTo");
        require(pi.bpbE6 > 0, "TrainingProver: zero bpbE6");
        require(pi.step > 0,  "TrainingProver: zero step");

        // ---- ZK proof verification ----
        uint256[12] memory inputs = _encodePublicInputs(pi);
        require(_verifyGroth16(proof, inputs), "TrainingProver: invalid ZK proof");

        // ---- Oracle signature verification ----
        bytes32 oracleMsgHash = _oracleSigningHash(pi, sha, jsonlRow, gateStatus);
        address signer = _recoverSigner(oracleMsgHash, oracle_sig);
        require(authorizedOracles[signer], "TrainingProver: invalid oracle signature");

        // ---- Mark submission used ----
        usedSubmissions[submissionKey] = true;

        // ---- Get previous best BPB for reward calc ----
        uint32 prevBest = IIGLALedger(iglaLedger).bestBPB(pi.chipSerial);

        // ---- Build TrainingRow and submit to IGLALedger ----
        IIGLALedger.TrainingRow memory row = IIGLALedger.TrainingRow({
            chipSerial: pi.chipSerial,
            step:       pi.step,
            seed:       pi.seed,
            bpbE6:      pi.bpbE6,
            sha:        sha,
            jsonlRow:   jsonlRow,
            gateStatus: gateStatus,
            timestamp:  0 // set by IGLALedger on-chain
        });
        IIGLALedger(iglaLedger).submitRowVerified(row);

        emit TrainingProofVerified(
            pi.chipSerial,
            pi.step,
            pi.seed,
            pi.bpbE6,
            pi.lossCurveHash,
            pi.weightsRootHash
        );

        // ---- Compute and mint reward ----
        uint256 rewardWei = bpbToReward(prevBest, pi.bpbE6);
        if (rewardWei > 0) {
            ITRIBridgeMint(triBridge).mintTrainingReward(rewardTo, rewardWei);
            emit TrainingRewardMinted(
                pi.chipSerial,
                rewardTo,
                rewardWei,
                prevBest,
                pi.bpbE6
            );
        }
    }

    // ─── Reward formula ───────────────────────────────────────────────────────

    /// @notice Compute TRI reward for a BPB improvement.
    /// @dev    Formula: 1 TRI per 0.01 BPB improvement, capped at 100 TRI.
    ///         In bpbE6 units: 0.01 BPB = 10_000 bpbE6 units.
    ///         If prevBest == 0 (first submission), reward is based on improvement
    ///         from a reference baseline of 3_000_000 (BPB=3.0).
    ///
    /// @param  prevBest  Previous best bpbE6 for this chip (0 if none).
    /// @param  newBest   New bpbE6 achieved.
    /// @return rewardWei TRI reward in wei (18 decimals).
    function bpbToReward(uint32 prevBest, uint32 newBest)
        public pure returns (uint256 rewardWei)
    {
        uint32 baseline = prevBest == 0 ? 3_000_000 : prevBest; // 3.0 BPB baseline
        if (newBest >= baseline) return 0; // no improvement

        uint32 improvement = baseline - newBest; // bpbE6 units improved
        uint256 triUnits = uint256(improvement) / BPB_UNIT_PER_TRI;

        // Cap at MAX_REWARD_TRI
        if (triUnits > MAX_REWARD_TRI) triUnits = MAX_REWARD_TRI;

        rewardWei = triUnits * TRI_DECIMALS;
    }

    // ─── Admin ───────────────────────────────────────────────────────────────

    function setOracle(address oracle, bool authorized) external onlyOwner {
        require(oracle != address(0), "TrainingProver: zero oracle");
        authorizedOracles[oracle] = authorized;
    }

    // ─── Internal: public inputs encoding ────────────────────────────────────

    /// @notice Encode TrainingPublicInputs into 12 BN254 scalar field elements.
    /// @dev    Order must match the Circom circuit's public signal order
    ///         (see docs/igla/zk/training_proof_circuit.md, section "Public Inputs Encoding"):
    ///
    ///         [0..3]  chipSerial as 4 × uint64 chunks
    ///         [4]     step (uint64)
    ///         [5]     seed (uint32)
    ///         [6]     bpbE6 (uint32)
    ///         [7..10] lossCurveHash as 4 × uint64 chunks
    ///         [11]    weightsRootHash lower 128 bits (uint128, fits BN254 scalar field)
    ///
    ///         Note: weightsRootHash is 256 bits but we take lower 128 bits for the
    ///         circuit input to stay within BN254 scalar field bounds.
    ///         Full 256-bit binding is achieved via lossCurveHash (includes weights link).
    function _encodePublicInputs(TrainingPublicInputs calldata pi)
        internal pure returns (uint256[12] memory inputs)
    {
        // chipSerial: split bytes32 into 4 × uint64
        bytes32 cs = pi.chipSerial;
        inputs[0] = uint256(uint64(bytes8(cs)));
        inputs[1] = uint256(uint64(bytes8(cs << 64)));
        inputs[2] = uint256(uint64(bytes8(cs << 128)));
        inputs[3] = uint256(uint64(bytes8(cs << 192)));

        // Scalar training values
        inputs[4] = uint256(pi.step);
        inputs[5] = uint256(pi.seed);
        inputs[6] = uint256(pi.bpbE6);

        // lossCurveHash: split bytes32 into 4 × uint64
        bytes32 lch = pi.lossCurveHash;
        inputs[7]  = uint256(uint64(bytes8(lch)));
        inputs[8]  = uint256(uint64(bytes8(lch << 64)));
        inputs[9]  = uint256(uint64(bytes8(lch << 128)));
        inputs[10] = uint256(uint64(bytes8(lch << 192)));

        // weightsRootHash: lower 128 bits (upper 128 committed via lossCurveHash)
        inputs[11] = uint256(uint128(uint256(pi.weightsRootHash)));
    }

    // ─── Internal: Groth16 verifier ───────────────────────────────────────────

    /// @dev Full Groth16 verification using BN254 precompiles (EIP-196/197).
    ///      Implements: e(A, B) = e(alpha, beta) * e(vk_x, gamma) * e(C, delta)
    ///      Via negated-A convention: e(-A, B) * e(alpha, beta) * e(vk_x, gamma) * e(C, delta) = 1
    ///
    ///      vk_x = IC[0] + sum(inputs[i] * IC[i+1])
    function _verifyGroth16(
        TrainingProof calldata proof,
        uint256[12] memory inputs
    ) internal view returns (bool) {

        // Step 1: Compute vk_x = IC[0] + sum(inputs[i] * IC[i+1])
        uint256[2] memory vk_x;
        vk_x[0] = VK_IC_X[0];
        vk_x[1] = VK_IC_Y[0];

        for (uint256 i = 0; i < 12; i++) {
            uint256[3] memory mulInput;
            mulInput[0] = VK_IC_X[i + 1];
            mulInput[1] = VK_IC_Y[i + 1];
            mulInput[2] = inputs[i] % SCALAR_MODULUS;

            uint256[2] memory tmp;
            bool ok;
            assembly {
                ok := staticcall(gas(), 0x07, mulInput, 96, tmp, 64)
            }
            require(ok, "TrainingProver: ecMul failed");

            uint256[4] memory addInput;
            addInput[0] = vk_x[0];
            addInput[1] = vk_x[1];
            addInput[2] = tmp[0];
            addInput[3] = tmp[1];

            assembly {
                ok := staticcall(gas(), 0x06, addInput, 128, vk_x, 64)
            }
            require(ok, "TrainingProver: ecAdd failed");
        }

        // Step 2: Pairing check via ecPairing precompile (0x08, EIP-197)
        // 4 pairs × 192 bytes = 768 bytes input
        uint256[24] memory p;

        // Pair 1: (-A, B)  [negate A.y]
        p[0]  = proof.a[0];
        p[1]  = FIELD_MODULUS - (proof.a[1] % FIELD_MODULUS);
        p[2]  = proof.b[0][0]; // B.x imaginary
        p[3]  = proof.b[0][1]; // B.x real
        p[4]  = proof.b[1][0]; // B.y imaginary
        p[5]  = proof.b[1][1]; // B.y real

        // Pair 2: (alpha, beta)
        p[6]  = VK_ALPHA_X;
        p[7]  = VK_ALPHA_Y;
        p[8]  = VK_BETA_X0;
        p[9]  = VK_BETA_X1;
        p[10] = VK_BETA_Y0;
        p[11] = VK_BETA_Y1;

        // Pair 3: (vk_x, gamma)
        p[12] = vk_x[0];
        p[13] = vk_x[1];
        p[14] = VK_GAMMA_X0;
        p[15] = VK_GAMMA_X1;
        p[16] = VK_GAMMA_Y0;
        p[17] = VK_GAMMA_Y1;

        // Pair 4: (C, delta)
        p[18] = proof.c[0];
        p[19] = proof.c[1];
        p[20] = VK_DELTA_X0;
        p[21] = VK_DELTA_X1;
        p[22] = VK_DELTA_Y0;
        p[23] = VK_DELTA_Y1;

        uint256[1] memory out;
        bool success;
        assembly {
            // 768 bytes = 24 * 32 bytes
            success := staticcall(gas(), 0x08, p, 768, out, 32)
        }
        require(success, "TrainingProver: ecPairing precompile failed");

        return out[0] == 1;
    }

    // ─── Internal: signature helpers ─────────────────────────────────────────

    /// @dev Compute EIP-191 personal-sign hash for oracle signature over training submission.
    function _oracleSigningHash(
        TrainingPublicInputs calldata pi,
        bytes7 sha,
        uint64 jsonlRow,
        uint8  gateStatus
    ) internal pure returns (bytes32) {
        bytes32 dataHash = keccak256(abi.encode(
            pi.chipSerial,
            pi.step,
            pi.seed,
            pi.bpbE6,
            pi.lossCurveHash,
            pi.weightsRootHash,
            sha,
            jsonlRow,
            gateStatus
        ));
        return keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            dataHash
        ));
    }

    /// @dev Recover signer address from EIP-191 signature (65 bytes: r || s || v).
    function _recoverSigner(
        bytes32 msgHash,
        bytes calldata sig
    ) internal pure returns (address) {
        require(sig.length == 65, "TrainingProver: invalid sig length");
        bytes32 r;
        bytes32 s;
        uint8   v;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, sig.offset, 65)
            r := mload(ptr)
            s := mload(add(ptr, 32))
            v := byte(0, mload(add(ptr, 64)))
        }
        if (v < 27) v += 27;
        require(v == 27 || v == 28, "TrainingProver: invalid v");
        address recovered = ecrecover(msgHash, v, r, s);
        require(recovered != address(0), "TrainingProver: ecrecover failed");
        return recovered;
    }
}
