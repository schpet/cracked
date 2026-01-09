# syntax=docker/dockerfile:1

# Base image for cracked development environment
# Supports: linux/amd64, linux/arm64
# Registry: ghcr.io/schpet/cracked:base

FROM debian:bookworm-slim

LABEL org.opencontainers.image.source="https://github.com/schpet/cracked"
LABEL org.opencontainers.image.description="Base development environment with modern CLI tools"

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set up locale
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Create tools directory
WORKDIR /root/tools

# Install minimal base packages needed for subsequent tool installation
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Default to bash for now (fish will be configured in later issues)
CMD ["/bin/bash"]
