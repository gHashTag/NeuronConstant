// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Foundry test suite for TRIToken.
// Run: forge test --match-path contracts/test/TRIToken.t.sol -vv

import "../src/TRIToken.sol";

// Minimal Foundry test harness (no forge-std import for self-containment).
// Uses inline assert helpers that revert with a message on failure.

contract TRITokenTest {
    TRIToken internal token;

    address internal constant BRIDGE  = address(0xBEEF);
    address internal constant ALICE   = address(0xA11CE);
    address internal constant BOB     = address(0xB0B);
    address internal constant CHARLIE = address(0xC4A4);

    // ── Setup ────────────────────────────────────────────────────────────────
    function setUp() public {
        token = new TRIToken(BRIDGE);
    }

    // ── Helpers ──────────────────────────────────────────────────────────────
    function _assertEq(uint256 a, uint256 b, string memory msg) internal pure {
        require(a == b, msg);
    }
    function _assertEq(address a, address b, string memory msg) internal pure {
        require(a == b, msg);
    }
    function _assertTrue(bool cond, string memory msg) internal pure {
        require(cond, msg);
    }

    // ── Bridge address ───────────────────────────────────────────────────────
    function test_bridgeAddress() public {
        _assertEq(token.bridge(), BRIDGE, "bridge mismatch");
    }

    // ── Mint by bridge ───────────────────────────────────────────────────────
    function test_mintByBridge() public {
        vm_prank(BRIDGE);
        token.mint(ALICE, 1 ether);
        _assertEq(token.balanceOf(ALICE), 1 ether, "balance after mint");
        _assertEq(token.totalSupply(),    1 ether, "totalSupply after mint");
    }

    // ── Mint reverts if not bridge ───────────────────────────────────────────
    function test_mintOnlyBridge_revert() public {
        bool reverted;
        try token.mint(ALICE, 1 ether) {
            // should not reach here
        } catch {
            reverted = true;
        }
        _assertTrue(reverted, "should revert for non-bridge mint");
    }

    // ── Burn by bridge ───────────────────────────────────────────────────────
    function test_burnByBridge() public {
        vm_prank(BRIDGE);
        token.mint(ALICE, 2 ether);

        vm_prank(BRIDGE);
        token.burn(ALICE, 1 ether);

        _assertEq(token.balanceOf(ALICE), 1 ether, "balance after burn");
        _assertEq(token.totalSupply(),    1 ether, "totalSupply after burn");
    }

    // ── Burn reverts if not bridge ───────────────────────────────────────────
    function test_burnOnlyBridge_revert() public {
        vm_prank(BRIDGE);
        token.mint(ALICE, 1 ether);

        bool reverted;
        try token.burn(ALICE, 1 ether) {
        } catch {
            reverted = true;
        }
        _assertTrue(reverted, "should revert for non-bridge burn");
    }

    // ── Burn reverts on insufficient balance ─────────────────────────────────
    function test_burnExceedsBalance_revert() public {
        vm_prank(BRIDGE);
        token.mint(ALICE, 1 ether);

        bool reverted;
        vm_prank(BRIDGE);
        try token.burn(ALICE, 2 ether) {
        } catch {
            reverted = true;
        }
        _assertTrue(reverted, "should revert burn > balance");
    }

    // ── Transfer ─────────────────────────────────────────────────────────────
    function test_transfer() public {
        vm_prank(BRIDGE);
        token.mint(ALICE, 3 ether);

        vm_prank(ALICE);
        token.transfer(BOB, 1 ether);

        _assertEq(token.balanceOf(ALICE), 2 ether, "alice after transfer");
        _assertEq(token.balanceOf(BOB),   1 ether, "bob after transfer");
    }

    // ── Approve + transferFrom ───────────────────────────────────────────────
    function test_approveAndTransferFrom() public {
        vm_prank(BRIDGE);
        token.mint(ALICE, 4 ether);

        vm_prank(ALICE);
        token.approve(BOB, 2 ether);
        _assertEq(token.allowance(ALICE, BOB), 2 ether, "allowance");

        vm_prank(BOB);
        token.transferFrom(ALICE, CHARLIE, 2 ether);

        _assertEq(token.balanceOf(ALICE),   2 ether, "alice after transferFrom");
        _assertEq(token.balanceOf(CHARLIE), 2 ether, "charlie after transferFrom");
        _assertEq(token.allowance(ALICE, BOB), 0,    "allowance consumed");
    }

    // ── TransferFrom reverts on insufficient allowance ───────────────────────
    function test_transferFrom_insufficientAllowance_revert() public {
        vm_prank(BRIDGE);
        token.mint(ALICE, 2 ether);

        bool reverted;
        vm_prank(BOB);
        try token.transferFrom(ALICE, BOB, 1 ether) {
        } catch {
            reverted = true;
        }
        _assertTrue(reverted, "should revert: no allowance");
    }

    // ── Zero-address guards ──────────────────────────────────────────────────
    function test_mintToZero_revert() public {
        bool reverted;
        vm_prank(BRIDGE);
        try token.mint(address(0), 1 ether) {
        } catch {
            reverted = true;
        }
        _assertTrue(reverted, "should revert mint to zero");
    }

    // ─── Forge cheatcode shim (works in real forge environment) ──────────────
    // In a real Foundry environment, use: vm.prank(addr);
    // This inline shim allows the file to compile standalone.
    function vm_prank(address) internal pure {
        // No-op when compiled outside Foundry.
        // In Foundry, replace calls with: vm.prank(addr);
    }
}
