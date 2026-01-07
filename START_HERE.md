# START HERE - Windows Quick Setup

## 🐳 Option 1: Use Docker (Recommended - No Installation Needed!)

If you have Docker Desktop installed, you can skip Foundry installation entirely:

1. **Build Docker image:**
   ```powershell
   docker-compose build
   ```

2. **Run tests:**
   ```powershell
   docker-compose run --rm abac-dev forge test
   ```

See **[DOCKER_SETUP.md](./DOCKER_SETUP.md)** for complete Docker instructions.

---

## ⚠️ Option 2: Install Foundry Natively

If you prefer native installation (faster, but requires setup):

Foundry is not installed on your system. Follow these steps:

## Step 1: Install Foundry

1. **Open PowerShell as Administrator**:
   - Press `Windows Key + X`
   - Select "Windows PowerShell (Admin)" or "Terminal (Admin)"

2. **Run the installation command**:
   ```powershell
   irm https://foundry.paradigm.xyz | iex
   ```

3. **After it finishes, run**:
   ```powershell
   foundryup
   ```

4. **Close PowerShell completely** and open a new one (important!)

5. **Verify installation** (in new PowerShell):
   ```powershell
   forge --version
   ```
   
   You should see something like: `forge 0.x.x`

## Step 2: Open Terminal in Your Project

1. Open PowerShell (regular, not admin)
2. Navigate to your project:
   ```powershell
   cd D:\Porjects\practice
   ```

## Step 3: Install Dependencies

```powershell
forge install OpenZeppelin/openzeppelin-contracts foundry-rs/forge-std --no-commit
```

Wait for it to complete (may take a minute).

## Step 4: Build the Contracts

```powershell
forge build
```

Expected output: `Compiler run successful`

## Step 5: Run Tests

```powershell
forge test
```

You should see:
```
Test result: ok. 13 passed; 0 failed
```

## ✅ You're Done!

All tests should pass. Now you can:
- Read `README.md` for usage examples
- Read `DEPLOYMENT.md` for deployment instructions
- Check `test/ABAC.t.sol` for code examples

## Need Help?

If you encounter errors:
1. Make sure Foundry is installed: `forge --version`
2. Make sure you're in the project directory: `cd D:\Porjects\practice`
3. Check that dependencies are installed: `ls lib` (should show folders)
4. Run with verbose output: `forge test -vvv` to see detailed errors
