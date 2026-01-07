# Use Ubuntu as base image
FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    libssl-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install Foundry
RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="/root/.foundry/bin:${PATH}"
RUN foundryup

# Set working directory
WORKDIR /app

# Default command
CMD ["/bin/bash"]
