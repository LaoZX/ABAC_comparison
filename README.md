# ABAC Smart Contract System

A production-quality Attribute-Based Access Control (ABAC) system implemented as Ethereum smart contracts. This system enables fine-grained access control for IoT resources based on subject attributes, object attributes, and environment conditions.

## Overview

This ABAC system provides:

- **Subject Attributes**: Role, organization, department, office, device type, location
- **Object Attributes**: Resource type, owner department, sensitivity level, location
- **Environment Attributes**: Time window, emergency mode, system load
- **Policy Evaluation**: On-chain policy evaluation with multiple operators (EQ, NEQ, LE, LT, GE, GT, IN_SET, EQ_FIELD)
- **Audit Trail**: All access decisions are recorded on-chain via events

## Architecture

The system consists of three main contracts:

1. **ABACRegistry.sol**: Stores subject and object attributes
2. **ABACPolicy.sol**: Defines, stores, and evaluates access control policies
3. **ABACAccessManager.sol**: Main entry point for access requests

Additionally, an optional `IEnvOracle.sol` interface allows for environment attribute verification.

## Installation

This project uses [Foundry](https://book.getfoundry.sh/) for development and testing.

### Option 1: Docker (Recommended - No Installation Needed!)

If you have Docker Desktop installed, you can run everything in a container:

```bash
# Build the Docker image
docker-compose build

# Run tests
docker-compose run --rm abac-dev forge test
```

See [DOCKER_SETUP.md](./DOCKER_SETUP.md) for complete Docker instructions.

### Option 2: Native Installation

**Prerequisites:**
- [Foundry](https://book.getfoundry.sh/getting-started/installation) (latest version)
- Solidity compiler 0.8.24+

**Setup:**

1. Install Foundry (see [INSTALL_FOUNDRY.md](./INSTALL_FOUNDRY.md) for detailed instructions)
2. Install dependencies:
   ```bash
   forge install OpenZeppelin/openzeppelin-contracts
   forge install foundry-rs/forge-std
   ```
3. Build the contracts:
   ```bash
   forge build
   ```
4. Run tests:
   ```bash
   forge test
   ```

## Deployment

### Step 1: Deploy ABACRegistry

```solidity
ABACRegistry registry = new ABACRegistry();
registry.transferOwnership(yourAdminAddress);
```

### Step 2: Deploy ABACPolicy

```solidity
ABACPolicy policy = new ABACPolicy(address(registry));
policy.transferOwnership(yourAdminAddress);
```

### Step 3: Deploy ABACAccessManager

```solidity
ABACAccessManager accessManager = new ABACAccessManager(
    address(registry),
    address(policy)
);
accessManager.transferOwnership(yourAdminAddress);
```

### Step 4: (Optional) Deploy and Configure Environment Oracle

```solidity
MockEnvOracle oracle = new MockEnvOracle();
accessManager.setEnvOracle(address(oracle));
```

## Usage

### Encoding Attributes

All attribute keys and string values are stored as `bytes32`. To encode string attributes:

```solidity
bytes32 role = keccak256("employee");
bytes32 department = keccak256("security");
bytes32 location = keccak256("locationA");
```

Predefined attribute keys (as `bytes32` constants):
- **Subject keys**: `SUB_ROLE`, `SUB_ORG`, `SUB_DEPT`, `SUB_OFFICE`, `SUB_DEV_TYPE`, `SUB_LOCATION`
- **Object keys**: `OBJ_RESOURCE_TYPE`, `OBJ_OWNER_DEPT`, `OBJ_SENSITIVITY`, `OBJ_LOCATION`

### Registering Subject Attributes

Subjects (users/devices) can set their own attributes, or an admin can set them:

```solidity
// Single attribute
registry.setSubjectAttribute(
    subjectAddress,
    registry.SUB_ROLE(),
    keccak256("employee")
);

// Multiple attributes
bytes32[] memory keys = [
    registry.SUB_ROLE(),
    registry.SUB_DEPT(),
    registry.SUB_LOCATION()
];
bytes32[] memory values = [
    keccak256("employee"),
    keccak256("security"),
    keccak256("locationA")
];
registry.setSubjectAttributes(subjectAddress, keys, values);
```

### Registering Object Attributes

Only the contract owner can set object attributes:

```solidity
bytes32[] memory keys = [
    registry.OBJ_RESOURCE_TYPE(),
    registry.OBJ_LOCATION()
];
bytes32[] memory values = [
    keccak256("doorLock"),
    keccak256("locationA")
];
registry.setObjectAttributes(resourceAddress, keys, values);
```

### Creating Policies

Only the policy contract owner can create policies. Policies use conditions that must all evaluate to true (AND logic). Multiple policies for the same resource/action are evaluated with OR logic (permit if any policy matches).

#### Example Policy A: Employee + Door Lock + Location Match + Working Hours

```solidity
ABACPolicy.Condition[] memory conditions = new ABACPolicy.Condition[](4);

// subject.role == "employee"
conditions[0] = ABACPolicy.Condition({
    leftSource: ABACPolicy.AttrSource.SUBJECT,
    leftKey: registry.SUB_ROLE(),
    op: ABACPolicy.Operator.EQ,
    rightSource: ABACPolicy.AttrSource.SUBJECT,
    rightKey: bytes32(0),
    value: keccak256("employee"),
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
    value: keccak256("doorLock"),
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

// env.timeWindow == WORKING_HOURS (0)
conditions[3] = ABACPolicy.Condition({
    leftSource: ABACPolicy.AttrSource.ENV,
    leftKey: keccak256("timeWindow"),
    op: ABACPolicy.Operator.EQ,
    rightSource: ABACPolicy.AttrSource.ENV,
    rightKey: bytes32(0),
    value: bytes32(uint256(0)), // 0 = WORKING_HOURS
    numValue: 0,
    setValues: new bytes32[](0)
});

uint256 policyId = policy.createPolicy(
    resourceAddress,
    ABACPolicy.Action.EXECUTE,
    conditions
);
```

#### Example Policy B: Security Dept + Computer + Monitor + Emergency Mode

```solidity
ABACPolicy.Condition[] memory conditions = new ABACPolicy.Condition[](4);

// subject.dept == "security"
conditions[0] = ABACPolicy.Condition({
    leftSource: ABACPolicy.AttrSource.SUBJECT,
    leftKey: registry.SUB_DEPT(),
    op: ABACPolicy.Operator.EQ,
    rightSource: ABACPolicy.AttrSource.SUBJECT,
    rightKey: bytes32(0),
    value: keccak256("security"),
    numValue: 0,
    setValues: new bytes32[](0)
});

// subject.deviceType == "computer"
conditions[1] = ABACPolicy.Condition({
    leftSource: ABACPolicy.AttrSource.SUBJECT,
    leftKey: registry.SUB_DEV_TYPE(),
    op: ABACPolicy.Operator.EQ,
    rightSource: ABACPolicy.AttrSource.SUBJECT,
    rightKey: bytes32(0),
    value: keccak256("computer"),
    numValue: 0,
    setValues: new bytes32[](0)
});

// object.resourceType == "monitor"
conditions[2] = ABACPolicy.Condition({
    leftSource: ABACPolicy.AttrSource.OBJECT,
    leftKey: registry.OBJ_RESOURCE_TYPE(),
    op: ABACPolicy.Operator.EQ,
    rightSource: ABACPolicy.AttrSource.OBJECT,
    rightKey: bytes32(0),
    value: keccak256("monitor"),
    numValue: 0,
    setValues: new bytes32[](0)
});

// env.emergencyMode == true
conditions[3] = ABACPolicy.Condition({
    leftSource: ABACPolicy.AttrSource.ENV,
    leftKey: keccak256("emergencyMode"),
    op: ABACPolicy.Operator.EQ,
    rightSource: ABACPolicy.AttrSource.ENV,
    rightKey: bytes32(0),
    value: bytes32(uint256(1)), // 1 = true
    numValue: 0,
    setValues: new bytes32[](0)
});

policy.createPolicy(resourceAddress, ABACPolicy.Action.READ, conditions);
```

#### Numeric Comparisons

For numeric comparisons (LE, LT, GE, GT), use `numValue`:

```solidity
// env.systemLoad <= 80
conditions[0] = ABACPolicy.Condition({
    leftSource: ABACPolicy.AttrSource.ENV,
    leftKey: keccak256("systemLoad"),
    op: ABACPolicy.Operator.LE,
    rightSource: ABACPolicy.AttrSource.ENV,
    rightKey: bytes32(0),
    value: bytes32(0),
    numValue: 80,
    setValues: new bytes32[](0)
});
```

#### Set Membership (IN_SET)

For set membership checks, use `setValues`:

```solidity
bytes32[] memory timeWindows = new bytes32[](2);
timeWindows[0] = bytes32(uint256(0)); // WORKING_HOURS
timeWindows[1] = bytes32(uint256(1)); // OFF_HOURS

conditions[0] = ABACPolicy.Condition({
    leftSource: ABACPolicy.AttrSource.ENV,
    leftKey: keccak256("timeWindow"),
    op: ABACPolicy.Operator.IN_SET,
    rightSource: ABACPolicy.AttrSource.ENV,
    rightKey: bytes32(0),
    value: bytes32(0),
    numValue: 0,
    setValues: timeWindows
});
```

### Requesting Access

#### Without Oracle (Trusted Environment)

```solidity
IEnvOracle.Env memory env = IEnvOracle.Env({
    timeWindow: 0,      // 0 = WORKING_HOURS, 1 = OFF_HOURS
    emergencyMode: false,
    systemLoad: 50      // 0-100 percent
});

bool permit = accessManager.requestAccess(
    subjectAddress,
    resourceAddress,
    ABACPolicy.Action.EXECUTE,
    env,
    "" // empty proof if oracle not enabled
);
```

#### With Oracle Verification

If an oracle is configured, provide a proof:

```solidity
bytes memory proof = "your_proof_data";
bool permit = accessManager.requestAccess(
    subjectAddress,
    resourceAddress,
    ABACPolicy.Action.READ,
    env,
    proof
);
```

### Managing Policies

Enable/disable a policy:
```solidity
policy.setPolicyEnabled(policyId, false); // disable
policy.setPolicyEnabled(policyId, true);  // enable
```

Delete a policy (removes from index, marks as disabled):
```solidity
policy.deletePolicy(policyId);
```

## Environment Attributes

Environment attributes are provided at request time:

- **timeWindow**: `uint8` - 0 = WORKING_HOURS, 1 = OFF_HOURS
- **emergencyMode**: `bool` - Emergency mode flag
- **systemLoad**: `uint256` - System load percentage (0-100)

### Environment Oracle

An optional oracle can verify environment attributes. The `IEnvOracle` interface provides a `verify()` function that takes environment attributes and a proof, returning true if verified.

In the prototype, environment attributes are trusted if no oracle is configured. For production, implement a proper oracle that verifies time windows, emergency states, and system load from external sources.

## Operators

- **EQ**: Equality (for bytes32 values)
- **NEQ**: Not equal (for bytes32 values)
- **LE**: Less than or equal (for numeric values)
- **LT**: Less than (for numeric values)
- **GE**: Greater than or equal (for numeric values)
- **GT**: Greater than (for numeric values)
- **IN_SET**: Set membership (for bytes32 values, max 8 members)
- **EQ_FIELD**: Compare two attributes (e.g., subject.location == object.location)

## Limitations

- Maximum 16 conditions per policy rule
- Maximum 8 members in IN_SET operations
- Policies use AND logic within a rule (all conditions must match)
- Multiple policies for the same resource/action use OR logic (any matching policy grants access)
- Deny by default if no policies match

## Testing

Run all tests:
```bash
forge test
```

Run with verbose output:
```bash
forge test -vvv
```

Run specific test:
```bash
forge test --match-test test_PolicyA_EmployeeDoorLockLocationMatch
```

For detailed deployment and testing instructions, see [DEPLOYMENT.md](./DEPLOYMENT.md).

### Test Coverage

The test suite includes:

1. Subject and object attribute registration
2. Policy A: Employee + door lock + location match + working hours
3. Policy B: Security dept + computer + monitor + emergency mode
4. Policy C: Deny by default behavior
5. Negative tests:
   - Wrong location
   - Off-hours access
   - System load too high
   - Policy disabled
6. Oracle verification tests
7. Multiple sequential requests
8. IN_SET operator tests

## Gas Considerations

- Attribute keys and values use `bytes32` for predictable gas costs
- Dynamic arrays in policies are capped (16 conditions, 8 set members)
- Policies are indexed by resource and action for efficient lookup
- Evaluation is deterministic and bounded (no unbounded loops)

## Security Considerations

- Access control: Only owners can create/modify policies and set object attributes
- Subjects can set their own attributes (with admin override)
- Environment attributes are caller-provided unless oracle is configured
- All access decisions are logged via events for audit trails
- Policy evaluation is deterministic and cannot be manipulated by external state

## License

MIT
