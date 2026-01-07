#!/bin/bash
# Install dependencies for Foundry project

forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install foundry-rs/forge-std --no-commit

echo "Dependencies installed successfully!"
