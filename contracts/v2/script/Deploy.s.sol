// SPDX-License-Identifier: Apache-2.0
// Author: Dmitrii Vasilev (sole author, admin@t27.ai)
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/TriToken.sol";
import "../src/MiningPool.sol";
import "../src/EmissionController.sol";

/// @notice Minimal chip registry used for Base Sepolia testnet deployment.
///         Production deployment must substitute a real registry contract
///         that the Trinity hardware tape-out keys feed into.
contract MockChipRegistry {
    mapping(bytes32 => bool) public registered;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function register(bytes32 pubkey) external {
        require(msg.sender == owner, "MockChipRegistry: not owner");
        registered[pubkey] = true;
    }

    function isRegistered(bytes32 pubkey) external view returns (bool) {
        return registered[pubkey];
    }
}

/// @title  Trinity Network -- Genesis Deployment
/// @notice Deploys the Trinity tokenomics v2 (3^27 supply) contract stack
///         to Base Sepolia (chainId 84532) or Base mainnet (8453).
///
///         Deployment order resolves the circular dependency between
///         TriToken (mints supply to MiningPool in its constructor) and
///         MiningPool (constructor takes the TriToken address) by
///         pre-computing the TriToken deployment address from the
///         deployer's nonce.
///
///         Sequence:
///           nonce+0: EmissionController
///           nonce+1: MockChipRegistry  (Sepolia only -- real registry on mainnet)
///           nonce+2: MiningPool        (constructor references predicted TriToken)
///           nonce+3: TriToken          (mints to MiningPool, renounces ownership)
///
///         Post-deploy assertions confirm:
///           - total supply == 3^27 * 10^18
///           - 100% of supply held by MiningPool
///           - all owners renounced (TriToken auto-renounces in constructor)
///
/// @author Dmitrii Vasilev (admin@t27.ai)
contract DeployTrinity is Script {
    /// @notice Expected total supply in wei (3^27 * 10^18).
    uint256 public constant EXPECTED_SUPPLY_WEI = 7_625_597_484_987 * 10 ** 18;

    function run() external {
        uint256 deployerPk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPk);
        uint256 genesisTs = vm.envOr("GENESIS_TIMESTAMP", block.timestamp);

        console.log("==== Trinity Network -- Genesis Deployment ====");
        console.log("Deployer:           %s", deployer);
        console.log("Chain ID:           %d", block.chainid);
        console.log("Block:              %d", block.number);
        console.log("Genesis timestamp:  %d", genesisTs);
        console.log("Expected supply:    7,625,597,484,987 TRI (3^27)");
        console.log("");

        // ── Predict TriToken address (deployer nonce + 3) ───────────────────
        uint256 startingNonce = vm.getNonce(deployer);
        address predictedTriToken = vm.computeCreateAddress(deployer, startingNonce + 3);
        console.log("Predicted TriToken: %s", predictedTriToken);
        console.log("");

        vm.startBroadcast(deployerPk);

        // nonce + 0 -- EmissionController
        EmissionController emission = new EmissionController(genesisTs);

        // nonce + 1 -- MockChipRegistry (Sepolia only; replace for mainnet)
        MockChipRegistry registry = new MockChipRegistry();

        // nonce + 2 -- MiningPool (refers to predicted TriToken)
        MiningPool pool = new MiningPool(
            predictedTriToken,
            address(registry),
            genesisTs
        );

        // nonce + 3 -- TriToken (mints to pool, auto-renounces ownership)
        TriToken token = new TriToken(address(pool));

        // Renounce mining pool ownership too (immutable forever).
        pool.renounceOwnership();

        vm.stopBroadcast();

        // ── Sanity checks (revert on any mismatch) ──────────────────────────
        require(address(token) == predictedTriToken, "TriToken address mismatch");
        require(token.totalSupply() == EXPECTED_SUPPLY_WEI, "TOTAL_SUPPLY mismatch");
        require(
            token.balanceOf(address(pool)) == EXPECTED_SUPPLY_WEI,
            "Pool must hold 100% of supply"
        );
        require(token.owner() == address(0), "TriToken owner not renounced");
        require(pool.owner() == address(0), "MiningPool owner not renounced");

        console.log("==== Deployment Successful ====");
        console.log("TriToken:            %s", address(token));
        console.log("MiningPool:          %s", address(pool));
        console.log("EmissionController:  %s", address(emission));
        console.log("MockChipRegistry:    %s", address(registry));
        console.log("Total supply (wei):  %d", token.totalSupply());
        console.log("Locked in pool:      %d", token.balanceOf(address(pool)));
        console.log("Ownerships renounced (token+pool): YES");
        console.log("");
        console.log("Basescan (Sepolia):");
        console.log("  https://sepolia.basescan.org/address/%s", address(token));
    }
}
