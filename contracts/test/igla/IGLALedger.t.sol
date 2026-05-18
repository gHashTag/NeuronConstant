// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/igla/IGLALedger.sol";

// ─────────────────────────────────────────────────────────────────────────────
// IGLALedger Foundry Tests
//
// Tests:
//   1. Happy path: submitRow with valid oracle signature
//   2. Regression revert: BPB does not improve
//   3. Step monotonicity revert: step regression
//   4. Invalid oracle signature: reverts
//   5. Gate-2 quorum: gate2() returns true after 3 chips
//   6. Champion tracking: getChampion() returns global best
//   7. submitRowVerified: only callable by trainingProver
//
// Champion reference: BPB=2.2393 @ step=27000 seed=43
// ─────────────────────────────────────────────────────────────────────────────

contract IGLALedgerTest is Test {
    IGLALedger internal ledger;

    // Test accounts
    uint256 internal oraclePrivKey = 0xA11CE;
    address internal oracle;
    address internal deployer = address(0xDEAD);
    address internal prover   = address(0xBEEF);

    // Champion constants from trios-trainer-igla/assertions/champion_lock.txt
    uint32  constant CHAMPION_BPB_E6 = 2_239_300; // 2.2393 * 1e6
    uint64  constant CHAMPION_STEP   = 27_000;
    uint32  constant CHAMPION_SEED   = 43;
    bytes7  constant CHAMPION_SHA    = bytes7(hex"24468550000000"); // sha=2446855 padded
    bytes32 constant CHIP_A = keccak256("chip-alpha");
    bytes32 constant CHIP_B = keccak256("chip-beta");
    bytes32 constant CHIP_C = keccak256("chip-gamma");

    function setUp() public {
        oracle = vm.addr(oraclePrivKey);

        address[] memory oracles = new address[](1);
        oracles[0] = oracle;

        vm.prank(deployer);
        ledger = new IGLALedger(oracles);

        vm.prank(deployer);
        ledger.setTrainingProver(prover);
    }

    // ─── Helper: sign a TrainingRow ───────────────────────────────────────────

    function _signRow(IGLALedger.TrainingRow memory row, uint256 privKey)
        internal pure returns (bytes memory)
    {
        bytes32 dataHash = keccak256(abi.encode(
            row.chipSerial,
            row.step,
            row.seed,
            row.bpbE6,
            row.sha,
            row.jsonlRow,
            row.gateStatus
        ));
        bytes32 msgHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            dataHash
        ));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, msgHash);
        return abi.encodePacked(r, s, v);
    }

    // ─── Helper: build champion row ───────────────────────────────────────────

    function _championRow(bytes32 chipSerial)
        internal pure returns (IGLALedger.TrainingRow memory)
    {
        return IGLALedger.TrainingRow({
            chipSerial: chipSerial,
            step:       CHAMPION_STEP,
            seed:       CHAMPION_SEED,
            bpbE6:      CHAMPION_BPB_E6,
            sha:        CHAMPION_SHA,
            jsonlRow:   1,
            gateStatus: 1,
            timestamp:  0 // set by contract
        });
    }

    // ─── Test 1: Happy path ───────────────────────────────────────────────────

    function test_submitRow_happyPath() public {
        IGLALedger.TrainingRow memory row = _championRow(CHIP_A);
        bytes memory sig = _signRow(row, oraclePrivKey);

        vm.expectEmit(true, false, false, true);
        emit IGLALedger.RowSubmitted(
            CHIP_A,
            CHAMPION_STEP,
            CHAMPION_SEED,
            CHAMPION_BPB_E6,
            1,
            1,
            uint64(block.timestamp)
        );

        ledger.submitRow(row, sig);

        assertEq(ledger.bestBPB(CHIP_A), CHAMPION_BPB_E6);
        assertEq(ledger.lastStep(CHIP_A), CHAMPION_STEP);

        IGLALedger.TrainingRow memory champion = ledger.getChampion();
        assertEq(champion.chipSerial, CHIP_A);
        assertEq(champion.bpbE6, CHAMPION_BPB_E6);
        assertEq(champion.seed, CHAMPION_SEED);
        assertEq(champion.step, CHAMPION_STEP);
    }

    // ─── Test 2: BPB regression revert ───────────────────────────────────────

    function test_submitRow_revert_bpbRegression() public {
        // Submit champion first
        IGLALedger.TrainingRow memory row1 = _championRow(CHIP_A);
        ledger.submitRow(row1, _signRow(row1, oraclePrivKey));

        // Try to submit worse BPB (higher = worse)
        IGLALedger.TrainingRow memory row2 = IGLALedger.TrainingRow({
            chipSerial: CHIP_A,
            step:       CHAMPION_STEP + 1000,
            seed:       CHAMPION_SEED,
            bpbE6:      CHAMPION_BPB_E6 + 1, // worse
            sha:        CHAMPION_SHA,
            jsonlRow:   2,
            gateStatus: 1,
            timestamp:  0
        });

        vm.expectRevert("IGLALedger: BPB does not improve best");
        ledger.submitRow(row2, _signRow(row2, oraclePrivKey));
    }

    // ─── Test 3: Same BPB (no improvement) revert ────────────────────────────

    function test_submitRow_revert_sameBPB() public {
        IGLALedger.TrainingRow memory row1 = _championRow(CHIP_A);
        ledger.submitRow(row1, _signRow(row1, oraclePrivKey));

        IGLALedger.TrainingRow memory row2 = IGLALedger.TrainingRow({
            chipSerial: CHIP_A,
            step:       CHAMPION_STEP + 1000,
            seed:       CHAMPION_SEED,
            bpbE6:      CHAMPION_BPB_E6, // same — not strictly better
            sha:        CHAMPION_SHA,
            jsonlRow:   2,
            gateStatus: 1,
            timestamp:  0
        });

        vm.expectRevert("IGLALedger: BPB does not improve best");
        ledger.submitRow(row2, _signRow(row2, oraclePrivKey));
    }

    // ─── Test 4: Step regression revert ──────────────────────────────────────

    function test_submitRow_revert_stepRegression() public {
        IGLALedger.TrainingRow memory row1 = _championRow(CHIP_A);
        ledger.submitRow(row1, _signRow(row1, oraclePrivKey));

        // Submit with lower step AND lower BPB — step must still be monotonic
        IGLALedger.TrainingRow memory row2 = IGLALedger.TrainingRow({
            chipSerial: CHIP_A,
            step:       CHAMPION_STEP - 1, // regression
            seed:       CHAMPION_SEED,
            bpbE6:      CHAMPION_BPB_E6 - 1, // better BPB but step regresses
            sha:        CHAMPION_SHA,
            jsonlRow:   2,
            gateStatus: 1,
            timestamp:  0
        });

        vm.expectRevert("IGLALedger: step regression");
        ledger.submitRow(row2, _signRow(row2, oraclePrivKey));
    }

    // ─── Test 5: Invalid oracle signature ────────────────────────────────────

    function test_submitRow_revert_invalidOracleSig() public {
        IGLALedger.TrainingRow memory row = _championRow(CHIP_A);

        // Sign with non-oracle key
        uint256 badKey = 0xBADBADBAD;
        bytes memory badSig = _signRow(row, badKey);

        vm.expectRevert("IGLALedger: invalid oracle signature");
        ledger.submitRow(row, badSig);
    }

    // ─── Test 6: Gate-2 quorum (3 chips) ─────────────────────────────────────

    function test_gate2_quorumAfterThreeChips() public {
        // Before: gate2 not reached
        assertFalse(ledger.gate2(CHAMPION_BPB_E6));

        // Chip A
        IGLALedger.TrainingRow memory rowA = _championRow(CHIP_A);
        ledger.submitRow(rowA, _signRow(rowA, oraclePrivKey));
        assertFalse(ledger.gate2(CHAMPION_BPB_E6));

        // Chip B
        IGLALedger.TrainingRow memory rowB = _championRow(CHIP_B);
        ledger.submitRow(rowB, _signRow(rowB, oraclePrivKey));
        assertFalse(ledger.gate2(CHAMPION_BPB_E6));

        // Chip C — triggers quorum
        IGLALedger.TrainingRow memory rowC = _championRow(CHIP_C);

        vm.expectEmit(true, false, false, true);
        emit IGLALedger.Gate2QuorumReached(CHAMPION_BPB_E6, 3);

        ledger.submitRow(rowC, _signRow(rowC, oraclePrivKey));

        assertTrue(ledger.gate2(CHAMPION_BPB_E6));
        assertEq(ledger.gate2ChipCount(CHAMPION_BPB_E6), 3);
    }

    // ─── Test 7: Gate2 count tracks correctly ─────────────────────────────────

    function test_gate2_countTrackingByTarget() public {
        // Chip A achieves a better BPB than champion
        uint32 betterBpb = CHAMPION_BPB_E6 - 1000;
        IGLALedger.TrainingRow memory rowA = IGLALedger.TrainingRow({
            chipSerial: CHIP_A,
            step:       28_000,
            seed:       CHAMPION_SEED,
            bpbE6:      betterBpb,
            sha:        CHAMPION_SHA,
            jsonlRow:   2,
            gateStatus: 2,
            timestamp:  0
        });
        ledger.submitRow(rowA, _signRow(rowA, oraclePrivKey));

        // Champion BPB: count still 0
        assertEq(ledger.gate2ChipCount(CHAMPION_BPB_E6), 0);
        // Better BPB target: count = 1
        assertEq(ledger.gate2ChipCount(betterBpb), 1);
    }

    // ─── Test 8: Champion update event ───────────────────────────────────────

    function test_champion_updateEvent() public {
        IGLALedger.TrainingRow memory row = _championRow(CHIP_A);

        vm.expectEmit(true, false, false, true);
        emit IGLALedger.ChampionUpdated(
            CHIP_A,
            CHAMPION_STEP,
            CHAMPION_SEED,
            CHAMPION_BPB_E6,
            uint64(block.timestamp)
        );

        ledger.submitRow(row, _signRow(row, oraclePrivKey));
    }

    // ─── Test 9: submitRowVerified — only prover ──────────────────────────────

    function test_submitRowVerified_onlyProver() public {
        IGLALedger.TrainingRow memory row = _championRow(CHIP_A);

        // Random caller fails
        vm.prank(address(0x1234));
        vm.expectRevert("IGLALedger: not trainingProver");
        ledger.submitRowVerified(row);

        // Prover succeeds
        vm.prank(prover);
        ledger.submitRowVerified(row);
        assertEq(ledger.bestBPB(CHIP_A), CHAMPION_BPB_E6);
    }

    // ─── Test 10: getChampion reverts if no rows ──────────────────────────────

    function test_getChampion_revertIfEmpty() public {
        vm.expectRevert("IGLALedger: no champion yet");
        ledger.getChampion();
    }

    // ─── Test 11: Multiple rows per chip tracked ──────────────────────────────

    function test_multipleRowsPerChip_tracked() public {
        // First submission
        IGLALedger.TrainingRow memory row1 = IGLALedger.TrainingRow({
            chipSerial: CHIP_A,
            step:       10_000,
            seed:       CHAMPION_SEED,
            bpbE6:      2_500_000, // 2.5 BPB
            sha:        CHAMPION_SHA,
            jsonlRow:   1,
            gateStatus: 0,
            timestamp:  0
        });
        ledger.submitRow(row1, _signRow(row1, oraclePrivKey));

        // Second better submission
        IGLALedger.TrainingRow memory row2 = IGLALedger.TrainingRow({
            chipSerial: CHIP_A,
            step:       27_000,
            seed:       CHAMPION_SEED,
            bpbE6:      CHAMPION_BPB_E6, // champion BPB
            sha:        CHAMPION_SHA,
            jsonlRow:   2,
            gateStatus: 1,
            timestamp:  0
        });
        ledger.submitRow(row2, _signRow(row2, oraclePrivKey));

        IGLALedger.TrainingRow[] memory rows = ledger.getRowsByChip(CHIP_A);
        assertEq(rows.length, 2);
        assertEq(rows[0].bpbE6, 2_500_000);
        assertEq(rows[1].bpbE6, CHAMPION_BPB_E6);
        assertEq(ledger.bestBPB(CHIP_A), CHAMPION_BPB_E6);
    }
}
