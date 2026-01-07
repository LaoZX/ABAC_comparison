# Step-by-Step Foundry Installation for Windows

## What is Foundry?

Foundry is a toolkit for Ethereum application development. We need it to:
- Compile Solidity smart contracts
- Run tests
- Deploy contracts

## Installation Steps

### Step 1: Open PowerShell as Administrator

**Method 1 - Windows Key Menu:**
1. Press `Windows Key + X`
2. Click "Windows PowerShell (Admin)" or "Terminal (Admin)"
3. If prompted by User Account Control, click "Yes"

**Method 2 - Start Menu:**
1. Click the Start button
2. Type "PowerShell"
3. Right-click on "Windows PowerShell"
4. Select "Run as administrator"

**Method 3 - Run Dialog:**
1. Press `Windows Key + R`
2. Type: `powershell`
3. Press `Ctrl + Shift + Enter` (this runs as admin)

### Step 2: Check PowerShell Execution Policy

First, let's make sure PowerShell can run scripts. In the admin PowerShell window, type:

```powershell
Get-ExecutionPolicy
```

**If it shows "Restricted":**
Run this command to allow scripts:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
Type `Y` when prompted and press Enter.

**If it shows "RemoteSigned" or "Unrestricted":**
You're good to go! Skip to Step 3.

### Step 3: Install Foundry

Copy and paste this command into the admin PowerShell window:

```powershell
irm https://foundry.paradigm.xyz | iex
```

**What this does:**
- `irm` = Invoke-RestMethod (downloads a script)
- The script installs Foundry
- This may take 1-2 minutes

**Expected output:**
You should see messages like:
```
Installing foundryup...
Installing forge...
Installing cast...
Installing anvil...
```

Wait for it to complete. You'll see a message when it's done.

### Step 4: Update Foundry

After installation, run:

```powershell
foundryup
```

This ensures you have the latest version. It should complete quickly.

### Step 5: Close and Reopen PowerShell

**IMPORTANT:** Foundry was added to your PATH, but you need to:
1. **Close the admin PowerShell window completely**
2. **Open a NEW regular PowerShell window** (NOT as admin this time)

**To open regular PowerShell:**
- Press `Windows Key + X` → Click "Windows PowerShell" (without Admin)
- OR Press `Windows Key`, type "PowerShell", press Enter

### Step 6: Verify Installation

In the new PowerShell window, run these commands one by one:

```powershell
forge --version
```

You should see something like: `forge 0.2.0 (abc123 2024-01-01T00:00:00.000000000Z)`

```powershell
cast --version
```

You should see: `cast 0.2.0 (abc123 2024-01-01T00:00:00.000000000Z)`

```powershell
anvil --version
```

You should see: `anvil 0.2.0 (abc123 2024-01-01T00:00:00.000000000Z)`

### Step 7: Navigate to Your Project

In the same PowerShell window, run:

```powershell
cd D:\Porjects\practice
```

Verify you're in the right place:

```powershell
ls
```

You should see folders like `contracts`, `test`, and files like `foundry.toml`, `README.md`.

## ✅ Installation Complete!

If all three commands (`forge --version`, `cast --version`, `anvil --version`) show version numbers, you're ready to go!

## Next Steps

Now you can:

1. **Install dependencies:**
   ```powershell
   forge install OpenZeppelin/openzeppelin-contracts foundry-rs/forge-std --no-commit
   ```

2. **Build contracts:**
   ```powershell
   forge build
   ```

3. **Run tests:**
   ```powershell
   forge test
   ```

## Troubleshooting

### Problem: "forge: command not found" after installation

**Solution:**
1. Close PowerShell completely
2. Open a NEW PowerShell window (not admin)
3. Try `forge --version` again

If it still doesn't work:
1. Check if Foundry is installed: Look for `C:\Users\<YourUsername>\.foundry\bin`
2. Restart your computer (sometimes needed for PATH updates)

### Problem: Execution policy error

**Solution:**
Run this in admin PowerShell:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Problem: Installation script fails

**Solution:**
Try installing manually:
1. Download from: https://github.com/foundry-rs/foundry/releases
2. Extract the zip file
3. Add the `bin` folder to your PATH environment variable

### Problem: "Unable to connect" or network error

**Solution:**
- Check your internet connection
- Try again (the server might be temporarily unavailable)
- Check if your firewall/antivirus is blocking the connection

## Need More Help?

- Foundry Book: https://book.getfoundry.sh/getting-started/installation
- Foundry GitHub: https://github.com/foundry-rs/foundry
