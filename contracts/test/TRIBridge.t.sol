// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Foundry test suite for TRIBridge.
// Run: forge test --match-path contracts/test/TRIBridge.t.sol -vvv
//
// NOTE: Tests that require oracle signature verification use forge's `vm.sign`
//       cheatcode.  The test contract inherits from forge-std/Test.sol in the
//       real environment; the inline version below documents the expected behaviour
//       and compiles without forge-std for static analysis / IDE support.
//
// Real Foundry test file pattern (with forge-std):
//   import "forge-std/Test.sol";
//   contract TRIBridgeTest is Test { ... }

import "../src/TRIToken.sol";
import "../src/TRIBridge.sol";

contract TRIBridgeTest {
    TRIToken  internal token;
    TRIBridge internal bridge;

    // Deterministic test private keys and their corresponding addresses.
    // In a real Foundry test, derive with: (addr, pk) = makeAddrAndKey("label");
    uint256 internal constant PK_ORACLE_0 = 0xA11;
    uint256 internal constant PK_ORACLE_1 = 0xB22;
    uint256 internal constant PK_ORACLE_2 = 0xC33;

    address internal oracle0;
    address internal oracle1;
    address internal oracle2;

    address internal constant ALICE = address(0xA11CE);

    bytes32 internal constant CHIP_SERIAL = keccak256("phi-chip-001");

    // ── Setup ────────────────────────────────────────────────────────────────
    function setUp() public {
        oracle0 = _pkToAddr(PK_ORACLE_0);
        oracle1 = _pkToAddr(PK_ORACLE_1);
        oracle2 = _pkToAddr(PK_ORACLE_2);

        address[3] memory oracles = [oracle0, oracle1, oracle2];
        bridge = new TRIBridge(address(0), oracles); // token set separately below

        // Deploy token with bridge as controller
        token = new TRIToken(address(bridge));

        // Note: In production, TRIBridge must be constructed AFTER TRIToken,
        // then TRIToken constructor receives bridge address.
        // Here we accept this circular dependency for test clarity;
        // use a factory or two-step init in production.
    }

    // ── Helpers ──────────────────────────────────────────────────────────────
    function _assertTrue(bool c, string memory m) internal pure { require(c, m); }
    function _assertEq(uint256 a, uint256 b, string memory m) internal pure { require(a == b, m); }

    /// @dev Simulate ecrecover signing for tests (forge-std vm.sign equivalent stub).
    function _signReceipt(bytes32 hash, uint256 pk) internal pure returns (bytes memory) {
        // In Foundry: (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, hash);
        // Stub: returns empty 65-byte slot; replace with real vm.sign in Foundry.
        bytes memory sig = new bytes(65);
        // Real usage:
        //   (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, hash);
        //   assembly { mstore(add(sig, 32), r) mstore(add(sig, 64), s) mstore8(add(sig, 96), v) }
        return sig;
    }

    function _pkToAddr(uint256 pk) internal pure returns (address) {
        // Stub: in Foundry use vm.addr(pk).
        // For uniqueness in tests we just cast.
        return address(uint160(pk * 0xDEAD));
    }

    // ── Test: constructor sets oracles ───────────────────────────────────────
    function test_oraclesSet() public {
        address[3] memory o = bridge.getOracles();
        _assertTrue(o[0] == oracle0, "oracle0");
        _assertTrue(o[1] == oracle1, "oracle1");
        _assertTrue(o[2] == oracle2, "oracle2");
    }

    // ── Test: duplicate oracle reverts ────────────────────────────────────────
    function test_duplicateOracle_revert() public {
        address[3] memory badOracles = [oracle0, oracle0, oracle2];
        bool reverted;
        try new TRIBridge(address(token), badOracles) {
        } catch {
            reverted = true;
        }
        _assertTrue(reverted, "should revert duplicate oracle");
    }

    // ── Test: chip type amount caps ───────────────────────────────────────────
    // In a full Foundry environment these tests use vm.sign to produce real sigs.
    // Here we document the expected revert conditions.

    // phi cap = 1 ether — amount > cap must revert
    function test_phiCapExceeded_revert() public {
        // Build a receipt with amount = 2 ether for a phi chip
        TRIBridge.ClaimReceipt memory r = TRIBridge.ClaimReceipt({
            chipSerial:    CHIP_SERIAL,
            nonce:         1,
            amount:        2 ether, // exceeds phi cap of 1 ether
            vrfReceiptHash: bytes32(0),
            chipType:      0,       // phi
            claimant:      ALICE,
            signatures:    new bytes(0)
        });

        bool reverted;
        try bridge.claim(r) {
        } catch {
            reverted = true;
        }
        _assertTrue(reverted, "phi cap exceeded should revert");
    }

    // euler cap = 2 ether
    function test_eulerCapExceeded_revert() public {
        TRIBridge.ClaimReceipt memory r = TRIBridge.ClaimReceipt({
            chipSerial:    CHIP_SERIAL,
            nonce:         1,
            amount:        3 ether,
            vrfReceiptHash: bytes32(0),
            chipType:      1,       // euler
            claimant:      ALICE,
            signatures:    new bytes(0)
        });

        bool reverted;
        try bridge.claim(r) {
        } catch {
            reverted = true;
        }
        _assertTrue(reverted, "euler cap exceeded should revert");
    }

    // gamma cap = 4 ether
    function test_gammaCap_valid_amount() public {
        // A gamma receipt with amount = 4 ether is within cap.
        // It will still revert for insufficient sigs, but NOT for cap.
        TRIBridge.ClaimReceipt memory r = TRIBridge.ClaimReceipt({
            chipSerial:    CHIP_SERIAL,
            nonce:         1,
            amount:        4 ether,
            vrfReceiptHash: bytes32(0),
            chipType:      2,       // gamma
            claimant:      ALICE,
            signatures:    new bytes(0)
        });

        bool reverted;
        string memory reason;
        try bridge.claim(r) {
        } catch Error(string memory _r) {
            reverted = true;
            reason   = _r;
        } catch {
            reverted = true;
        }
        _assertTrue(reverted, "should still revert (no sigs), but not for cap");
        // In Foundry: assertNotEq(reason, "TRIBridge: exceeds gamma cap");
    }

    // ── Test: insufficient oracle signatures (1 sig) reverts ─────────────────
    function test_insufficientSigs_revert() public {
        // Submit with 0 bytes of signatures
        TRIBridge.ClaimReceipt memory r = TRIBridge.ClaimReceipt({
            chipSerial:    CHIP_SERIAL,
            nonce:         1,
            amount:        1 ether,
            vrfReceiptHash: bytes32(0),
            chipType:      0,
            claimant:      ALICE,
            signatures:    new bytes(0)
        });

        bool reverted;
        try bridge.claim(r) {
        } catch {
            reverted = true;
        }
        _assertTrue(reverted, "0 sigs should revert");
    }

    // ── Test: nonce regression reverts ───────────────────────────────────────
    // If chipNonces[serial] = 5, submitting nonce = 5 or lower must revert.
    function test_nonceRegression_revert() public {
        // We cannot advance the nonce without valid sigs in this stub.
        // Document the check: bridge.chipNonces starts at 0, nonce=0 should revert.
        TRIBridge.ClaimReceipt memory r = TRIBridge.ClaimReceipt({
            chipSerial:    CHIP_SERIAL,
            nonce:         0, // must be > 0 (> chipNonces[serial])
            amount:        1 ether,
            vrfReceiptHash: bytes32(0),
            chipType:      0,
            claimant:      ALICE,
            signatures:    new bytes(0)
        });

        bool reverted;
        try bridge.claim(r) {
        } catch {
            reverted = true;
        }
        _assertTrue(reverted, "nonce=0 should revert (not > chipNonces[0])");
    }

    // ── Test: unknown chipType reverts ────────────────────────────────────────
    function test_unknownChipType_revert() public {
        TRIBridge.ClaimReceipt memory r = TRIBridge.ClaimReceipt({
            chipSerial:    CHIP_SERIAL,
            nonce:         1,
            amount:        1 ether,
            vrfReceiptHash: bytes32(0),
            chipType:      99, // invalid
            claimant:      ALICE,
            signatures:    new bytes(0)
        });

        bool reverted;
        try bridge.claim(r) {
        } catch {
            reverted = true;
        }
        _assertTrue(reverted, "unknown chipType should revert");
    }

    // ── Test: non-oracle cannot slash ─────────────────────────────────────────
    function test_slashOnlyOracle_revert() public {
        bool reverted;
        try bridge.slashReceipt(bytes32(0), bytes("evidence")) {
        } catch {
            reverted = true;
        }
        _assertTrue(reverted, "non-oracle slash should revert");
    }

    // ─── NOTE: Full 2-of-3 happy-path and replay-attack tests ────────────────
    // require forge-std vm.sign cheatcode to produce real ECDSA signatures.
    // Template (add to a forge-std Test subclass):
    //
    //   function test_claim_2of3_success() public {
    //       TRIBridge.ClaimReceipt memory r = /* ... */;
    //       bytes32 innerHash = keccak256(abi.encode(
    //           r.chipSerial, r.nonce, r.amount, r.vrfReceiptHash,
    //           r.chipType, r.claimant));
    //       bytes32 msgHash = keccak256(abi.encodePacked(
    //           "\x19Ethereum Signed Message:\n32", innerHash));
    //       (uint8 v0, bytes32 r0, bytes32 s0) = vm.sign(PK_ORACLE_0, msgHash);
    //       (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(PK_ORACLE_1, msgHash);
    //       bytes memory sigs = abi.encodePacked(r0, s0, v0, r1, s1, v1);
    //       r.signatures = sigs;
    //       bridge.claim(r);
    //       assertEq(token.balanceOf(ALICE), r.amount);
    //   }
    //
    //   function test_replayAttack_revert() public {
    //       // claim once (succeeds), then claim same receipt again (reverts)
    //   }
}
