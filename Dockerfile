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

# Install core system tools
# - fish: modern shell (set as default)
# - git: version control
# - ripgrep: fast grep alternative (rg)
# - fd-find: fast find alternative (creates fdfind, symlinked to fd)
# - fzf: fuzzy finder
# - stow: symlink farm manager (for dotfiles)
# - jq: JSON processor
# - jo: JSON output generator
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    fish \
    git \
    ripgrep \
    fd-find \
    fzf \
    stow \
    jq \
    jo \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd

# Install eza (modern ls replacement) from GitHub releases
# Not available in Debian bookworm repos
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then EZA_ARCH="x86_64-unknown-linux-gnu"; fi && \
    if [ "$ARCH" = "aarch64" ]; then EZA_ARCH="aarch64-unknown-linux-gnu"; fi && \
    curl -fsSL "https://github.com/eza-community/eza/releases/download/v0.20.24/eza_${EZA_ARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin --strip-components=0

# Set fish as default shell
ENV SHELL=/usr/bin/fish
CMD ["/usr/bin/fish"]
