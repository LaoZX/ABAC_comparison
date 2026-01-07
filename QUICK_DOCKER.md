# Quick Docker Guide 🐳

Since you have Docker installed, you can run everything without installing Foundry!

## Quick Start (3 Commands)

Open PowerShell in your project directory (`D:\Porjects\practice`) and run:

### 1. Build the Docker Image
```powershell
docker-compose build
```
*(Takes 5-10 minutes the first time - downloads Ubuntu and installs Foundry)*

### 2. Run Tests
```powershell
docker-compose run --rm abac-dev forge test
```

### 3. Build Contracts (optional)
```powershell
docker-compose run --rm abac-dev forge build
```

That's it! All tests should pass.

## Common Commands

```powershell
# Run tests with verbose output
docker-compose run --rm abac-dev forge test -vvv

# Run specific test
docker-compose run --rm abac-dev forge test --match-test test_PolicyA_EmployeeDoorLockLocationMatch -vvv

# Get interactive shell (for multiple commands)
docker-compose run --rm abac-dev
# Then run: forge build, forge test, etc.
# Type 'exit' when done

# Build contracts
docker-compose run --rm abac-dev forge build
```

## What's Happening?

- Docker creates a container with Foundry pre-installed
- Your project files are mounted, so changes are reflected instantly
- No need to install anything on Windows!

## Need More Details?

See **[DOCKER_SETUP.md](./DOCKER_SETUP.md)** for comprehensive Docker instructions.
