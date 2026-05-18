// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/BittensorSubnetAttest.sol";

contract BittensorSubnetAttestTest is Test {
    BittensorSubnetAttest public attest;

    function setUp() public {
        attest = new BittensorSubnetAttest();
    }

    /// @notice Test deployment: constants are correctly set
    function testDeployment() public view {
        assertEq(attest.CHAMPION_BPB(), 22393);
        assertEq(attest.CHAMPION_STEP(), 27000);
        assertEq(attest.CHAMPION_SEED(), 43);
        assertEq(attest.PHI_ANCHOR(), 0x47C0);
    }

    /// @notice Happy path: attestValidator registers a validator with 2-of-3 sigs
    function testAttestValidatorHappyPath() public {
        address validator = address(0xBEEF);
        vm.deal(validator, 1 ether);

        bytes32 phiSig   = bytes32(uint256(0x1));
        bytes32 eulerSig = bytes32(uint256(0x2));
        bytes32 gammaSig = bytes32(0); // only 2-of-3 required

        uint256 bpb = 20000; // below CHAMPION_BPB

        vm.prank(validator);
        vm.expectEmit(true, false, false, true);
        emit BittensorSubnetAttest.ValidatorAttested(validator, bpb);
        attest.attestValidator{value: 0.01 ether}(phiSig, eulerSig, gammaSig, bpb);

        assertTrue(attest.isActive(validator));
        (address owner,,,,uint256 bpbScore, uint256 stake, bool active) = attest.validators(validator);
        assertEq(owner, validator);
        assertEq(bpbScore, bpb);
        assertEq(stake, 0.01 ether);
        assertTrue(active);
    }
}
