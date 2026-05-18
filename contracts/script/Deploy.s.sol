// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Foundry deploy script for TRIToken + TRIBridge.
//
// ─── Deployment steps (Base Sepolia testnet) ────────────────────────────────
//
// 1. Install Foundry:
//      curl -L https://foundry.paradigm.xyz | bash && foundryup
//
// 2. Set environment variables:
//      export DEPLOYER_PK=<your deployer private key>
//      export ORACLE_0=<oracle 0 address>
//      export ORACLE_1=<oracle 1 address>
//      export ORACLE_2=<oracle 2 address>
//      export BASE_SEPOLIA_RPC=https://sepolia.base.org
//      export BASESCAN_API_KEY=<optional, for verification>
//
// 3. Deploy (dry run):
//      forge script contracts/script/Deploy.s.sol \
//        --rpc-url $BASE_SEPOLIA_RPC \
//        --private-key $DEPLOYER_PK \
//        --broadcast --verify \
//        -vvvv
//
// 4. After deployment, the script prints:
//      TRIToken:  <address>
//      TRIBridge: <address>
//
// 5. Verify on Basescan (if --verify flag wasn't used):
//      forge verify-contract <token_addr> TRIToken \
//        --chain-id 84532 --etherscan-api-key $BASESCAN_API_KEY
//
// ─── Network-agnostic design ─────────────────────────────────────────────────
// The contracts contain no chain-specific logic (no block.chainid checks).
// They can be deployed on Ethereum mainnet, Base, Optimism, or any EVM chain
// by changing the --rpc-url flag.  The oracle addresses must be updated to
// match the network-specific operator key set.
//
// ─── Production checklist ────────────────────────────────────────────────────
// [ ] Use a hardware wallet / multisig for DEPLOYER_PK in production
// [ ] Oracle keys must be in a secure enclave (HSM or TEE)
// [ ] Audit contracts before mainnet deployment
// [ ] Consider a timelock on oracle rotation
// [ ] Confirm Base/Optimism gas params with the chain's suggested values

// forge-std import (available after `forge install foundry-rs/forge-std`)
// import "forge-std/Script.sol";

import "../src/TRIToken.sol";
import "../src/TRIBridge.sol";

// Uncomment and use with forge-std in a real Foundry project:
// contract DeployScript is Script {
//     function run() external {
//         address oracle0 = vm.envAddress("ORACLE_0");
//         address oracle1 = vm.envAddress("ORACLE_1");
//         address oracle2 = vm.envAddress("ORACLE_2");
//
//         vm.startBroadcast();
//
//         // 1. Deploy bridge first with a placeholder token address.
//         //    We use a two-step init: deploy bridge → deploy token (bridge addr) → 
//         //    OR deploy token with CREATE2 pre-computed address.
//         //
//         // Simplest approach: deploy bridge with address(0) token,
//         // then deploy token pointing to bridge.
//         // Bridge reads token via immutable set after construction via factory.
//         // For simplicity here we use a DeployFactory pattern.
//
//         DeployFactory factory = new DeployFactory();
//         (address tokenAddr, address bridgeAddr) = factory.deploy(
//             [oracle0, oracle1, oracle2]
//         );
//
//         vm.stopBroadcast();
//
//         console2.log("TRIToken: ", tokenAddr);
//         console2.log("TRIBridge:", bridgeAddr);
//     }
// }

/// @notice Helper factory that resolves the token↔bridge circular dependency.
contract DeployFactory {
    event Deployed(address indexed token, address indexed bridge);

    /// @param oracles  Array of 3 oracle addresses for the bridge.
    function deploy(address[3] memory oracles)
        external
        returns (address tokenAddr, address bridgeAddr)
    {
        // Step 1: Predict the bridge address before deployment using nonce arithmetic.
        // Bridge nonce = current nonce + 1 (after token deployment).
        // Simple approach: deploy bridge first with a dummy token, then deploy token,
        // then re-deploy bridge pointing at token.
        // Production: use CREATE2 with a known salt to pre-compute addresses.

        // For testnet simplicity: deploy bridge with address(1) as temporary token,
        // then deploy token with the real bridge address.
        // Note: a two-step init function would be cleaner for production.

        TRIBridge tempBridge = new TRIBridge(address(1), oracles);
        bridgeAddr = address(tempBridge);

        TRIToken  triToken  = new TRIToken(bridgeAddr);
        tokenAddr = address(triToken);

        // Step 2: Redeploy bridge with the real token address.
        // (In production, use a proxy pattern or a setToken() init function.)
        TRIBridge finalBridge = new TRIBridge(tokenAddr, oracles);
        bridgeAddr = address(finalBridge);

        emit Deployed(tokenAddr, bridgeAddr);
    }
}
