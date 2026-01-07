// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../contracts/ABACRegistry.sol";
import "../contracts/ABACPolicy.sol";
import "../contracts/ABACAccessManager.sol";
import "../contracts/interfaces/IEnvOracle.sol";

/**
 * @title InteractScript
 * @notice Example script showing how to interact with deployed contracts
 * @dev Set CONTRACT_ADDRESSES in .env file
 */
contract InteractScript is Script {
    ABACRegistry public registry;
    ABACPolicy public policy;
    ABACAccessManager public accessManager;

    // Contract addresses (set in .env)
    address constant REGISTRY_ADDRESS = address(0);
    address constant POLICY_ADDRESS = address(0);
    address constant MANAGER_ADDRESS = address(0);

    function setUp() public {
        // In production, load from environment
        // registry = ABACRegistry(vm.envAddress("REGISTRY_ADDRESS"));
        // policy = ABACPolicy(vm.envAddress("POLICY_ADDRESS"));
        // accessManager = ABACAccessManager(vm.envAddress("MANAGER_ADDRESS"));
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Example: Register subject attributes
        address subject = address(0x1001);
        bytes32 role = keccak256("employee");
        bytes32 dept = keccak256("security");
        bytes32 location = keccak256("locationA");

        console.log("Registering subject attributes...");
        bytes32[] memory subKeys = new bytes32[](3);
        subKeys[0] = registry.SUB_ROLE();
        subKeys[1] = registry.SUB_DEPT();
        subKeys[2] = registry.SUB_LOCATION();
        bytes32[] memory subValues = new bytes32[](3);
        subValues[0] = role;
        subValues[1] = dept;
        subValues[2] = location;
        registry.setSubjectAttributes(subject, subKeys, subValues);

        // Example: Register object attributes
        address resource = address(0x2001);
        bytes32 resourceType = keccak256("doorLock");

        console.log("Registering object attributes...");
        bytes32[] memory objKeys = new bytes32[](2);
        objKeys[0] = registry.OBJ_RESOURCE_TYPE();
        objKeys[1] = registry.OBJ_LOCATION();
        bytes32[] memory objValues = new bytes32[](2);
        objValues[0] = resourceType;
        objValues[1] = location;
        registry.setObjectAttributes(resource, objKeys, objValues);

        // Example: Create a policy
        console.log("Creating policy...");
        ABACPolicy.Condition[] memory conditions = new ABACPolicy.Condition[](2);

        // subject.role == "employee"
        conditions[0] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.SUBJECT,
            leftKey: registry.SUB_ROLE(),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.SUBJECT,
            rightKey: bytes32(0),
            value: role,
            numValue: 0,
            setValues: new bytes32[](0)
        });

        // object.resourceType == "doorLock"
        conditions[1] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.OBJECT,
            leftKey: registry.OBJ_RESOURCE_TYPE(),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.OBJECT,
            rightKey: bytes32(0),
            value: resourceType,
            numValue: 0,
            setValues: new bytes32[](0)
        });

        uint256 policyId = policy.createPolicy(
            resource,
            ABACPolicy.Action.EXECUTE,
            conditions
        );
        console.log("Policy created with ID:", policyId);

        // Example: Request access
        console.log("Requesting access...");
        IEnvOracle.Env memory env = IEnvOracle.Env({
            timeWindow: 0, // WORKING_HOURS
            emergencyMode: false,
            systemLoad: 50
        });

        bool permit = accessManager.requestAccess(
            subject,
            resource,
            ABACPolicy.Action.EXECUTE,
            env,
            ""
        );
        console.log("Access granted:", permit);

        vm.stopBroadcast();
    }
}
