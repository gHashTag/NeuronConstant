// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// ─────────────────────────────────────────────────────────────────────────────
// MofNTrainingAttest — 2-of-3 Multi-Chip Attestation for IGLA Training Rows
//
// Mirrors the hardware tri_mofn_attest.v module (DePIN #3):
//   common/depin/v2/tri_mofn_attest.v (commit fb0e385)
//
// Semantics:
//   - Each chip-owner (or their operator key) can submit a single attestation
//     for a given rowHash via attestRow()
//   - Once 2 of 3 registered chip-owners have attested, the row is considered
//     "attested" and IGLALedger.submitRow will accept it
//   - Quorum threshold is configurable (default: 2-of-3, consistent with TRIBridge)
//
// Integration:
//   1. Deploy MofNTrainingAttest with chipOwners[3] and quorum=2
//   2. Call IGLALedger.setAttestModule(address(this))
//   3. Before submitting to IGLALedger, each chip-owner calls attestRow(rowHash, sig)
//   4. After >= quorum attestations, submitRow proceeds
//
// Signature:
//   Each chip-owner signs: keccak256(abi.encodePacked("\x19...\n32", rowHash))
//   i.e. EIP-191 personal-sign of rowHash
//
// v1.0.0 modules preserved. R-SI-1 N/A (Solidity). DePIN #3 mirror.
// ─────────────────────────────────────────────────────────────────────────────

contract MofNTrainingAttest {
    // ─── State ───────────────────────────────────────────────────────────────

    /// @notice Number of attestations required to approve a row (default 2).
    uint8 public immutable quorumThreshold;

    /// @notice Total number of registered chip-owners (default 3).
    uint8 public immutable chipOwnerCount;

    /// @notice Registered chip-owner keys (indexed 0..chipOwnerCount-1).
    address[3] public chipOwners;

    /// @notice Per-rowHash: bitmap of which chip-owners have attested.
    ///         bit i = 1 → chipOwners[i] has attested this row.
    mapping(bytes32 => uint8) public attestBitmap;

    /// @notice Per-rowHash: count of attestations received.
    mapping(bytes32 => uint8) public attestCount;

    /// @notice Per-rowHash: whether quorum has been reached (locked).
    mapping(bytes32 => bool) public quorumReached;

    /// @notice Owner (deployer) — can update chip-owner list.
    address public immutable owner;

    // ─── Events ──────────────────────────────────────────────────────────────

    /// @notice Emitted when a chip-owner submits an attestation.
    event RowAttested(
        bytes32 indexed rowHash,
        address indexed attester,
        uint8   ownerIndex,
        uint8   attestCountNow
    );

    /// @notice Emitted when quorum (M-of-N) is first reached for a row.
    event QuorumReached(
        bytes32 indexed rowHash,
        uint8   quorum,
        uint8   total
    );

    // ─── Modifiers ───────────────────────────────────────────────────────────

    modifier onlyOwner() {
        require(msg.sender == owner, "MofNAttest: not owner");
        _;
    }

    // ─── Constructor ─────────────────────────────────────────────────────────

    /// @param _chipOwners    Array of exactly 3 chip-owner addresses.
    /// @param _quorumThreshold  Minimum attestations required (must be <= 3).
    constructor(address[3] memory _chipOwners, uint8 _quorumThreshold) {
        require(_quorumThreshold >= 1 && _quorumThreshold <= 3,
                "MofNAttest: invalid quorum");
        for (uint8 i = 0; i < 3; i++) {
            require(_chipOwners[i] != address(0), "MofNAttest: zero chipOwner");
            // Uniqueness check
            for (uint8 j = 0; j < i; j++) {
                require(_chipOwners[i] != _chipOwners[j], "MofNAttest: duplicate chipOwner");
            }
        }
        chipOwners       = _chipOwners;
        quorumThreshold  = _quorumThreshold;
        chipOwnerCount   = 3;
        owner            = msg.sender;
    }

    // ─── Core: attestRow ─────────────────────────────────────────────────────

    /// @notice Submit a chip-owner attestation for a training row hash.
    /// @dev    Verifies ECDSA signature over EIP-191 personal-sign of rowHash.
    ///         Each chip-owner may attest at most once per rowHash.
    ///         Once quorum is reached, further attestations are accepted but
    ///         the quorumReached flag is already set (idempotent).
    ///
    /// @param rowHash  keccak256 hash of the TrainingRow fields (as computed by IGLALedger._rowHash).
    /// @param sig      65-byte ECDSA signature (r || s || v) over EIP-191 personal-sign of rowHash.
    function attestRow(bytes32 rowHash, bytes calldata sig) external {
        require(rowHash != bytes32(0), "MofNAttest: zero rowHash");

        // ---- Recover signer ----
        bytes32 msgHash = _personalSignHash(rowHash);
        address signer = _recoverSigner(msgHash, sig);

        // ---- Find chip-owner index ----
        int8 idx = _chipOwnerIndex(signer);
        require(idx >= 0, "MofNAttest: signer not a chip-owner");

        // ---- Check not already attested ----
        uint8 bit = uint8(1 << uint8(idx));
        require((attestBitmap[rowHash] & bit) == 0, "MofNAttest: already attested");

        // ---- Record attestation ----
        attestBitmap[rowHash] |= bit;
        attestCount[rowHash] += 1;
        uint8 count = attestCount[rowHash];

        emit RowAttested(rowHash, signer, uint8(idx), count);

        // ---- Check quorum ----
        if (!quorumReached[rowHash] && count >= quorumThreshold) {
            quorumReached[rowHash] = true;
            emit QuorumReached(rowHash, quorumThreshold, chipOwnerCount);
        }
    }

    // ─── Core: attestRowDirect ────────────────────────────────────────────────

    /// @notice Alternative entry: caller must be a registered chip-owner (no sig needed).
    /// @dev    Useful when the chip-owner calls directly from their own EOA.
    function attestRowDirect(bytes32 rowHash) external {
        require(rowHash != bytes32(0), "MofNAttest: zero rowHash");

        int8 idx = _chipOwnerIndex(msg.sender);
        require(idx >= 0, "MofNAttest: caller not a chip-owner");

        uint8 bit = uint8(1 << uint8(idx));
        require((attestBitmap[rowHash] & bit) == 0, "MofNAttest: already attested");

        attestBitmap[rowHash] |= bit;
        attestCount[rowHash] += 1;
        uint8 count = attestCount[rowHash];

        emit RowAttested(rowHash, msg.sender, uint8(idx), count);

        if (!quorumReached[rowHash] && count >= quorumThreshold) {
            quorumReached[rowHash] = true;
            emit QuorumReached(rowHash, quorumThreshold, chipOwnerCount);
        }
    }

    // ─── Queries ─────────────────────────────────────────────────────────────

    /// @notice Returns true if rowHash has reached quorum attestations.
    /// @dev    Called by IGLALedger.submitRow when attestModule is configured.
    function isRowAttested(bytes32 rowHash) external view returns (bool) {
        return quorumReached[rowHash];
    }

    /// @notice Returns which chip-owners have attested a given rowHash.
    /// @return attested Array of booleans [owner0_attested, owner1_attested, owner2_attested].
    function getAttesters(bytes32 rowHash)
        external view returns (bool[3] memory attested)
    {
        uint8 bm = attestBitmap[rowHash];
        attested[0] = (bm & 0x01) != 0;
        attested[1] = (bm & 0x02) != 0;
        attested[2] = (bm & 0x04) != 0;
    }

    /// @notice Returns the registered chip-owners.
    function getChipOwners() external view returns (address[3] memory) {
        return chipOwners;
    }

    // ─── Admin ───────────────────────────────────────────────────────────────

    /// @notice Update a single chip-owner address (e.g., key rotation).
    /// @param  index  0, 1, or 2.
    /// @param  newOwner New chip-owner address.
    function setChipOwner(uint8 index, address newOwner) external onlyOwner {
        require(index < 3, "MofNAttest: index out of range");
        require(newOwner != address(0), "MofNAttest: zero address");
        // Uniqueness check
        for (uint8 j = 0; j < 3; j++) {
            if (j != index) {
                require(chipOwners[j] != newOwner, "MofNAttest: duplicate chipOwner");
            }
        }
        chipOwners[index] = newOwner;
    }

    // ─── Internal helpers ────────────────────────────────────────────────────

    /// @dev Compute EIP-191 personal-sign hash of rowHash.
    function _personalSignHash(bytes32 rowHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            rowHash
        ));
    }

    /// @dev Recover signer from 65-byte ECDSA signature (r || s || v).
    function _recoverSigner(
        bytes32 msgHash,
        bytes calldata sig
    ) internal pure returns (address) {
        require(sig.length == 65, "MofNAttest: invalid sig length");
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
        require(v == 27 || v == 28, "MofNAttest: invalid v");
        address recovered = ecrecover(msgHash, v, r, s);
        require(recovered != address(0), "MofNAttest: ecrecover failed");
        return recovered;
    }

    /// @dev Returns chip-owner index [0,2] or -1 if not found.
    function _chipOwnerIndex(address addr) internal view returns (int8) {
        for (int8 i = 0; i < 3; i++) {
            if (chipOwners[uint8(i)] == addr) return i;
        }
        return -1;
    }
}
