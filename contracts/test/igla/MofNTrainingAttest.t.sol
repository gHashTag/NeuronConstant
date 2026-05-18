// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/igla/MofNTrainingAttest.sol";

// ─────────────────────────────────────────────────────────────────────────────
// MofNTrainingAttest Foundry Tests
//
// Tests:
//   1. attestRow happy path with valid sig from chip-owner 0
//   2. attestRow happy path with valid sig from chip-owner 1
//   3. attestRowDirect from chip-owner EOA
//   4. Quorum reached after 2-of-3 attestations
//   5. Quorum NOT reached after only 1 attestation
//   6. Duplicate attestation reverts
//   7. Non-chip-owner signature reverts
//   8. isRowAttested returns false/true correctly
//   9. getAttesters bitmap tracks correctly
//   10. setChipOwner (admin) updates and enforces uniqueness
//
// Mirrors HW tri_mofn_attest.v (common/depin/v2/, commit fb0e385).
// ─────────────────────────────────────────────────────────────────────────────

contract MofNTrainingAttestTest is Test {
    MofNTrainingAttest internal attest;

    uint256 internal key0 = 0xC0FFEE01;
    uint256 internal key1 = 0xC0FFEE02;
    uint256 internal key2 = 0xC0FFEE03;

    address internal owner0;
    address internal owner1;
    address internal owner2;
    address internal deployer = address(0xDEAD);

    bytes32 constant ROW_HASH_A = keccak256("row-hash-alpha");
    bytes32 constant ROW_HASH_B = keccak256("row-hash-beta");

    function setUp() public {
        owner0 = vm.addr(key0);
        owner1 = vm.addr(key1);
        owner2 = vm.addr(key2);

        address[3] memory owners = [owner0, owner1, owner2];

        vm.prank(deployer);
        attest = new MofNTrainingAttest(owners, 2); // 2-of-3
    }

    // ─── Helper: sign rowHash as chip-owner ───────────────────────────────────

    function _signHash(bytes32 rowHash, uint256 privKey)
        internal pure returns (bytes memory)
    {
        bytes32 msgHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            rowHash
        ));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, msgHash);
        return abi.encodePacked(r, s, v);
    }

    // ─── Test 1: attestRow with sig from owner0 ───────────────────────────────

    function test_attestRow_owner0() public {
        bytes memory sig = _signHash(ROW_HASH_A, key0);

        vm.expectEmit(true, true, false, true);
        emit MofNTrainingAttest.RowAttested(ROW_HASH_A, owner0, 0, 1);

        attest.attestRow(ROW_HASH_A, sig);

        assertEq(attest.attestCount(ROW_HASH_A), 1);
        assertFalse(attest.quorumReached(ROW_HASH_A));
    }

    // ─── Test 2: attestRow with sig from owner1 ───────────────────────────────

    function test_attestRow_owner1() public {
        bytes memory sig = _signHash(ROW_HASH_A, key1);

        vm.expectEmit(true, true, false, true);
        emit MofNTrainingAttest.RowAttested(ROW_HASH_A, owner1, 1, 1);

        attest.attestRow(ROW_HASH_A, sig);
        assertEq(attest.attestCount(ROW_HASH_A), 1);
    }

    // ─── Test 3: attestRowDirect from EOA ────────────────────────────────────

    function test_attestRowDirect() public {
        vm.prank(owner2);
        attest.attestRowDirect(ROW_HASH_A);

        assertEq(attest.attestCount(ROW_HASH_A), 1);
    }

    // ─── Test 4: Quorum reached after 2 attestations ──────────────────────────

    function test_quorumReached_2of3() public {
        // Attest 1
        attest.attestRow(ROW_HASH_A, _signHash(ROW_HASH_A, key0));
        assertFalse(attest.quorumReached(ROW_HASH_A));
        assertFalse(attest.isRowAttested(ROW_HASH_A));

        // Attest 2 — triggers quorum
        vm.expectEmit(true, false, false, true);
        emit MofNTrainingAttest.QuorumReached(ROW_HASH_A, 2, 3);

        attest.attestRow(ROW_HASH_A, _signHash(ROW_HASH_A, key1));
        assertTrue(attest.quorumReached(ROW_HASH_A));
        assertTrue(attest.isRowAttested(ROW_HASH_A));
        assertEq(attest.attestCount(ROW_HASH_A), 2);
    }

    // ─── Test 5: Quorum NOT reached after 1 attestation ──────────────────────

    function test_quorumNotReached_after1() public {
        attest.attestRow(ROW_HASH_A, _signHash(ROW_HASH_A, key0));
        assertFalse(attest.quorumReached(ROW_HASH_A));
        assertFalse(attest.isRowAttested(ROW_HASH_A));
    }

    // ─── Test 6: Duplicate attestation reverts ────────────────────────────────

    function test_duplicateAttestation_reverts() public {
        attest.attestRow(ROW_HASH_A, _signHash(ROW_HASH_A, key0));

        // Same owner tries again
        vm.expectRevert("MofNAttest: already attested");
        attest.attestRow(ROW_HASH_A, _signHash(ROW_HASH_A, key0));
    }

    function test_duplicateAttestDirect_reverts() public {
        vm.prank(owner0);
        attest.attestRowDirect(ROW_HASH_A);

        vm.prank(owner0);
        vm.expectRevert("MofNAttest: already attested");
        attest.attestRowDirect(ROW_HASH_A);
    }

    // ─── Test 7: Non-chip-owner signature reverts ────────────────────────────

    function test_nonChipOwner_sig_reverts() public {
        uint256 badKey = 0xBADBAD;
        bytes memory sig = _signHash(ROW_HASH_A, badKey);

        vm.expectRevert("MofNAttest: signer not a chip-owner");
        attest.attestRow(ROW_HASH_A, sig);
    }

    function test_nonChipOwner_direct_reverts() public {
        vm.prank(address(0x9999));
        vm.expectRevert("MofNAttest: caller not a chip-owner");
        attest.attestRowDirect(ROW_HASH_A);
    }

    // ─── Test 8: isRowAttested returns correct state ──────────────────────────

    function test_isRowAttested_states() public {
        // Initially false
        assertFalse(attest.isRowAttested(ROW_HASH_A));

        attest.attestRow(ROW_HASH_A, _signHash(ROW_HASH_A, key0));
        assertFalse(attest.isRowAttested(ROW_HASH_A)); // still 1 of 3

        attest.attestRow(ROW_HASH_A, _signHash(ROW_HASH_A, key1));
        assertTrue(attest.isRowAttested(ROW_HASH_A));  // 2 of 3 = quorum
    }

    // ─── Test 9: getAttesters bitmap ─────────────────────────────────────────

    function test_getAttesters_bitmap() public {
        bool[3] memory a;

        a = attest.getAttesters(ROW_HASH_A);
        assertFalse(a[0]); assertFalse(a[1]); assertFalse(a[2]);

        attest.attestRow(ROW_HASH_A, _signHash(ROW_HASH_A, key0));
        a = attest.getAttesters(ROW_HASH_A);
        assertTrue(a[0]); assertFalse(a[1]); assertFalse(a[2]);

        attest.attestRow(ROW_HASH_A, _signHash(ROW_HASH_A, key2));
        a = attest.getAttesters(ROW_HASH_A);
        assertTrue(a[0]); assertFalse(a[1]); assertTrue(a[2]);
    }

    // ─── Test 10: setChipOwner admin ─────────────────────────────────────────

    function test_setChipOwner_updatesAddress() public {
        address newOwner = address(0xABCD);
        vm.prank(deployer);
        attest.setChipOwner(0, newOwner);
        assertEq(attest.chipOwners(0), newOwner);
    }

    function test_setChipOwner_revert_notOwner() public {
        vm.prank(address(0x1234));
        vm.expectRevert("MofNAttest: not owner");
        attest.setChipOwner(0, address(0xABCD));
    }

    function test_setChipOwner_revert_duplicate() public {
        // Try to set owner0 index 0 to same address as owner1
        vm.prank(deployer);
        vm.expectRevert("MofNAttest: duplicate chipOwner");
        attest.setChipOwner(0, owner1);
    }

    // ─── Test 11: All 3 chip-owners attest (full set) ────────────────────────

    function test_allThreeAttest() public {
        attest.attestRow(ROW_HASH_B, _signHash(ROW_HASH_B, key0));
        attest.attestRow(ROW_HASH_B, _signHash(ROW_HASH_B, key1));
        attest.attestRow(ROW_HASH_B, _signHash(ROW_HASH_B, key2));

        assertEq(attest.attestCount(ROW_HASH_B), 3);
        assertTrue(attest.quorumReached(ROW_HASH_B));

        bool[3] memory a = attest.getAttesters(ROW_HASH_B);
        assertTrue(a[0]); assertTrue(a[1]); assertTrue(a[2]);
    }

    // ─── Test 12: Different rowHashes are independent ─────────────────────────

    function test_independentRowHashes() public {
        // Attest ROW_HASH_A to quorum
        attest.attestRow(ROW_HASH_A, _signHash(ROW_HASH_A, key0));
        attest.attestRow(ROW_HASH_A, _signHash(ROW_HASH_A, key1));
        assertTrue(attest.isRowAttested(ROW_HASH_A));

        // ROW_HASH_B is independent
        assertFalse(attest.isRowAttested(ROW_HASH_B));
        assertEq(attest.attestCount(ROW_HASH_B), 0);
    }

    // ─── Test 13: Constructor reverts on invalid quorum ───────────────────────

    function test_constructor_revert_invalidQuorum() public {
        address[3] memory owners = [owner0, owner1, owner2];
        vm.expectRevert("MofNAttest: invalid quorum");
        new MofNTrainingAttest(owners, 0);

        vm.expectRevert("MofNAttest: invalid quorum");
        new MofNTrainingAttest(owners, 4);
    }

    function test_constructor_revert_duplicateOwner() public {
        address[3] memory owners = [owner0, owner0, owner2]; // duplicate
        vm.expectRevert("MofNAttest: duplicate chipOwner");
        new MofNTrainingAttest(owners, 2);
    }
}
