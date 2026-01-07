// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../contracts/ABACRegistry.sol";
import "../contracts/ABACPolicy.sol";
import "../contracts/ABACAccessManager.sol";
import "../contracts/mocks/MockEnvOracle.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Registry
        console.log("Deploying ABACRegistry...");
        ABACRegistry registry = new ABACRegistry();
        console.log("ABACRegistry deployed at:", address(registry));

        // Deploy Policy
        console.log("Deploying ABACPolicy...");
        ABACPolicy policy = new ABACPolicy(address(registry));
        console.log("ABACPolicy deployed at:", address(policy));

        // Deploy AccessManager
        console.log("Deploying ABACAccessManager...");
        ABACAccessManager accessManager = new ABACAccessManager(
            address(registry),
            address(policy)
        );
        console.log("ABACAccessManager deployed at:", address(accessManager));

        // Optional: Deploy Mock Oracle
        console.log("Deploying MockEnvOracle...");
        MockEnvOracle oracle = new MockEnvOracle();
        console.log("MockEnvOracle deployed at:", address(oracle));

        // Set oracle in access manager
        accessManager.setEnvOracle(address(oracle));
        console.log("Oracle set in AccessManager");

        vm.stopBroadcast();

        // Print deployment summary
        console.log("\n=== Deployment Summary ===");
        console.log("Registry:", address(registry));
        console.log("Policy:", address(policy));
        console.log("AccessManager:", address(accessManager));
        console.log("Oracle:", address(oracle));
    }
}
