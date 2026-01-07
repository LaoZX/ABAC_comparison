# Quick Start Guide

Get up and running with the ABAC system in minutes.

## Prerequisites Check

First, verify you have Foundry installed:
```bash
forge --version
```

If not installed, install Foundry:
```bash
# Windows (PowerShell - run as Administrator)
irm https://foundry.paradigm.xyz | iex
foundryup

# Linux/Mac
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

## Step 1: Install Dependencies

```bash
forge install OpenZeppelin/openzeppelin-contracts foundry-rs/forge-std --no-commit
```

This installs:
- OpenZeppelin contracts (for Ownable)
- Foundry standard library (for testing)

## Step 2: Build Contracts

```bash
forge build
```

Expected output: `Compiler run successful`

## Step 3: Run Tests

```bash
forge test
```

You should see all 13 tests passing:
```
Test result: ok. 13 passed; 0 failed; finished in X.XXs
```

For detailed test output:
```bash
forge test -vvv
```

## Step 4: Test on Local Network (Optional)

### Start Local Node

Open a new terminal and run:
```bash
anvil
```

This starts a local Ethereum node with test accounts.

### Deploy Contracts

In your main terminal, set up environment:

**Windows (PowerShell):**
```powershell
$env:PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
```

**Linux/Mac:**
```bash
export PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
```

Then deploy:
```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url http://127.0.0.1:8545 --broadcast
```

This will deploy all contracts and print their addresses.

## Quick Test Commands

### Run Specific Test
```bash
forge test --match-test test_PolicyA_EmployeeDoorLockLocationMatch -vvv
```

### Run Tests with Gas Report
```bash
forge test --gas-report
```

### Run Tests and Show Traces
```bash
forge test -vvvv
```

## What Gets Tested

The test suite includes:

1. ✅ Subject attribute registration
2. ✅ Object attribute registration  
3. ✅ Policy A: Employee + door lock + location match + working hours
4. ✅ Policy B: Security dept + computer + monitor + emergency mode
5. ✅ Policy C: Deny by default
6. ✅ Negative tests (wrong location, off-hours, high load, disabled policy)
7. ✅ Oracle verification
8. ✅ Multiple sequential requests
9. ✅ IN_SET operator
10. ✅ System load conditions

## Common Issues

### Issue: "library not found"
**Solution**: Install dependencies
```bash
forge install OpenZeppelin/openzeppelin-contracts foundry-rs/forge-std --no-commit
```

### Issue: Compilation errors
**Solution**: Check Solidity version matches (0.8.24)
```bash
forge build --force
```

### Issue: Tests fail
**Solution**: Run with verbose output to see details
```bash
forge test -vvv
```

## Next Steps

- Read [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed deployment instructions
- Read [README.md](./README.md) for usage examples
- Check test files in `test/` for code examples

## Need Help?

- Check the full [DEPLOYMENT.md](./DEPLOYMENT.md) guide
- Review test cases in `test/ABAC.t.sol` for usage examples
- See [README.md](./README.md) for API documentation
