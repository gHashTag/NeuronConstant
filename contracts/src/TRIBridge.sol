// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Trinity DePIN Bridge — Oracle Multi-sig Gateway
//
// Architecture:
//   HW accumulator (tri_token_accumulator.v) inside each Trinity Triad chip
//   generates a ClaimReceipt after each completed work cycle.  An off-chain
//   indexer daemon collects these receipts via USB/serial, gathers 2-of-3
//   oracle signatures (mirroring the hardware M-of-N attestation scheme),
//   and submits them to this contract.
//
// Chip type reward caps (per single claim):
//   phi   (chipType=0, SKY26b 1x1) → max 1  TRI  (1e18 wei)
//   euler (chipType=1, SKY26b 2x2) → max 2  TRI  (2e18 wei)
//   gamma (chipType=2, SKY26b 4x2) → max 4  TRI  (4e18 wei)
//
// Security model:
//   - Replay protection: processedReceipts mapping
//   - Sequence integrity: chipNonces ensures monotonically increasing nonces
//   - Oracle threshold: >= 2-of-3 valid ECDSA signatures required
//   - Amount cap: enforced per chipType on-chain
//   - Slashing: oracle records evidence of fraudulent claims; off-chain
//     enforcement deducts balance >> 4 (6.25 %) from the claimant

interface ITRIToken {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

contract TRIBridge {
    // ─── Constants ───────────────────────────────────────────────────────────
    uint256 public constant ORACLE_THRESHOLD = 2;

    // Maximum TRI per single claim, in 1e18 units (integer TRI).
    uint256 public constant PHI_MAX   = 1 ether;   // chipType = 0
    uint256 public constant EULER_MAX = 2 ether;   // chipType = 1
    uint256 public constant GAMMA_MAX = 4 ether;   // chipType = 2

    // ─── State ───────────────────────────────────────────────────────────────
    ITRIToken public immutable token;

    address[3] public oracles;

    /// @notice Tracks the highest processed nonce per chip serial.
    mapping(bytes32 => uint256) public chipNonces;

    /// @notice Records receipt hashes that have been processed to prevent replay.
    mapping(bytes32 => bool) public processedReceipts;

    /// @notice Maps slashed receipt hashes to the oracle who filed the slash.
    mapping(bytes32 => address) public slashedBy;

    // ─── Structs ─────────────────────────────────────────────────────────────
    /// @dev Mirrors the hardware-generated receipt from tri_token_accumulator.v
    struct ClaimReceipt {
        bytes32 chipSerial;       // Unique chip identifier (from hardware ROM)
        uint256 nonce;            // Monotonically increasing per chip
        uint256 amount;           // TRI to mint, in wei (18 decimals)
        bytes32 vrfReceiptHash;   // VRF output hash from hardware (v2 attestation)
        uint8   chipType;         // 0=phi, 1=euler, 2=gamma
        address claimant;         // Destination wallet
        bytes   signatures;       // ABI-encoded packed array of oracle ECDSA sigs (each 65 bytes)
    }

    // ─── Events ──────────────────────────────────────────────────────────────
    event Claimed(
        bytes32 indexed chipSerial,
        address indexed claimant,
        uint256 amount,
        uint256 nonce,
        bytes32 receiptHash
    );

    event Withdrawn(
        bytes32 indexed chipSerial,
        address indexed from,
        uint256 amount
    );

    event Slashed(
        bytes32 indexed receiptHash,
        address indexed reporter,
        bytes evidence
    );

    event NonceAdvanced(
        bytes32 indexed chipSerial,
        uint256 oldNonce,
        uint256 newNonce
    );

    // ─── Modifiers ───────────────────────────────────────────────────────────
    modifier onlyOracle() {
        require(_isOracle(msg.sender), "TRIBridge: caller is not oracle");
        _;
    }

    // ─── Constructor ─────────────────────────────────────────────────────────
    /// @param _token   Address of the deployed TRIToken contract.
    /// @param _oracles Array of exactly 3 oracle addresses (2-of-3 threshold).
    constructor(address _token, address[3] memory _oracles) {
        require(_token != address(0), "TRIBridge: token is zero address");
        for (uint256 i = 0; i < 3; i++) {
            require(_oracles[i] != address(0), "TRIBridge: oracle is zero address");
            // Uniqueness check
            for (uint256 j = 0; j < i; j++) {
                require(_oracles[i] != _oracles[j], "TRIBridge: duplicate oracle");
            }
        }
        token   = ITRIToken(_token);
        oracles = _oracles;
    }

    // ─── Core: claim ─────────────────────────────────────────────────────────
    /// @notice Submit a hardware ClaimReceipt to mint TRI.
    /// @dev    Requires >= 2 valid oracle signatures over the receipt hash.
    ///         The `signatures` field is a tightly packed bytes array of 65-byte
    ///         ECDSA signatures (r ++ s ++ v), each signed by a distinct oracle.
    function claim(ClaimReceipt calldata receipt) external {
        bytes32 receiptHash = _receiptHash(receipt);

        // Replay protection
        require(!processedReceipts[receiptHash], "TRIBridge: receipt already processed");

        // Nonce must strictly advance
        require(
            receipt.nonce > chipNonces[receipt.chipSerial],
            "TRIBridge: nonce regression"
        );

        // Amount cap per chip type
        _validateAmount(receipt.chipType, receipt.amount);

        // Oracle signature threshold
        uint256 validSigs = _countValidSignatures(receiptHash, receipt.signatures);
        require(validSigs >= ORACLE_THRESHOLD, "TRIBridge: insufficient oracle signatures");

        // Commit state
        uint256 oldNonce = chipNonces[receipt.chipSerial];
        chipNonces[receipt.chipSerial]  = receipt.nonce;
        processedReceipts[receiptHash]  = true;

        emit NonceAdvanced(receipt.chipSerial, oldNonce, receipt.nonce);

        // Mint tokens
        token.mint(receipt.claimant, receipt.amount);

        emit Claimed(
            receipt.chipSerial,
            receipt.claimant,
            receipt.amount,
            receipt.nonce,
            receiptHash
        );
    }

    // ─── Core: withdraw ──────────────────────────────────────────────────────
    /// @notice Burn TRI from the caller and emit event for off-chain indexer
    ///         to credit the corresponding chip (e.g., for on-chip computation).
    /// @param chipSerial  Target chip to credit.
    /// @param amount      Amount of TRI to burn.
    function withdraw(bytes32 chipSerial, uint256 amount) external {
        require(amount > 0, "TRIBridge: zero amount");
        token.burn(msg.sender, amount);
        emit Withdrawn(chipSerial, msg.sender, amount);
    }

    // ─── Oracle: slashReceipt ────────────────────────────────────────────────
    /// @notice Record evidence of an invalid or fraudulent claim receipt.
    ///         On-chain state: marks the receipt hash as slashed.
    ///         Off-chain enforcement: indexer/governance deducts balance >> 4
    ///         (i.e., 6.25%) from the claimant's accumulated rewards.
    /// @param receiptHash  Hash of the fraudulent receipt (keccak256).
    /// @param evidence     Arbitrary bytes: ABI-encoded proof (e.g., conflicting VRF).
    function slashReceipt(bytes32 receiptHash, bytes calldata evidence) external onlyOracle {
        require(slashedBy[receiptHash] == address(0), "TRIBridge: already slashed");
        slashedBy[receiptHash] = msg.sender;
        emit Slashed(receiptHash, msg.sender, evidence);
    }

    // ─── View helpers ────────────────────────────────────────────────────────
    /// @notice Returns the list of oracle addresses.
    function getOracles() external view returns (address[3] memory) {
        return oracles;
    }

    // ─── Internal helpers ────────────────────────────────────────────────────
    /// @dev Compute EIP-191 personal-sign hash of the receipt struct fields.
    function _receiptHash(ClaimReceipt calldata r) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encode(
                r.chipSerial,
                r.nonce,
                r.amount,
                r.vrfReceiptHash,
                r.chipType,
                r.claimant
            ))
        ));
    }

    /// @dev Count how many of the packed signatures are from distinct, known oracles.
    ///      Each signature is exactly 65 bytes: r (32) || s (32) || v (1).
    function _countValidSignatures(
        bytes32 receiptHash,
        bytes calldata sigs
    ) internal view returns (uint256 count) {
        uint256 nSigs = sigs.length / 65;
        bool[3] memory used; // track which oracle index was seen

        for (uint256 i = 0; i < nSigs; i++) {
            bytes32 r;
            bytes32 s;
            uint8   v;
            uint256 offset = i * 65;
            assembly {
                // sigs is calldata; use calldatacopy approach via mload on slice
                let ptr := mload(0x40)
                calldatacopy(ptr, add(sigs.offset, offset), 65)
                r := mload(ptr)
                s := mload(add(ptr, 32))
                v := byte(0, mload(add(ptr, 64)))
            }
            if (v < 27) v += 27;
            address recovered = ecrecover(receiptHash, v, r, s);
            int8 idx = _oracleIndex(recovered);
            if (idx >= 0 && !used[uint8(idx)]) {
                used[uint8(idx)] = true;
                count++;
            }
        }
    }

    /// @dev Returns oracle index [0,2] if address is a registered oracle, else -1.
    function _oracleIndex(address addr) internal view returns (int8) {
        for (int8 i = 0; i < 3; i++) {
            if (oracles[uint8(i)] == addr) return i;
        }
        return -1;
    }

    function _isOracle(address addr) internal view returns (bool) {
        return _oracleIndex(addr) >= 0;
    }

    /// @dev Enforce per-chipType maximum single-claim amount.
    function _validateAmount(uint8 chipType, uint256 amount) internal pure {
        require(amount > 0, "TRIBridge: zero amount");
        if (chipType == 0) {
            require(amount <= PHI_MAX,   "TRIBridge: exceeds phi cap");
        } else if (chipType == 1) {
            require(amount <= EULER_MAX, "TRIBridge: exceeds euler cap");
        } else if (chipType == 2) {
            require(amount <= GAMMA_MAX, "TRIBridge: exceeds gamma cap");
        } else {
            revert("TRIBridge: unknown chipType");
        }
    }
}
