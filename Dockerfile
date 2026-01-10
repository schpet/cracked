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
# - unzip: archive extraction (needed for deno install)
# - xz-utils: xz compression (needed for tar.xz archives)
# - nodejs/npm: required for claude code
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
    unzip \
    xz-utils \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && chsh -s /usr/bin/fish

# Install eza (modern ls replacement) from GitHub releases
# Not available in Debian bookworm repos
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then EZA_ARCH="x86_64-unknown-linux-gnu"; fi && \
    if [ "$ARCH" = "aarch64" ]; then EZA_ARCH="aarch64-unknown-linux-gnu"; fi && \
    curl -fsSL "https://github.com/eza-community/eza/releases/download/v0.20.24/eza_${EZA_ARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin --strip-components=0

# Install jj (jujutsu) version control from GitHub releases
# Modern Git-compatible VCS with first-class support for conflicts and anonymous branches
RUN JJ_VERSION="0.37.0" && \
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then JJ_ARCH="x86_64-unknown-linux-musl"; fi && \
    if [ "$ARCH" = "aarch64" ]; then JJ_ARCH="aarch64-unknown-linux-musl"; fi && \
    curl -fsSL "https://github.com/jj-vcs/jj/releases/download/v${JJ_VERSION}/jj-v${JJ_VERSION}-${JJ_ARCH}.tar.gz" \
    | tar -xzf - -C /usr/local/bin --strip-components=1 ./jj

# Install deno runtime from official installer
# JavaScript/TypeScript runtime with built-in tooling
RUN DENO_VERSION="v2.1.5" && \
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then DENO_ARCH="x86_64-unknown-linux-gnu"; fi && \
    if [ "$ARCH" = "aarch64" ]; then DENO_ARCH="aarch64-unknown-linux-gnu"; fi && \
    curl -fsSL "https://github.com/denoland/deno/releases/download/${DENO_VERSION}/deno-${DENO_ARCH}.zip" -o /tmp/deno.zip && \
    unzip -q /tmp/deno.zip -d /usr/local/bin && \
    rm /tmp/deno.zip && \
    chmod +x /usr/local/bin/deno

# Install just command runner from GitHub releases
# Handy way to save and run project-specific commands
RUN JUST_VERSION="1.40.0" && \
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then JUST_ARCH="x86_64-unknown-linux-musl"; fi && \
    if [ "$ARCH" = "aarch64" ]; then JUST_ARCH="aarch64-unknown-linux-musl"; fi && \
    curl -fsSL "https://github.com/casey/just/releases/download/${JUST_VERSION}/just-${JUST_VERSION}-${JUST_ARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin just

# Install GitHub CLI (gh) from GitHub releases
# GitHub's official command line tool
RUN GH_VERSION="2.67.0" && \
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then GH_ARCH="linux_amd64"; fi && \
    if [ "$ARCH" = "aarch64" ]; then GH_ARCH="linux_arm64"; fi && \
    curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_${GH_ARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin --strip-components=2 gh_${GH_VERSION}_${GH_ARCH}/bin/gh

# Install git-delta (syntax-highlighting pager for git/diff output)
RUN DELTA_VERSION="0.18.2" && \
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then DELTA_ARCH="x86_64-unknown-linux-musl"; fi && \
    if [ "$ARCH" = "aarch64" ]; then DELTA_ARCH="aarch64-unknown-linux-gnu"; fi && \
    curl -fsSL "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-${DELTA_ARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin --strip-components=1 delta-${DELTA_VERSION}-${DELTA_ARCH}/delta

# Install sd (intuitive find & replace CLI, sed alternative)
RUN SD_VERSION="1.0.0" && \
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then SD_ARCH="x86_64-unknown-linux-musl"; fi && \
    if [ "$ARCH" = "aarch64" ]; then SD_ARCH="aarch64-unknown-linux-musl"; fi && \
    curl -fsSL "https://github.com/chmln/sd/releases/download/v${SD_VERSION}/sd-v${SD_VERSION}-${SD_ARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin --strip-components=1 sd-v${SD_VERSION}-${SD_ARCH}/sd

# Install starship prompt (cross-shell prompt with rich customization)
RUN STARSHIP_VERSION="1.24.2" && \
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then STARSHIP_ARCH="x86_64-unknown-linux-musl"; fi && \
    if [ "$ARCH" = "aarch64" ]; then STARSHIP_ARCH="aarch64-unknown-linux-musl"; fi && \
    curl -fsSL "https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-${STARSHIP_ARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin starship

# Install changelog (changelog management tool) from GitHub releases
RUN CHANGELOG_VERSION="1.0.0" && \
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then CHANGELOG_ARCH="x86_64-unknown-linux-gnu"; fi && \
    if [ "$ARCH" = "aarch64" ]; then CHANGELOG_ARCH="aarch64-unknown-linux-gnu"; fi && \
    curl -fsSL "https://github.com/schpet/changelog/releases/download/v${CHANGELOG_VERSION}/changelog-${CHANGELOG_ARCH}.tar.xz" \
    | tar -xJ -C /usr/local/bin --strip-components=1 changelog-${CHANGELOG_ARCH}/changelog

# Install svbump (semantic version bump tool) from GitHub releases
RUN SVBUMP_VERSION="1.0.0" && \
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then SVBUMP_ARCH="x86_64-unknown-linux-gnu"; fi && \
    if [ "$ARCH" = "aarch64" ]; then SVBUMP_ARCH="aarch64-unknown-linux-gnu"; fi && \
    curl -fsSL "https://github.com/schpet/svbump/releases/download/v${SVBUMP_VERSION}/svbump-${SVBUMP_ARCH}.tar.xz" \
    | tar -xJ -C /usr/local/bin --strip-components=1 svbump-${SVBUMP_ARCH}/svbump

# Install Claude Code CLI
# Reference: https://github.com/anthropics/claude-code/blob/main/.devcontainer/Dockerfile
ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# Clone and install dotfiles using install.sh
# Dotfiles provide configuration for jj, fish, git, starship, and other tools
RUN git clone --depth 1 https://github.com/schpet/dotfiles.git /root/dotfiles && \
    cd /root/dotfiles && \
    echo "=== Installing dotfiles ===" && \
    # Backup and stow (core of install.sh, skipping apt since we have all tools)
    mv /root/.gitconfig /root/.gitconfig.orig 2>/dev/null || true && \
    mv /root/.zshrc /root/.zshrc.orig 2>/dev/null || true && \
    stow . -t /root -v 2 --adopt 2>&1 && \
    echo "=== Symlinks created ===" && \
    ls -la /root/.config/ && \
    echo "=== Dotfiles installation complete ==="

# Clone and install deno tools from GitHub
# gogreen: run claude code in a loop to fix github CI status checks
# easy-bead-oven: orchestrator that processes beads issues
RUN echo "=== Installing deno tools ===" && \
    # Clone gogreen
    git clone --depth 1 https://github.com/schpet/gogreen.git /root/tools/gogreen && \
    cd /root/tools/gogreen && \
    just install && \
    # Clone easy-bead-oven
    git clone --depth 1 https://github.com/schpet/easy-bead-oven.git /root/tools/easy-bead-oven && \
    cd /root/tools/easy-bead-oven && \
    deno install -c ./deno.json -A -g -f -n ebo ./main.ts && \
    echo "=== Deno tools installation complete ==="

# Add deno bin to PATH
ENV PATH="/root/.deno/bin:${PATH}"

# Set fish as default shell
ENV SHELL=/usr/bin/fish
CMD ["/usr/bin/fish"]
