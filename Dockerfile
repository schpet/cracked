# syntax=docker/dockerfile:1

# Base image for cracked development environment
# Supports: linux/amd64, linux/arm64
# Registry: ghcr.io/schpet/cracked:base
#
# The setup script can also be run directly:
#   curl -fsSL https://raw.githubusercontent.com/schpet/cracked/main/setup.sh | bash

FROM debian:bookworm-slim

LABEL org.opencontainers.image.source="https://github.com/schpet/cracked"
LABEL org.opencontainers.image.description="Base development environment with modern CLI tools"

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set up locale
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install minimal dependencies needed to run setup script
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create dev user with passwordless sudo and fish shell
RUN useradd -m -s /bin/bash dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy setup script
COPY setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

# Run setup script as root for system-level installations
RUN /usr/local/bin/setup.sh --base

# Change dev user's shell to fish (now that it's installed)
RUN chsh -s /usr/bin/fish dev

# Switch to dev user for user-specific setup
USER dev
WORKDIR /home/dev

# Create tools directory
RUN mkdir -p /home/dev/tools

# Clone and install dotfiles using stow
# Dotfiles provide configuration for jj, fish, git, starship, and other tools
RUN git clone --depth 1 https://github.com/schpet/dotfiles.git /home/dev/dotfiles && \
    cd /home/dev/dotfiles && \
    echo "=== Installing dotfiles ===" && \
    stow . -t /home/dev -v 2 --adopt 2>&1 && \
    echo "=== Symlinks created ===" && \
    ls -la /home/dev/.config/ && \
    echo "=== Dotfiles installation complete ==="

# Clone and install deno tools from GitHub
# gogreen: run claude code in a loop to fix github CI status checks
# easy-bead-oven: orchestrator that processes beads issues
RUN echo "=== Installing deno tools ===" && \
    git clone --depth 1 https://github.com/schpet/gogreen.git /home/dev/tools/gogreen && \
    cd /home/dev/tools/gogreen && \
    just install && \
    git clone --depth 1 https://github.com/schpet/easy-bead-oven.git /home/dev/tools/easy-bead-oven && \
    cd /home/dev/tools/easy-bead-oven && \
    deno install -c ./deno.json -A -g -f -n ebo ./main.ts && \
    echo "=== Deno tools installation complete ==="

# Install Claude Code plugins from schpet/toolbox
RUN claude plugin marketplace add schpet/toolbox && \
    claude plugin install jj-vcs@toolbox && \
    claude plugin install changelog@toolbox && \
    claude plugin install svbump@toolbox && \
    claude plugin install chores@toolbox && \
    claude plugin install speccer@toolbox

# Add deno bin to PATH
ENV PATH="/home/dev/.deno/bin:${PATH}"

# Set fish as default shell
ENV SHELL=/usr/bin/fish
CMD ["/usr/bin/fish"]
