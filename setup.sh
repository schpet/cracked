#!/usr/bin/env bash
#
# Cracked Development Environment Setup
# https://github.com/schpet/cracked
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/schpet/cracked/main/setup.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/schpet/cracked/main/setup.sh | bash -s -- --deno
#   curl -fsSL https://raw.githubusercontent.com/schpet/cracked/main/setup.sh | bash -s -- --rust
#   curl -fsSL https://raw.githubusercontent.com/schpet/cracked/main/setup.sh | bash -s -- --rails
#   curl -fsSL https://raw.githubusercontent.com/schpet/cracked/main/setup.sh | bash -s -- --all
#
# Options:
#   --base   Install base tools only (default)
#   --deno   Install base + Deno environment
#   --rust   Install base + Rust toolchain
#   --rails  Install base + Ruby on Rails
#   --all    Install everything
#   --update Update already installed tools to latest versions

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect architecture
ARCH=$(uname -m)
OS=$(uname -s)

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Check if running as root (we need sudo for system installs)
check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        SUDO=""
    elif command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        log_error "This script requires sudo or root access"
        exit 1
    fi
}

# Detect if a command exists
has_cmd() { command -v "$1" &> /dev/null; }

# Get latest GitHub release tag for a repo
get_latest_release() {
    local repo="$1"
    curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/'
}

# Install system packages via apt
install_apt_packages() {
    log_info "Installing system packages..."
    export DEBIAN_FRONTEND=noninteractive
    $SUDO apt-get update
    $SUDO apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install -y --no-install-recommends \
        sudo \
        ca-certificates \
        curl \
        fish \
        git \
        openssh-client \
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
        tmux \
        chromium \
        chromium-driver

    # Create fd symlink if it doesn't exist
    if [[ -f /usr/bin/fdfind ]] && [[ ! -f /usr/local/bin/fd ]]; then
        $SUDO ln -sf /usr/bin/fdfind /usr/local/bin/fd
    fi
    log_success "System packages installed"
}

# Install eza (ls replacement)
install_eza() {
    local current_version=""
    if has_cmd eza; then
        current_version=$(eza --version | head -1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    fi

    local latest_tag
    latest_tag=$(get_latest_release "eza-community/eza")
    local version="${latest_tag#v}"

    if [[ "$current_version" == "$latest_tag" ]] && [[ -z "${FORCE_UPDATE:-}" ]]; then
        log_success "eza $current_version already installed (latest)"
        return
    fi

    log_info "Installing eza $version..."
    local eza_arch
    case "$ARCH" in
        x86_64)  eza_arch="x86_64-unknown-linux-gnu" ;;
        aarch64) eza_arch="aarch64-unknown-linux-gnu" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac

    curl -fsSL "https://github.com/eza-community/eza/releases/download/${latest_tag}/eza_${eza_arch}.tar.gz" \
        | $SUDO tar -xz -C /usr/local/bin --strip-components=0
    log_success "eza $version installed"
}

# Install jj (jujutsu VCS)
install_jj() {
    local current_version=""
    if has_cmd jj; then
        current_version=$(jj --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
    fi

    local latest_tag
    latest_tag=$(get_latest_release "jj-vcs/jj")
    local version="${latest_tag#v}"

    if [[ "$current_version" == "$version" ]] && [[ -z "${FORCE_UPDATE:-}" ]]; then
        log_success "jj $current_version already installed (latest)"
        return
    fi

    log_info "Installing jj $version..."
    local jj_arch
    case "$ARCH" in
        x86_64)  jj_arch="x86_64-unknown-linux-musl" ;;
        aarch64) jj_arch="aarch64-unknown-linux-musl" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac

    curl -fsSL "https://github.com/jj-vcs/jj/releases/download/${latest_tag}/jj-${latest_tag}-${jj_arch}.tar.gz" \
        | $SUDO tar -xzf - -C /usr/local/bin --strip-components=1 ./jj
    log_success "jj $version installed"
}

# Install deno runtime
install_deno() {
    local current_version=""
    if has_cmd deno; then
        current_version=$(deno --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    fi

    local latest_tag
    latest_tag=$(get_latest_release "denoland/deno")
    local version="${latest_tag#v}"

    if [[ "$current_version" == "$version" ]] && [[ -z "${FORCE_UPDATE:-}" ]]; then
        log_success "deno $current_version already installed (latest)"
        return
    fi

    log_info "Installing deno $version..."
    local deno_arch
    case "$ARCH" in
        x86_64)  deno_arch="x86_64-unknown-linux-gnu" ;;
        aarch64) deno_arch="aarch64-unknown-linux-gnu" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac

    local tmpfile
    tmpfile=$(mktemp)
    curl -fsSL "https://github.com/denoland/deno/releases/download/${latest_tag}/deno-${deno_arch}.zip" -o "$tmpfile"
    $SUDO unzip -q -o "$tmpfile" -d /usr/local/bin
    rm "$tmpfile"
    $SUDO chmod +x /usr/local/bin/deno
    log_success "deno $version installed"
}

# Install just command runner
install_just() {
    local current_version=""
    if has_cmd just; then
        current_version=$(just --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    fi

    local latest_tag
    latest_tag=$(get_latest_release "casey/just")
    local version="${latest_tag}"

    if [[ "$current_version" == "$version" ]] && [[ -z "${FORCE_UPDATE:-}" ]]; then
        log_success "just $current_version already installed (latest)"
        return
    fi

    log_info "Installing just $version..."
    local just_arch
    case "$ARCH" in
        x86_64)  just_arch="x86_64-unknown-linux-musl" ;;
        aarch64) just_arch="aarch64-unknown-linux-musl" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac

    curl -fsSL "https://github.com/casey/just/releases/download/${latest_tag}/just-${version}-${just_arch}.tar.gz" \
        | $SUDO tar -xz -C /usr/local/bin just
    log_success "just $version installed"
}

# Install GitHub CLI
install_gh() {
    local current_version=""
    if has_cmd gh; then
        current_version=$(gh --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    fi

    local latest_tag
    latest_tag=$(get_latest_release "cli/cli")
    local version="${latest_tag#v}"

    if [[ "$current_version" == "$version" ]] && [[ -z "${FORCE_UPDATE:-}" ]]; then
        log_success "gh $current_version already installed (latest)"
        return
    fi

    log_info "Installing gh $version..."
    local gh_arch
    case "$ARCH" in
        x86_64)  gh_arch="linux_amd64" ;;
        aarch64) gh_arch="linux_arm64" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac

    curl -fsSL "https://github.com/cli/cli/releases/download/${latest_tag}/gh_${version}_${gh_arch}.tar.gz" \
        | $SUDO tar -xz -C /usr/local/bin --strip-components=2 "gh_${version}_${gh_arch}/bin/gh"
    log_success "gh $version installed"
}

# Install git-delta
install_delta() {
    local current_version=""
    if has_cmd delta; then
        current_version=$(delta --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    fi

    local latest_tag
    latest_tag=$(get_latest_release "dandavison/delta")
    local version="${latest_tag}"

    if [[ "$current_version" == "$version" ]] && [[ -z "${FORCE_UPDATE:-}" ]]; then
        log_success "delta $current_version already installed (latest)"
        return
    fi

    log_info "Installing delta $version..."
    local delta_arch
    case "$ARCH" in
        x86_64)  delta_arch="x86_64-unknown-linux-musl" ;;
        aarch64) delta_arch="aarch64-unknown-linux-gnu" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac

    curl -fsSL "https://github.com/dandavison/delta/releases/download/${version}/delta-${version}-${delta_arch}.tar.gz" \
        | $SUDO tar -xz -C /usr/local/bin --strip-components=1 "delta-${version}-${delta_arch}/delta"
    log_success "delta $version installed"
}

# Install sd (sed alternative)
install_sd() {
    local current_version=""
    if has_cmd sd; then
        current_version=$(sd --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    fi

    local latest_tag
    latest_tag=$(get_latest_release "chmln/sd")
    local version="${latest_tag#v}"

    if [[ "$current_version" == "$version" ]] && [[ -z "${FORCE_UPDATE:-}" ]]; then
        log_success "sd $current_version already installed (latest)"
        return
    fi

    log_info "Installing sd $version..."
    local sd_arch
    case "$ARCH" in
        x86_64)  sd_arch="x86_64-unknown-linux-musl" ;;
        aarch64) sd_arch="aarch64-unknown-linux-musl" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac

    curl -fsSL "https://github.com/chmln/sd/releases/download/${latest_tag}/sd-${latest_tag}-${sd_arch}.tar.gz" \
        | $SUDO tar -xz -C /usr/local/bin --strip-components=1 "sd-${latest_tag}-${sd_arch}/sd"
    log_success "sd $version installed"
}

# Install starship prompt
install_starship() {
    local current_version=""
    if has_cmd starship; then
        current_version=$(starship --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    fi

    local latest_tag
    latest_tag=$(get_latest_release "starship/starship")
    local version="${latest_tag#v}"

    if [[ "$current_version" == "$version" ]] && [[ -z "${FORCE_UPDATE:-}" ]]; then
        log_success "starship $current_version already installed (latest)"
        return
    fi

    log_info "Installing starship $version..."
    local starship_arch
    case "$ARCH" in
        x86_64)  starship_arch="x86_64-unknown-linux-musl" ;;
        aarch64) starship_arch="aarch64-unknown-linux-musl" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac

    curl -fsSL "https://github.com/starship/starship/releases/download/${latest_tag}/starship-${starship_arch}.tar.gz" \
        | $SUDO tar -xz -C /usr/local/bin starship
    log_success "starship $version installed"
}

# Install changelog tool
install_changelog() {
    local current_version=""
    if has_cmd changelog; then
        current_version=$(changelog --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    fi

    local latest_tag
    latest_tag=$(get_latest_release "schpet/changelog")
    local version="${latest_tag#v}"

    if [[ "$current_version" == "$version" ]] && [[ -z "${FORCE_UPDATE:-}" ]]; then
        log_success "changelog $current_version already installed (latest)"
        return
    fi

    log_info "Installing changelog $version..."
    local changelog_arch
    case "$ARCH" in
        x86_64)  changelog_arch="x86_64-unknown-linux-gnu" ;;
        aarch64) changelog_arch="aarch64-unknown-linux-gnu" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac

    curl -fsSL "https://github.com/schpet/changelog/releases/download/${latest_tag}/changelog-${changelog_arch}.tar.xz" \
        | $SUDO tar -xJ -C /usr/local/bin --strip-components=1 "changelog-${changelog_arch}/changelog"
    log_success "changelog $version installed"
}

# Install svbump tool
install_svbump() {
    local current_version=""
    if has_cmd svbump; then
        current_version=$(svbump --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    fi

    local latest_tag
    latest_tag=$(get_latest_release "schpet/svbump")
    local version="${latest_tag#v}"

    if [[ "$current_version" == "$version" ]] && [[ -z "${FORCE_UPDATE:-}" ]]; then
        log_success "svbump $current_version already installed (latest)"
        return
    fi

    log_info "Installing svbump $version..."
    local svbump_arch
    case "$ARCH" in
        x86_64)  svbump_arch="x86_64-unknown-linux-gnu" ;;
        aarch64) svbump_arch="aarch64-unknown-linux-gnu" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac

    curl -fsSL "https://github.com/schpet/svbump/releases/download/${latest_tag}/svbump-${svbump_arch}.tar.xz" \
        | $SUDO tar -xJ -C /usr/local/bin --strip-components=1 "svbump-${svbump_arch}/svbump"
    log_success "svbump $version installed"
}

# Install neovim
install_neovim() {
    local current_version=""
    if has_cmd nvim; then
        current_version=$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    fi

    local latest_tag
    latest_tag=$(get_latest_release "neovim/neovim")
    local version="${latest_tag#v}"

    if [[ "$current_version" == "$version" ]] && [[ -z "${FORCE_UPDATE:-}" ]]; then
        log_success "neovim $current_version already installed (latest)"
        return
    fi

    log_info "Installing neovim $version..."
    local nvim_arch
    case "$ARCH" in
        x86_64)  nvim_arch="linux-x86_64" ;;
        aarch64) nvim_arch="linux-arm64" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac

    curl -fsSL "https://github.com/neovim/neovim/releases/download/${latest_tag}/nvim-${nvim_arch}.tar.gz" \
        | $SUDO tar -xz -C /usr/local --strip-components=1
    log_success "neovim $version installed"
}

# Install Claude Code CLI
install_claude_code() {
    log_info "Installing/updating Claude Code CLI..."
    $SUDO npm install -g @anthropic-ai/claude-code@latest
    log_success "Claude Code CLI installed"
}

# Install Claude Code plugins
install_claude_plugins() {
    if ! has_cmd claude; then
        log_warn "Claude Code not installed, skipping plugins"
        return
    fi

    log_info "Installing Claude Code plugins..."
    claude plugin marketplace add schpet/toolbox || true
    claude plugin marketplace add anthropics/claude-plugins-official || true
    claude plugin install jj-vcs@toolbox || true
    claude plugin install changelog@toolbox || true
    claude plugin install svbump@toolbox || true
    claude plugin install chores@toolbox || true
    claude plugin install speccer@toolbox || true
    claude plugin install ralph-loop@claude-plugins-official || true

    log_info "Configuring MCP servers..."
    # Use --scope user for global config, --headless --isolated for headless Linux servers
    claude mcp add --scope user chrome-devtools -- npx chrome-devtools-mcp@latest --headless --isolated || true
    log_success "Claude Code plugins and MCP servers configured"
}

# Install dotfiles
install_dotfiles() {
    local dotfiles_dir="${HOME}/dotfiles"

    if [[ -d "$dotfiles_dir" ]]; then
        log_info "Updating dotfiles..."
        cd "$dotfiles_dir"
        git pull --ff-only || log_warn "Could not update dotfiles"
    else
        log_info "Cloning dotfiles..."
        git clone --depth 1 https://github.com/schpet/dotfiles.git "$dotfiles_dir"
    fi

    log_info "Installing dotfiles with stow..."
    cd "$dotfiles_dir"
    stow . -t "$HOME" -v 2 --adopt 2>&1 || log_warn "Stow had some issues (this may be normal)"
    log_success "Dotfiles installed"
}

# Install deno tools (gogreen, easy-bead-oven)
install_deno_tools() {
    local tools_dir="${HOME}/tools"
    mkdir -p "$tools_dir"

    # gogreen
    local gogreen_dir="${tools_dir}/gogreen"
    if [[ -d "$gogreen_dir" ]]; then
        log_info "Updating gogreen..."
        cd "$gogreen_dir"
        git pull --ff-only || log_warn "Could not update gogreen"
    else
        log_info "Installing gogreen..."
        git clone --depth 1 https://github.com/schpet/gogreen.git "$gogreen_dir"
    fi
    cd "$gogreen_dir"
    just install || log_warn "gogreen install had issues"

    # easy-bead-oven
    local ebo_dir="${tools_dir}/easy-bead-oven"
    if [[ -d "$ebo_dir" ]]; then
        log_info "Updating easy-bead-oven..."
        cd "$ebo_dir"
        git pull --ff-only || log_warn "Could not update easy-bead-oven"
    else
        log_info "Installing easy-bead-oven..."
        git clone --depth 1 https://github.com/schpet/easy-bead-oven.git "$ebo_dir"
    fi
    cd "$ebo_dir"
    deno install -c ./deno.json -A -g -f -n ebo ./main.ts || log_warn "ebo install had issues"

    log_success "Deno tools installed"
}

# ============================================================================
# Language-specific environments
# ============================================================================

# Install Deno environment (user-local via official installer)
setup_deno_env() {
    log_info "Setting up Deno environment..."

    export DENO_INSTALL="${HOME}/.deno"

    if [[ -f "${DENO_INSTALL}/bin/deno" ]]; then
        log_info "Updating Deno..."
    fi

    curl -fsSL https://deno.land/install.sh | sh

    # Add to PATH for this session
    export PATH="${DENO_INSTALL}/bin:${PATH}"

    log_success "Deno environment ready"
    deno --version
}

# Install Rust environment
setup_rust_env() {
    log_info "Setting up Rust environment..."

    # Install build dependencies
    export DEBIAN_FRONTEND=noninteractive
    $SUDO apt-get update
    $SUDO apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install -y --no-install-recommends \
        build-essential \
        pkg-config \
        libssl-dev

    export RUSTUP_HOME="${HOME}/.rustup"
    export CARGO_HOME="${HOME}/.cargo"
    export PATH="${CARGO_HOME}/bin:${PATH}"

    if has_cmd rustup; then
        log_info "Updating Rust toolchain..."
        rustup update stable
    else
        log_info "Installing Rust via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
            --default-toolchain stable \
            --component clippy \
            --component rustfmt
    fi

    # Ensure components are installed
    rustup component add clippy rustfmt

    # Install cargo plugins
    log_info "Installing cargo plugins..."
    cargo install cargo-dist cargo-watch cargo-edit || log_warn "Some cargo plugins may have failed"

    log_success "Rust environment ready"
    rustc --version
    cargo --version
}

# Install Ruby on Rails environment
setup_rails_env() {
    log_info "Setting up Ruby on Rails environment..."

    # Install build dependencies
    export DEBIAN_FRONTEND=noninteractive
    $SUDO apt-get update
    $SUDO apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install -y --no-install-recommends \
        autoconf \
        bison \
        build-essential \
        libssl-dev \
        libyaml-dev \
        libreadline-dev \
        zlib1g-dev \
        libncurses-dev \
        libffi-dev \
        libgdbm-dev \
        libdb-dev \
        uuid-dev

    export RBENV_ROOT="${HOME}/.rbenv"
    export PATH="${RBENV_ROOT}/bin:${RBENV_ROOT}/shims:${PATH}"

    # Install or update rbenv
    if [[ -d "$RBENV_ROOT" ]]; then
        log_info "Updating rbenv..."
        cd "$RBENV_ROOT"
        git pull --ff-only || log_warn "Could not update rbenv"
        cd "${RBENV_ROOT}/plugins/ruby-build"
        git pull --ff-only || log_warn "Could not update ruby-build"
    else
        log_info "Installing rbenv..."
        git clone https://github.com/rbenv/rbenv.git "$RBENV_ROOT"
        git clone https://github.com/rbenv/ruby-build.git "${RBENV_ROOT}/plugins/ruby-build"
    fi

    # Get latest stable Ruby version
    local ruby_version
    ruby_version=$("${RBENV_ROOT}/plugins/ruby-build/bin/ruby-build" --definitions | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -1)

    if [[ -z "$ruby_version" ]]; then
        ruby_version="3.3.0"
        log_warn "Could not detect latest Ruby, using $ruby_version"
    fi

    log_info "Installing Ruby $ruby_version..."
    rbenv install -s "$ruby_version"
    rbenv global "$ruby_version"
    rbenv rehash

    # Install gems
    log_info "Installing Ruby gems..."
    gem install ruby-lsp foreman rails --no-document

    # Install rubyfmt
    log_info "Installing rubyfmt..."
    local rubyfmt_arch
    case "$ARCH" in
        x86_64)  rubyfmt_arch="x86_64" ;;
        aarch64) rubyfmt_arch="aarch64" ;;
        *) log_warn "rubyfmt: Unsupported architecture $ARCH"; return ;;
    esac

    local latest_rubyfmt
    latest_rubyfmt=$(get_latest_release "fables-tales/rubyfmt")

    local tmpdir
    tmpdir=$(mktemp -d)
    curl -fsSL "https://github.com/fables-tales/rubyfmt/releases/download/${latest_rubyfmt}/rubyfmt-${latest_rubyfmt}-Linux-${rubyfmt_arch}.tar.gz" \
        | tar -xz -C "$tmpdir"
    $SUDO cp "${tmpdir}/tmp/releases/${latest_rubyfmt#v}-Linux/rubyfmt" /usr/local/bin/rubyfmt || \
    $SUDO cp "${tmpdir}/tmp/releases/${latest_rubyfmt}-Linux/rubyfmt" /usr/local/bin/rubyfmt || \
        log_warn "Could not install rubyfmt"
    $SUDO chmod +x /usr/local/bin/rubyfmt || true
    rm -rf "$tmpdir"

    log_success "Ruby on Rails environment ready"
    ruby --version
    rails --version || log_warn "Rails not fully configured yet"
}

# ============================================================================
# Main installation logic
# ============================================================================

install_base() {
    log_info "=== Installing base development environment ==="

    check_sudo

    # System packages (only on Debian/Ubuntu)
    if [[ -f /etc/debian_version ]]; then
        install_apt_packages
    else
        log_warn "Not a Debian-based system, skipping apt packages"
    fi

    # CLI tools from GitHub releases
    install_eza
    install_jj
    install_deno
    install_just
    install_gh
    install_delta
    install_sd
    install_starship
    install_changelog
    install_svbump
    install_neovim

    # Claude Code
    if has_cmd npm; then
        install_claude_code
        install_claude_plugins
    else
        log_warn "npm not found, skipping Claude Code"
    fi

    # User-level setup (dotfiles, deno tools)
    if [[ $EUID -ne 0 ]]; then
        install_dotfiles
        if has_cmd deno && has_cmd just; then
            install_deno_tools
        fi
    fi

    log_success "=== Base installation complete ==="
}

# Parse arguments
INSTALL_BASE=true
INSTALL_DENO=false
INSTALL_RUST=false
INSTALL_RAILS=false
UPDATE_MODE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --base)
            INSTALL_BASE=true
            shift
            ;;
        --deno)
            INSTALL_DENO=true
            shift
            ;;
        --rust)
            INSTALL_RUST=true
            shift
            ;;
        --rails)
            INSTALL_RAILS=true
            shift
            ;;
        --all)
            INSTALL_DENO=true
            INSTALL_RUST=true
            INSTALL_RAILS=true
            shift
            ;;
        --update)
            UPDATE_MODE=true
            FORCE_UPDATE=1
            export FORCE_UPDATE
            shift
            ;;
        --help|-h)
            echo "Cracked Development Environment Setup"
            echo ""
            echo "Usage:"
            echo "  curl -fsSL https://raw.githubusercontent.com/schpet/cracked/main/setup.sh | bash"
            echo "  ./setup.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --base   Install base tools only (default)"
            echo "  --deno   Install base + Deno environment"
            echo "  --rust   Install base + Rust toolchain"
            echo "  --rails  Install base + Ruby on Rails"
            echo "  --all    Install everything"
            echo "  --update Force update of already installed tools"
            echo "  --help   Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Main execution
main() {
    echo ""
    echo "  ██████╗██████╗  █████╗  ██████╗██╗  ██╗███████╗██████╗ "
    echo " ██╔════╝██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗"
    echo " ██║     ██████╔╝███████║██║     █████╔╝ █████╗  ██║  ██║"
    echo " ██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ██╔══╝  ██║  ██║"
    echo " ╚██████╗██║  ██║██║  ██║╚██████╗██║  ██╗███████╗██████╔╝"
    echo "  ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═════╝ "
    echo ""
    echo "  Development Environment Setup"
    echo "  https://github.com/schpet/cracked"
    echo ""

    if [[ "$OS" != "Linux" ]]; then
        log_error "This script only supports Linux"
        exit 1
    fi

    install_base

    if $INSTALL_DENO; then
        setup_deno_env
    fi

    if $INSTALL_RUST; then
        setup_rust_env
    fi

    if $INSTALL_RAILS; then
        setup_rails_env
    fi

    echo ""
    log_success "=== All installations complete ==="
    echo ""
    echo "Next steps:"
    echo "  1. Restart your shell or run: source ~/.bashrc"
    echo "  2. If using fish, it should work immediately"
    echo ""
}

main
