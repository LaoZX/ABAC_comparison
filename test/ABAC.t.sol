// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/ABACRegistry.sol";
import "../contracts/ABACPolicy.sol";
import "../contracts/ABACAccessManager.sol";
import "../contracts/mocks/MockEnvOracle.sol";
import "../contracts/interfaces/IEnvOracle.sol";

/**
 * @title ABACTests
 * @notice Comprehensive test suite for ABAC system
 */
contract ABACTests is Test {
    ABACRegistry public registry;
    ABACPolicy public policy;
    ABACAccessManager public accessManager;
    MockEnvOracle public oracle;

    // Test addresses
    address public admin = address(1);
    address public subject1 = address(0x1001);
    address public subject2 = address(0x1002);
    address public resource1 = address(0x2001); // doorLock
    address public resource2 = address(0x2002); // monitor

    // Attribute values (bytes32)
    bytes32 public constant EMPLOYEE = keccak256("employee");
    bytes32 public constant SECURITY_DEPT = keccak256("security");
    bytes32 public constant DOOR_LOCK = keccak256("doorLock");
    bytes32 public constant MONITOR = keccak256("monitor");
    bytes32 public constant COMPUTER = keccak256("computer");
    bytes32 public constant LOCATION_A = keccak256("locationA");
    bytes32 public constant LOCATION_B = keccak256("locationB");

    // Environment constants
    uint8 public constant WORKING_HOURS = 0;
    uint8 public constant OFF_HOURS = 1;

    function setUp() public {
        // Deploy contracts
        vm.startPrank(admin);
        registry = new ABACRegistry();
        registry.transferOwnership(admin);
        policy = new ABACPolicy(address(registry));
        policy.transferOwnership(admin);
        accessManager = new ABACAccessManager(address(registry), address(policy));
        accessManager.transferOwnership(admin);
        oracle = new MockEnvOracle();

        // Set up oracle to always accept for basic tests
        oracle.setAlwaysAccept(true);
        accessManager.setEnvOracle(address(oracle));

        vm.stopPrank();
    }

    // Helper function to create environment
    function createEnv(
        uint8 timeWindow,
        bool emergencyMode,
        uint256 systemLoad
    ) internal pure returns (IEnvOracle.Env memory) {
        return
            IEnvOracle.Env({
                timeWindow: timeWindow,
                emergencyMode: emergencyMode,
                systemLoad: systemLoad
            });
    }

    // Test 1: Register subject attributes
    function test_RegisterSubjectAttributes() public {
        bytes32[] memory keys1 = new bytes32[](3);
        keys1[0] = ABACRegistry(registry).SUB_ROLE();
        keys1[1] = ABACRegistry(registry).SUB_DEPT();
        keys1[2] = ABACRegistry(registry).SUB_LOCATION();
        bytes32[] memory values1 = new bytes32[](3);
        values1[0] = EMPLOYEE;
        values1[1] = SECURITY_DEPT;
        values1[2] = LOCATION_A;
        vm.prank(subject1);
        registry.setSubjectAttributes(subject1, keys1, values1);

        assertEq(registry.subjectAttr(subject1, registry.SUB_ROLE()), EMPLOYEE);
        assertEq(
            registry.subjectAttr(subject1, registry.SUB_DEPT()),
            SECURITY_DEPT
        );
        assertEq(
            registry.subjectAttr(subject1, registry.SUB_LOCATION()),
            LOCATION_A
        );
        assertTrue(registry.isSubjectRegistered(subject1));
    }

    // Test 2: Register object attributes
    function test_RegisterObjectAttributes() public {
        bytes32[] memory keys2 = new bytes32[](2);
        keys2[0] = registry.OBJ_RESOURCE_TYPE();
        keys2[1] = registry.OBJ_LOCATION();
        bytes32[] memory values2 = new bytes32[](2);
        values2[0] = DOOR_LOCK;
        values2[1] = LOCATION_A;
        vm.prank(admin);
        registry.setObjectAttributes(resource1, keys2, values2);

        assertEq(
            registry.objectAttr(resource1, registry.OBJ_RESOURCE_TYPE()),
            DOOR_LOCK
        );
        assertEq(
            registry.objectAttr(resource1, registry.OBJ_LOCATION()),
            LOCATION_A
        );
        assertTrue(registry.isObjectRegistered(resource1));
    }

    // Test 3: Policy A - Employee + doorLock + location match + working hours + EXECUTE
    function test_PolicyA_EmployeeDoorLockLocationMatch() public {
        // Register subject
        bytes32[] memory keys3a = new bytes32[](2);
        keys3a[0] = registry.SUB_ROLE();
        keys3a[1] = registry.SUB_LOCATION();
        bytes32[] memory values3a = new bytes32[](2);
        values3a[0] = EMPLOYEE;
        values3a[1] = LOCATION_A;
        vm.prank(subject1);
        registry.setSubjectAttributes(subject1, keys3a, values3a);

        // Register object
        bytes32[] memory keys3b = new bytes32[](2);
        keys3b[0] = registry.OBJ_RESOURCE_TYPE();
        keys3b[1] = registry.OBJ_LOCATION();
        bytes32[] memory values3b = new bytes32[](2);
        values3b[0] = DOOR_LOCK;
        values3b[1] = LOCATION_A;
        vm.prank(admin);
        registry.setObjectAttributes(resource1, keys3b, values3b);

        // Create policy: permit if employee AND resourceType=doorLock AND
        // subject.location==object.location AND timeWindow=WORKING_HOURS AND action=EXECUTE
        ABACPolicy.Condition[] memory conditions = new ABACPolicy.Condition[](4);

        // subject.role == EMPLOYEE
        conditions[0] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.SUBJECT,
            leftKey: registry.SUB_ROLE(),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.SUBJECT,
            rightKey: bytes32(0),
            value: EMPLOYEE,
            numValue: 0,
            setValues: new bytes32[](0)
        });

        // object.resourceType == DOOR_LOCK
        conditions[1] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.OBJECT,
            leftKey: registry.OBJ_RESOURCE_TYPE(),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.OBJECT,
            rightKey: bytes32(0),
            value: DOOR_LOCK,
            numValue: 0,
            setValues: new bytes32[](0)
        });

        // subject.location == object.location
        conditions[2] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.SUBJECT,
            leftKey: registry.SUB_LOCATION(),
            op: ABACPolicy.Operator.EQ_FIELD,
            rightSource: ABACPolicy.AttrSource.OBJECT,
            rightKey: registry.OBJ_LOCATION(),
            value: bytes32(0),
            numValue: 0,
            setValues: new bytes32[](0)
        });

        // env.timeWindow == WORKING_HOURS
        conditions[3] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.ENV,
            leftKey: keccak256("timeWindow"),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.ENV,
            rightKey: bytes32(0),
            value: bytes32(uint256(WORKING_HOURS)),
            numValue: 0,
            setValues: new bytes32[](0)
        });

        vm.prank(admin);
        uint256 policyId = policy.createPolicy(
            resource1,
            ABACPolicy.Action.EXECUTE,
            conditions
        );

        // Test access request - should permit
        IEnvOracle.Env memory env = createEnv(WORKING_HOURS, false, 50);
        (bool permit, uint256 matchedId) = accessManager.checkAccess(
            subject1,
            resource1,
            ABACPolicy.Action.EXECUTE,
            env
        );

        assertTrue(permit);
        assertEq(matchedId, policyId);

        // Test with requestAccess (should emit event)
        bool result = accessManager.requestAccess(
            subject1,
            resource1,
            ABACPolicy.Action.EXECUTE,
            env,
            ""
        );
        assertTrue(result);
    }

    // Test 4: Policy A - Negative test: wrong location
    function test_PolicyA_WrongLocation() public {
        // Register subject with different location
        bytes32[] memory keys4a = new bytes32[](2);
        keys4a[0] = registry.SUB_ROLE();
        keys4a[1] = registry.SUB_LOCATION();
        bytes32[] memory values4a = new bytes32[](2);
        values4a[0] = EMPLOYEE;
        values4a[1] = LOCATION_B; // Different location
        vm.prank(subject1);
        registry.setSubjectAttributes(subject1, keys4a, values4a);

        bytes32[] memory keys4b = new bytes32[](2);
        keys4b[0] = registry.OBJ_RESOURCE_TYPE();
        keys4b[1] = registry.OBJ_LOCATION();
        bytes32[] memory values4b = new bytes32[](2);
        values4b[0] = DOOR_LOCK;
        values4b[1] = LOCATION_A;
        vm.prank(admin);
        registry.setObjectAttributes(resource1, keys4b, values4b);

        // Create same policy as test 3
        ABACPolicy.Condition[] memory conditions = new ABACPolicy.Condition[](4);
        conditions[0] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.SUBJECT,
            leftKey: registry.SUB_ROLE(),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.SUBJECT,
            rightKey: bytes32(0),
            value: EMPLOYEE,
            numValue: 0,
            setValues: new bytes32[](0)
        });
        conditions[1] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.OBJECT,
            leftKey: registry.OBJ_RESOURCE_TYPE(),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.OBJECT,
            rightKey: bytes32(0),
            value: DOOR_LOCK,
            numValue: 0,
            setValues: new bytes32[](0)
        });
        conditions[2] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.SUBJECT,
            leftKey: registry.SUB_LOCATION(),
            op: ABACPolicy.Operator.EQ_FIELD,
            rightSource: ABACPolicy.AttrSource.OBJECT,
            rightKey: registry.OBJ_LOCATION(),
            value: bytes32(0),
            numValue: 0,
            setValues: new bytes32[](0)
        });
        conditions[3] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.ENV,
            leftKey: keccak256("timeWindow"),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.ENV,
            rightKey: bytes32(0),
            value: bytes32(uint256(WORKING_HOURS)),
            numValue: 0,
            setValues: new bytes32[](0)
        });

        vm.prank(admin);
        policy.createPolicy(resource1, ABACPolicy.Action.EXECUTE, conditions);

        IEnvOracle.Env memory env = createEnv(WORKING_HOURS, false, 50);
        (bool permit, ) = accessManager.checkAccess(
            subject1,
            resource1,
            ABACPolicy.Action.EXECUTE,
            env
        );

        assertFalse(permit); // Should deny due to location mismatch
    }

    // Test 5: Policy A - Negative test: off-hours
    function test_PolicyA_OffHours() public {
        bytes32[] memory keys5a = new bytes32[](2);
        keys5a[0] = registry.SUB_ROLE();
        keys5a[1] = registry.SUB_LOCATION();
        bytes32[] memory values5a = new bytes32[](2);
        values5a[0] = EMPLOYEE;
        values5a[1] = LOCATION_A;
        vm.prank(subject1);
        registry.setSubjectAttributes(subject1, keys5a, values5a);

        bytes32[] memory keys5b = new bytes32[](2);
        keys5b[0] = registry.OBJ_RESOURCE_TYPE();
        keys5b[1] = registry.OBJ_LOCATION();
        bytes32[] memory values5b = new bytes32[](2);
        values5b[0] = DOOR_LOCK;
        values5b[1] = LOCATION_A;
        vm.prank(admin);
        registry.setObjectAttributes(resource1, keys5b, values5b);

        // Create policy (same as test 3)
        ABACPolicy.Condition[] memory conditions = new ABACPolicy.Condition[](4);
        conditions[0] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.SUBJECT,
            leftKey: registry.SUB_ROLE(),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.SUBJECT,
            rightKey: bytes32(0),
            value: EMPLOYEE,
            numValue: 0,
            setValues: new bytes32[](0)
        });
        conditions[1] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.OBJECT,
            leftKey: registry.OBJ_RESOURCE_TYPE(),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.OBJECT,
            rightKey: bytes32(0),
            value: DOOR_LOCK,
            numValue: 0,
            setValues: new bytes32[](0)
        });
        conditions[2] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.SUBJECT,
            leftKey: registry.SUB_LOCATION(),
            op: ABACPolicy.Operator.EQ_FIELD,
            rightSource: ABACPolicy.AttrSource.OBJECT,
            rightKey: registry.OBJ_LOCATION(),
            value: bytes32(0),
            numValue: 0,
            setValues: new bytes32[](0)
        });
        conditions[3] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.ENV,
            leftKey: keccak256("timeWindow"),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.ENV,
            rightKey: bytes32(0),
            value: bytes32(uint256(WORKING_HOURS)),
            numValue: 0,
            setValues: new bytes32[](0)
        });

        vm.prank(admin);
        policy.createPolicy(resource1, ABACPolicy.Action.EXECUTE, conditions);

        // Request access during off-hours
        IEnvOracle.Env memory env = createEnv(OFF_HOURS, false, 50);
        (bool permit, ) = accessManager.checkAccess(
            subject1,
            resource1,
            ABACPolicy.Action.EXECUTE,
            env
        );

        assertFalse(permit); // Should deny due to off-hours
    }

    // Test 6: Policy B - Security dept + computer + monitor + emergencyMode + READ
    function test_PolicyB_SecurityDeptEmergencyMode() public {
        bytes32[] memory keys6a = new bytes32[](2);
        keys6a[0] = registry.SUB_DEPT();
        keys6a[1] = registry.SUB_DEV_TYPE();
        bytes32[] memory values6a = new bytes32[](2);
        values6a[0] = SECURITY_DEPT;
        values6a[1] = COMPUTER;
        vm.prank(subject2);
        registry.setSubjectAttributes(subject2, keys6a, values6a);

        bytes32[] memory keys6b = new bytes32[](1);
        keys6b[0] = registry.OBJ_RESOURCE_TYPE();
        bytes32[] memory values6b = new bytes32[](1);
        values6b[0] = MONITOR;
        vm.prank(admin);
        registry.setObjectAttributes(resource2, keys6b, values6b);

        // Create policy: permit if security dept AND deviceType=computer AND
        // resourceType=monitor AND emergencyMode=true AND action=READ
        ABACPolicy.Condition[] memory conditions = new ABACPolicy.Condition[](4);

        conditions[0] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.SUBJECT,
            leftKey: registry.SUB_DEPT(),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.SUBJECT,
            rightKey: bytes32(0),
            value: SECURITY_DEPT,
            numValue: 0,
            setValues: new bytes32[](0)
        });

        conditions[1] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.SUBJECT,
            leftKey: registry.SUB_DEV_TYPE(),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.SUBJECT,
            rightKey: bytes32(0),
            value: COMPUTER,
            numValue: 0,
            setValues: new bytes32[](0)
        });

        conditions[2] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.OBJECT,
            leftKey: registry.OBJ_RESOURCE_TYPE(),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.OBJECT,
            rightKey: bytes32(0),
            value: MONITOR,
            numValue: 0,
            setValues: new bytes32[](0)
        });

        conditions[3] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.ENV,
            leftKey: keccak256("emergencyMode"),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.ENV,
            rightKey: bytes32(0),
            value: bytes32(uint256(1)), // true
            numValue: 0,
            setValues: new bytes32[](0)
        });

        vm.prank(admin);
        uint256 policyId = policy.createPolicy(
            resource2,
            ABACPolicy.Action.READ,
            conditions
        );

        // Test with emergency mode on
        IEnvOracle.Env memory env = createEnv(WORKING_HOURS, true, 50);
        (bool permit, uint256 matchedId) = accessManager.checkAccess(
            subject2,
            resource2,
            ABACPolicy.Action.READ,
            env
        );

        assertTrue(permit);
        assertEq(matchedId, policyId);
    }

    // Test 7: Policy B - Negative test: emergency mode off
    function test_PolicyB_NoEmergencyMode() public {
        bytes32[] memory keys7a = new bytes32[](2);
        keys7a[0] = registry.SUB_DEPT();
        keys7a[1] = registry.SUB_DEV_TYPE();
        bytes32[] memory values7a = new bytes32[](2);
        values7a[0] = SECURITY_DEPT;
        values7a[1] = COMPUTER;
        vm.prank(subject2);
        registry.setSubjectAttributes(subject2, keys7a, values7a);

        bytes32[] memory keys7b = new bytes32[](1);
        keys7b[0] = registry.OBJ_RESOURCE_TYPE();
        bytes32[] memory values7b = new bytes32[](1);
        values7b[0] = MONITOR;
        vm.prank(admin);
        registry.setObjectAttributes(resource2, keys7b, values7b);

        // Create same policy as test 6
        ABACPolicy.Condition[] memory conditions = new ABACPolicy.Condition[](4);
        conditions[0] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.SUBJECT,
            leftKey: registry.SUB_DEPT(),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.SUBJECT,
            rightKey: bytes32(0),
            value: SECURITY_DEPT,
            numValue: 0,
            setValues: new bytes32[](0)
        });
        conditions[1] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.SUBJECT,
            leftKey: registry.SUB_DEV_TYPE(),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.SUBJECT,
            rightKey: bytes32(0),
            value: COMPUTER,
            numValue: 0,
            setValues: new bytes32[](0)
        });
        conditions[2] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.OBJECT,
            leftKey: registry.OBJ_RESOURCE_TYPE(),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.OBJECT,
            rightKey: bytes32(0),
            value: MONITOR,
            numValue: 0,
            setValues: new bytes32[](0)
        });
        conditions[3] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.ENV,
            leftKey: keccak256("emergencyMode"),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.ENV,
            rightKey: bytes32(0),
            value: bytes32(uint256(1)),
            numValue: 0,
            setValues: new bytes32[](0)
        });

        vm.prank(admin);
        policy.createPolicy(resource2, ABACPolicy.Action.READ, conditions);

        // Test without emergency mode
        IEnvOracle.Env memory env = createEnv(WORKING_HOURS, false, 50);
        (bool permit, ) = accessManager.checkAccess(
            subject2,
            resource2,
            ABACPolicy.Action.READ,
            env
        );

        assertFalse(permit);
    }

    // Test 8: Policy C - Deny by default (no policy matches)
    function test_PolicyC_DenyByDefault() public {
        bytes32[] memory keys8a = new bytes32[](1);
        keys8a[0] = registry.SUB_ROLE();
        bytes32[] memory values8a = new bytes32[](1);
        values8a[0] = EMPLOYEE;
        vm.prank(subject1);
        registry.setSubjectAttributes(subject1, keys8a, values8a);

        bytes32[] memory keys8b = new bytes32[](1);
        keys8b[0] = registry.OBJ_RESOURCE_TYPE();
        bytes32[] memory values8b = new bytes32[](1);
        values8b[0] = DOOR_LOCK;
        vm.prank(admin);
        registry.setObjectAttributes(resource1, keys8b, values8b);

        // No policies created - should deny by default
        IEnvOracle.Env memory env = createEnv(WORKING_HOURS, false, 50);
        (bool permit, ) = accessManager.checkAccess(
            subject1,
            resource1,
            ABACPolicy.Action.EXECUTE,
            env
        );

        assertFalse(permit);
    }

    // Test 9: System load check (numeric comparison)
    function test_SystemLoadCondition() public {
        bytes32[] memory keys9a = new bytes32[](1);
        keys9a[0] = registry.SUB_ROLE();
        bytes32[] memory values9a = new bytes32[](1);
        values9a[0] = EMPLOYEE;
        vm.prank(subject1);
        registry.setSubjectAttributes(subject1, keys9a, values9a);

        bytes32[] memory keys9b = new bytes32[](1);
        keys9b[0] = registry.OBJ_RESOURCE_TYPE();
        bytes32[] memory values9b = new bytes32[](1);
        values9b[0] = DOOR_LOCK;
        vm.prank(admin);
        registry.setObjectAttributes(resource1, keys9b, values9b);

        // Policy: permit if employee AND systemLoad <= 80
        ABACPolicy.Condition[] memory conditions = new ABACPolicy.Condition[](2);
        conditions[0] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.SUBJECT,
            leftKey: registry.SUB_ROLE(),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.SUBJECT,
            rightKey: bytes32(0),
            value: EMPLOYEE,
            numValue: 0,
            setValues: new bytes32[](0)
        });
        conditions[1] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.ENV,
            leftKey: keccak256("systemLoad"),
            op: ABACPolicy.Operator.LE,
            rightSource: ABACPolicy.AttrSource.ENV,
            rightKey: bytes32(0),
            value: bytes32(0),
            numValue: 80,
            setValues: new bytes32[](0)
        });

        vm.prank(admin);
        policy.createPolicy(resource1, ABACPolicy.Action.READ, conditions);

        // Test with systemLoad = 50 (should permit)
        IEnvOracle.Env memory env = createEnv(WORKING_HOURS, false, 50);
        (bool permit1, ) = accessManager.checkAccess(
            subject1,
            resource1,
            ABACPolicy.Action.READ,
            env
        );
        assertTrue(permit1);

        // Test with systemLoad = 80 (should permit)
        env = createEnv(WORKING_HOURS, false, 80);
        (bool permit2, ) = accessManager.checkAccess(
            subject1,
            resource1,
            ABACPolicy.Action.READ,
            env
        );
        assertTrue(permit2);

        // Test with systemLoad = 90 (should deny)
        env = createEnv(WORKING_HOURS, false, 90);
        (bool permit3, ) = accessManager.checkAccess(
            subject1,
            resource1,
            ABACPolicy.Action.READ,
            env
        );
        assertFalse(permit3);
    }

    // Test 10: Policy disabled
    function test_PolicyDisabled() public {
        bytes32[] memory keys10a = new bytes32[](1);
        keys10a[0] = registry.SUB_ROLE();
        bytes32[] memory values10a = new bytes32[](1);
        values10a[0] = EMPLOYEE;
        vm.prank(subject1);
        registry.setSubjectAttributes(subject1, keys10a, values10a);

        bytes32[] memory keys10b = new bytes32[](1);
        keys10b[0] = registry.OBJ_RESOURCE_TYPE();
        bytes32[] memory values10b = new bytes32[](1);
        values10b[0] = DOOR_LOCK;
        vm.prank(admin);
        registry.setObjectAttributes(resource1, keys10b, values10b);

        ABACPolicy.Condition[] memory conditions = new ABACPolicy.Condition[](1);
        conditions[0] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.SUBJECT,
            leftKey: registry.SUB_ROLE(),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.SUBJECT,
            rightKey: bytes32(0),
            value: EMPLOYEE,
            numValue: 0,
            setValues: new bytes32[](0)
        });

        vm.prank(admin);
        uint256 policyId = policy.createPolicy(
            resource1,
            ABACPolicy.Action.READ,
            conditions
        );

        // Disable policy
        vm.prank(admin);
        policy.setPolicyEnabled(policyId, false);

        IEnvOracle.Env memory env = createEnv(WORKING_HOURS, false, 50);
        (bool permit, ) = accessManager.checkAccess(
            subject1,
            resource1,
            ABACPolicy.Action.READ,
            env
        );

        assertFalse(permit);
    }

    // Test 11: Oracle verification
    function test_OracleVerification() public {
        // Disable always accept (need admin prank)
        vm.prank(admin);
        oracle.setAlwaysAccept(false);

        bytes32[] memory keys11a = new bytes32[](1);
        keys11a[0] = registry.SUB_ROLE();
        bytes32[] memory values11a = new bytes32[](1);
        values11a[0] = EMPLOYEE;
        vm.prank(subject1);
        registry.setSubjectAttributes(subject1, keys11a, values11a);

        bytes32[] memory keys11b = new bytes32[](1);
        keys11b[0] = registry.OBJ_RESOURCE_TYPE();
        bytes32[] memory values11b = new bytes32[](1);
        values11b[0] = DOOR_LOCK;
        vm.prank(admin);
        registry.setObjectAttributes(resource1, keys11b, values11b);

        ABACPolicy.Condition[] memory conditions = new ABACPolicy.Condition[](1);
        conditions[0] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.SUBJECT,
            leftKey: registry.SUB_ROLE(),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.SUBJECT,
            rightKey: bytes32(0),
            value: EMPLOYEE,
            numValue: 0,
            setValues: new bytes32[](0)
        });

        vm.prank(admin);
        policy.createPolicy(resource1, ABACPolicy.Action.READ, conditions);

        IEnvOracle.Env memory env = createEnv(WORKING_HOURS, false, 50);
        bytes memory invalidProof = "invalid";

        // Should fail with invalid proof
        vm.expectRevert("ABACAccessManager: env verification failed");
        accessManager.requestAccess(
            subject1,
            resource1,
            ABACPolicy.Action.READ,
            env,
            invalidProof
        );

        // Mark proof as valid (need admin prank)
        bytes32 proofHash = keccak256("valid_proof");
        vm.prank(admin);
        oracle.setValidProof(proofHash, true);

        // Should succeed with valid proof
        bool permit = accessManager.requestAccess(
            subject1,
            resource1,
            ABACPolicy.Action.READ,
            env,
            "valid_proof"
        );
        assertTrue(permit);
    }

    // Test 12: Multiple sequential requests
    function test_MultipleSequentialRequests() public {
        bytes32[] memory keys12a = new bytes32[](1);
        keys12a[0] = registry.SUB_ROLE();
        bytes32[] memory values12a = new bytes32[](1);
        values12a[0] = EMPLOYEE;
        vm.prank(subject1);
        registry.setSubjectAttributes(subject1, keys12a, values12a);

        bytes32[] memory keys12b = new bytes32[](1);
        keys12b[0] = registry.OBJ_RESOURCE_TYPE();
        bytes32[] memory values12b = new bytes32[](1);
        values12b[0] = DOOR_LOCK;
        vm.prank(admin);
        registry.setObjectAttributes(resource1, keys12b, values12b);

        ABACPolicy.Condition[] memory conditions = new ABACPolicy.Condition[](1);
        conditions[0] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.SUBJECT,
            leftKey: registry.SUB_ROLE(),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.SUBJECT,
            rightKey: bytes32(0),
            value: EMPLOYEE,
            numValue: 0,
            setValues: new bytes32[](0)
        });

        vm.prank(admin);
        policy.createPolicy(resource1, ABACPolicy.Action.READ, conditions);

        IEnvOracle.Env memory env = createEnv(WORKING_HOURS, false, 50);

        // Multiple sequential requests
        for (uint256 i = 0; i < 5; i++) {
            (bool permit, ) = accessManager.checkAccess(
                subject1,
                resource1,
                ABACPolicy.Action.READ,
                env
            );
            assertTrue(permit);
        }
    }

    // Test 13: IN_SET operator
    function test_InSetOperator() public {
        bytes32[] memory keys13a = new bytes32[](1);
        keys13a[0] = registry.SUB_ROLE();
        bytes32[] memory values13a = new bytes32[](1);
        values13a[0] = EMPLOYEE;
        vm.prank(subject1);
        registry.setSubjectAttributes(subject1, keys13a, values13a);

        bytes32[] memory keys13b = new bytes32[](1);
        keys13b[0] = registry.OBJ_RESOURCE_TYPE();
        bytes32[] memory values13b = new bytes32[](1);
        values13b[0] = DOOR_LOCK;
        vm.prank(admin);
        registry.setObjectAttributes(resource1, keys13b, values13b);

        bytes32[] memory timeWindows = new bytes32[](2);
        timeWindows[0] = bytes32(uint256(WORKING_HOURS));
        timeWindows[1] = bytes32(uint256(OFF_HOURS));

        ABACPolicy.Condition[] memory conditions = new ABACPolicy.Condition[](2);
        conditions[0] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.SUBJECT,
            leftKey: registry.SUB_ROLE(),
            op: ABACPolicy.Operator.EQ,
            rightSource: ABACPolicy.AttrSource.SUBJECT,
            rightKey: bytes32(0),
            value: EMPLOYEE,
            numValue: 0,
            setValues: new bytes32[](0)
        });
        conditions[1] = ABACPolicy.Condition({
            leftSource: ABACPolicy.AttrSource.ENV,
            leftKey: keccak256("timeWindow"),
            op: ABACPolicy.Operator.IN_SET,
            rightSource: ABACPolicy.AttrSource.ENV,
            rightKey: bytes32(0),
            value: bytes32(0),
            numValue: 0,
            setValues: timeWindows
        });

        vm.prank(admin);
        policy.createPolicy(resource1, ABACPolicy.Action.READ, conditions);

        // Should permit with WORKING_HOURS
        IEnvOracle.Env memory env = createEnv(WORKING_HOURS, false, 50);
        (bool permit1, ) = accessManager.checkAccess(
            subject1,
            resource1,
            ABACPolicy.Action.READ,
            env
        );
        assertTrue(permit1);

        // Should permit with OFF_HOURS
        env = createEnv(OFF_HOURS, false, 50);
        (bool permit2, ) = accessManager.checkAccess(
            subject1,
            resource1,
            ABACPolicy.Action.READ,
            env
        );
        assertTrue(permit2);
    }
}
