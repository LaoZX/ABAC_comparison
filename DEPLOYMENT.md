# Deployment and Testing Guide

This guide provides step-by-step instructions for deploying and testing the ABAC smart contract system.

## Prerequisites

1. **Install Foundry** (if not already installed):
   ```bash
   # On Windows (PowerShell)
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   
   # On Linux/Mac
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Verify Installation**:
   ```bash
   forge --version
   cast --version
   anvil --version
   ```

## Setup

### 1. Install Dependencies

```bash
# Install OpenZeppelin contracts
forge install OpenZeppelin/openzeppelin-contracts --no-commit

# Install Foundry standard library
forge install foundry-rs/forge-std --no-commit
```

Alternatively, use the provided script:
- **Windows (PowerShell)**: `.\scripts\install-deps.ps1`
- **Linux/Mac**: `bash scripts/install-deps.sh`

### 2. Build Contracts

```bash
forge build
```

This will compile all contracts and create artifacts in the `out/` directory.

### 3. Run Tests

Run all tests:
```bash
forge test
```

Run tests with verbose output:
```bash
forge test -vvv
```

Run a specific test:
```bash
forge test --match-test test_PolicyA_EmployeeDoorLockLocationMatch -vvv
```

Run tests with gas reporting:
```bash
forge test --gas-report
```

## Testing on Local Network (Anvil)

### 1. Start Local Anvil Node

In a separate terminal:
```bash
anvil
```

This will start a local Ethereum node at `http://127.0.0.1:8545` with 10 test accounts.

### 2. Deploy to Anvil

Create a deployment script. See `script/Deploy.s.sol` for a complete deployment script.

Quick deployment using cast:
```bash
# Set the private key (use one of the anvil accounts)
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Deploy Registry
REGISTRY=$(forge create --rpc-url http://127.0.0.1:8545 --private-key $PRIVATE_KEY contracts/ABACRegistry.sol:ABACRegistry --json | jq -r '.deployedTo')

# Deploy Policy (passing registry address)
POLICY=$(forge create --rpc-url http://127.0.0.1:8545 --private-key $PRIVATE_KEY contracts/ABACPolicy.sol:ABACPolicy --constructor-args $REGISTRY --json | jq -r '.deployedTo')

# Deploy AccessManager (passing registry and policy addresses)
MANAGER=$(forge create --rpc-url http://127.0.0.1:8545 --private-key $PRIVATE_KEY contracts/ABACAccessManager.sol:ABACAccessManager --constructor-args $REGISTRY $POLICY --json | jq -r '.deployedTo')

echo "Registry: $REGISTRY"
echo "Policy: $POLICY"
echo "AccessManager: $MANAGER"
```

## Deployment Script

A more convenient way is to use the deployment script:

```bash
# Make sure anvil is running
forge script script/Deploy.s.sol:DeployScript --rpc-url http://127.0.0.1:8545 --broadcast --private-key $PRIVATE_KEY
```

## Testing Deployed Contracts

After deployment, you can interact with contracts using `cast`:

### Register Subject Attributes

```bash
# Register a subject attribute
cast send $REGISTRY "setSubjectAttribute(address,bytes32,bytes32)" \
  <SUBJECT_ADDRESS> \
  $(cast keccak "SUB_ROLE") \
  $(cast keccak "employee") \
  --private-key $PRIVATE_KEY \
  --rpc-url http://127.0.0.1:8545
```

### Create a Policy

```bash
# This is complex with multiple conditions - better to use a script
# See script/CreatePolicy.s.sol for an example
```

### Request Access

```bash
# Request access (requires proper encoding of Env struct)
# Better to use a script - see script/RequestAccess.s.sol
```

## Deployment to Testnets

### 1. Set Up Environment Variables

Create a `.env` file:
```env
PRIVATE_KEY=your_private_key_here
RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
ETHERSCAN_API_KEY=your_etherscan_api_key
```

Load environment variables:
```bash
# Windows (PowerShell)
$env:PRIVATE_KEY="your_private_key"
$env:RPC_URL="https://sepolia.infura.io/v3/YOUR_KEY"

# Linux/Mac
export PRIVATE_KEY="your_private_key"
export RPC_URL="https://sepolia.infura.io/v3/YOUR_KEY"
```

### 2. Deploy to Sepolia Testnet

```bash
# Deploy Registry
forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
  contracts/ABACRegistry.sol:ABACRegistry

# Deploy Policy (replace REGISTRY_ADDRESS)
forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
  contracts/ABACPolicy.sol:ABACPolicy \
  --constructor-args REGISTRY_ADDRESS

# Deploy AccessManager (replace REGISTRY_ADDRESS and POLICY_ADDRESS)
forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
  contracts/ABACAccessManager.sol:ABACAccessManager \
  --constructor-args REGISTRY_ADDRESS POLICY_ADDRESS
```

### 3. Verify Contracts on Etherscan

```bash
forge verify-contract REGISTRY_ADDRESS \
  contracts/ABACRegistry.sol:ABACRegistry \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --chain sepolia

forge verify-contract POLICY_ADDRESS \
  contracts/ABACPolicy.sol:ABACPolicy \
  --constructor-args $(cast abi-encode "constructor(address)" REGISTRY_ADDRESS) \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --chain sepolia
```

## Testing Checklist

After deployment, test the following:

1. ✅ Register subject attributes
2. ✅ Register object attributes
3. ✅ Create Policy A (employee + doorLock + location + working hours)
4. ✅ Create Policy B (security dept + computer + monitor + emergency mode)
5. ✅ Test access requests:
   - Valid access (should permit)
   - Invalid location (should deny)
   - Off-hours (should deny)
   - High system load (should deny)
   - Disabled policy (should deny)
6. ✅ Test oracle verification (if oracle is deployed)
7. ✅ Verify events are emitted correctly

## Gas Estimates

Check gas costs before deploying:

```bash
forge snapshot
```

This creates a snapshot with gas estimates for all operations.

## Troubleshooting

### Common Issues

1. **"library not found" errors**:
   - Make sure dependencies are installed: `forge install OpenZeppelin/openzeppelin-contracts foundry-rs/forge-std`
   - Check `remappings.txt` exists

2. **Compilation errors**:
   - Ensure Solidity version matches (0.8.24)
   - Check `foundry.toml` configuration

3. **Test failures**:
   - Run with `-vvv` for detailed output
   - Ensure all dependencies are installed
   - Check that test accounts have sufficient balance

4. **Deployment failures**:
   - Verify RPC URL is correct and accessible
   - Ensure private key has sufficient balance for gas
   - Check constructor arguments are correct

## Next Steps

After successful deployment:

1. Transfer ownership of contracts to a multisig or admin address
2. Set up monitoring for access events
3. Implement environment oracle for production use
4. Consider adding additional policies as needed
5. Set up indexing for events (e.g., The Graph)
