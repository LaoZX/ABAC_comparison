# Setup Guide for Windows

## Step 1: Install Foundry

Open PowerShell as Administrator and run:

```powershell
irm https://foundry.paradigm.xyz | iex
```

After installation completes, run:
```powershell
foundryup
```

**Close and reopen PowerShell** for the PATH to update.

Verify installation:
```powershell
forge --version
cast --version
anvil --version
```

You should see version numbers for all three tools.

## Step 2: Navigate to Project Directory

Open PowerShell (regular, not as admin) and navigate to your project:

```powershell
cd D:\Porjects\practice
```

## Step 3: Install Dependencies

```powershell
forge install OpenZeppelin/openzeppelin-contracts foundry-rs/forge-std --no-commit
```

This will create a `lib/` folder with the dependencies.

## Step 4: Build Contracts

```powershell
forge build
```

You should see: `Compiler run successful`

## Step 5: Run Tests

```powershell
forge test
```

You should see all tests passing!

## Troubleshooting

### If `forge` command not found:
1. Close and reopen PowerShell
2. Check if `C:\Users\<your-username>\.foundry\bin` is in your PATH
3. Restart your computer if needed

### If installation fails:
- Make sure PowerShell execution policy allows scripts:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

### Alternative Installation:
If the script doesn't work, you can manually install:
1. Download from: https://github.com/foundry-rs/foundry/releases
2. Extract and add to PATH

## Quick Command Reference

```powershell
# Check version
forge --version

# Install dependencies
forge install OpenZeppelin/openzeppelin-contracts foundry-rs/forge-std --no-commit

# Build
forge build

# Test
forge test

# Test with verbose output
forge test -vvv

# Run specific test
forge test --match-test test_PolicyA_EmployeeDoorLockLocationMatch
```
