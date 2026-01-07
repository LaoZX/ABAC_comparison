# Running ABAC Project in Docker

This guide shows you how to run the ABAC smart contract project in Docker, so you don't need to install Foundry directly on your Windows machine.

## Prerequisites

- **Docker Desktop** installed on Windows
  - Download from: https://www.docker.com/products/docker-desktop/
  - Install and make sure Docker Desktop is running

## Quick Start

### Step 1: Verify Docker is Running

Open PowerShell and check Docker:

```powershell
docker --version
docker-compose --version
```

You should see version numbers for both.

### Step 2: Build the Docker Image

Navigate to your project directory:

```powershell
cd D:\Porjects\practice
```

Build the Docker image (this will take a few minutes the first time):

```powershell
docker-compose build
```

### Step 3: Start the Container

Start an interactive container:

```powershell
docker-compose run --rm abac-dev
```

This will:
- Start a container with Foundry pre-installed
- Mount your project directory
- Drop you into a bash shell inside the container

### Step 4: Run Commands Inside Container

Once inside the container, you can run all Foundry commands:

```bash
# Verify Foundry is installed
forge --version

# Install dependencies (if not already done)
forge install OpenZeppelin/openzeppelin-contracts foundry-rs/forge-std --no-commit

# Build contracts
forge build

# Run tests
forge test

# Run tests with verbose output
forge test -vvv
```

### Step 5: Exit Container

To exit the container and return to PowerShell:

```bash
exit
```

## Common Workflows

### Run Tests

```powershell
# Start container, run tests, then exit
docker-compose run --rm abac-dev forge test
```

### Build Contracts

```powershell
docker-compose run --rm abac-dev forge build
```

### Run Specific Test

```powershell
docker-compose run --rm abac-dev forge test --match-test test_PolicyA_EmployeeDoorLockLocationMatch -vvv
```

### Interactive Shell (for multiple commands)

```powershell
# Start interactive shell
docker-compose run --rm abac-dev

# Now you're inside the container - run any commands:
# forge build
# forge test
# forge test -vvv
# etc.

# When done, type: exit
```

### Run Anvil (Local Blockchain)

In one terminal:
```powershell
docker-compose run --rm -p 8545:8545 abac-dev anvil
```

In another terminal, deploy:
```powershell
docker-compose run --rm abac-dev forge script script/Deploy.s.sol:DeployScript --rpc-url http://host.docker.internal:8545 --broadcast
```

## Alternative: Direct Docker Commands

If you prefer not to use docker-compose:

### Build Image

```powershell
docker build -t abac-foundry .
```

### Run Container

```powershell
docker run -it --rm -v ${PWD}:/app -w /app abac-foundry /bin/bash
```

### Run Single Command

```powershell
docker run -it --rm -v ${PWD}:/app -w /app abac-foundry forge test
```

## Tips

1. **First Build**: The first `docker-compose build` will take several minutes as it downloads Ubuntu, installs dependencies, and builds Foundry. Subsequent builds will be much faster.

2. **Volume Mounts**: Your project directory is mounted, so any changes you make on your Windows machine will be reflected in the container.

3. **Dependencies Cache**: The `lib/` folder is cached in a Docker volume, so dependencies won't need to be reinstalled every time.

4. **Persistent Cache**: Foundry's cache is stored in a Docker volume, so compilation will be faster on subsequent runs.

5. **Clean Start**: To start fresh, remove volumes:
   ```powershell
   docker-compose down -v
   docker-compose build --no-cache
   ```

## Troubleshooting

### Docker Desktop not running

**Error**: `Cannot connect to the Docker daemon`

**Solution**: Start Docker Desktop application

### Permission errors

**Error**: Permission denied errors

**Solution**: Make sure Docker Desktop has access to the D: drive. Go to Docker Desktop → Settings → Resources → File Sharing → Add D:\

### Container exits immediately

**Error**: Container starts and immediately exits

**Solution**: Use `docker-compose run --rm abac-dev` (not `up`) for interactive mode

### Build fails

**Error**: Build errors or timeouts

**Solution**: 
- Check your internet connection
- Try: `docker-compose build --no-cache`
- Make sure Docker Desktop has enough resources allocated (Settings → Resources)

### Changes not reflected

**Error**: Code changes don't appear in container

**Solution**: 
- Make sure you're using `docker-compose run` (not `docker run`)
- Check that the volume mount is working: `docker-compose run --rm abac-dev ls -la`

## Comparison: Docker vs Native Installation

| Feature | Docker | Native Installation |
|---------|--------|---------------------|
| Setup Time | 5-10 min (first time) | 5-15 min |
| Disk Space | ~2GB (Docker + image) | ~500MB |
| Isolation | Complete | None |
| Windows Compatibility | Works everywhere | May have issues |
| Performance | Slightly slower | Faster |
| Easy Cleanup | `docker-compose down -v` | Manual uninstall |

## Next Steps

After running tests successfully in Docker, you can:

1. Continue development in Docker (recommended if you want isolation)
2. Or install Foundry natively on Windows for better performance (see INSTALL_FOUNDRY.md)

Both approaches work great! Docker is easier to set up, while native installation is faster for development.
