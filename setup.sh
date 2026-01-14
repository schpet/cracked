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
    local auth_header=""
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        auth_header="-H \"Authorization: token $GITHUB_TOKEN\""
    fi
    local result
    result=$(curl -fsSL $auth_header "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    if [[ -z "$result" ]]; then
        log_warn "Could not fetch latest release for $repo (rate limited?). Skipping..."
        return 1
    fi
    echo "$result"
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

    # Install ghostty terminfo for proper terminal support
    if ! infocmp xterm-ghostty &>/dev/null; then
        log_info "Installing ghostty terminfo..."
        $SUDO tic -x - <<'TERMINFO'
xterm-ghostty|ghostty|Ghostty,
	am, bce, ccc, hs, km, mc5i, mir, msgr, npc, xenl, AX, Su, Tc, XT, fullkbd,
	colors#0x100, cols#80, it#8, lines#24, pairs#0x7fff,
	acsc=++\,\,--..00``aaffgghhiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~,
	bel=^G, blink=\E[5m, bold=\E[1m, cbt=\E[Z, civis=\E[?25l,
	clear=\E[H\E[2J, cnorm=\E[?12l\E[?25h, cr=\r,
	csr=\E[%i%p1%d;%p2%dr, cub=\E[%p1%dD, cub1=^H,
	cud=\E[%p1%dB, cud1=\n, cuf=\E[%p1%dC, cuf1=\E[C,
	cup=\E[%i%p1%d;%p2%dH, cuu=\E[%p1%dA, cuu1=\E[A,
	cvvis=\E[?12;25h, dch=\E[%p1%dP, dch1=\E[P, dim=\E[2m,
	dl=\E[%p1%dM, dl1=\E[M, dsl=\E]2;\007, ech=\E[%p1%dX,
	ed=\E[J, el=\E[K, el1=\E[1K, flash=\E[?5h$<100/>\E[?5l,
	fsl=^G, home=\E[H, hpa=\E[%i%p1%dG, ht=^I, hts=\EH,
	ich=\E[%p1%d@, ich1=\E[@, il=\E[%p1%dL, il1=\E[L, ind=\n,
	indn=\E[%p1%dS,
	initc=\E]4;%p1%d;rgb:%p2%{255}%*%{1000}%/%2.2X/%p3%{255}%*%{1000}%/%2.2X/%p4%{255}%*%{1000}%/%2.2X\E\\,
	invis=\E[8m, kDC=\E[3;2~, kEND=\E[1;2F, kHOM=\E[1;2H,
	kIC=\E[2;2~, kLFT=\E[1;2D, kNXT=\E[6;2~, kPRV=\E[5;2~,
	kRIT=\E[1;2C, kbs=^?, kcbt=\E[Z, kcub1=\EOD, kcud1=\EOB,
	kcuf1=\EOC, kcuu1=\EOA, kdch1=\E[3~, kend=\EOF, kent=\EOM,
	kf1=\EOP, kf10=\E[21~, kf11=\E[23~, kf12=\E[24~,
	kf13=\E[1;2P, kf14=\E[1;2Q, kf15=\E[1;2R, kf16=\E[1;2S,
	kf17=\E[15;2~, kf18=\E[17;2~, kf19=\E[18;2~, kf2=\EOQ,
	kf20=\E[19;2~, kf21=\E[20;2~, kf22=\E[21;2~,
	kf23=\E[23;2~, kf24=\E[24;2~, kf25=\E[1;5P, kf26=\E[1;5Q,
	kf27=\E[1;5R, kf28=\E[1;5S, kf29=\E[15;5~, kf3=\EOR,
	kf30=\E[17;5~, kf31=\E[18;5~, kf32=\E[19;5~,
	kf33=\E[20;5~, kf34=\E[21;5~, kf35=\E[23;5~,
	kf36=\E[24;5~, kf37=\E[1;6P, kf38=\E[1;6Q, kf39=\E[1;6R,
	kf4=\EOS, kf40=\E[1;6S, kf41=\E[15;6~, kf42=\E[17;6~,
	kf43=\E[18;6~, kf44=\E[19;6~, kf45=\E[20;6~,
	kf46=\E[21;6~, kf47=\E[23;6~, kf48=\E[24;6~,
	kf49=\E[1;3P, kf5=\E[15~, kf50=\E[1;3Q, kf51=\E[1;3R,
	kf52=\E[1;3S, kf53=\E[15;3~, kf54=\E[17;3~,
	kf55=\E[18;3~, kf56=\E[19;3~, kf57=\E[20;3~,
	kf58=\E[21;3~, kf59=\E[23;3~, kf6=\E[17~, kf60=\E[24;3~,
	kf61=\E[1;4P, kf62=\E[1;4Q, kf63=\E[1;4R, kf7=\E[18~,
	kf8=\E[19~, kf9=\E[20~, khome=\EOH, kich1=\E[2~,
	kind=\E[1;2B, kmous=\E[<, knp=\E[6~, kpp=\E[5~,
	kri=\E[1;2A, oc=\E]104\007, op=\E[39;49m, rc=\E8,
	rep=%p1%c\E[%p2%{1}%-%db, rev=\E[7m, ri=\EM,
	rin=\E[%p1%dT, ritm=\E[23m, rmacs=\E(B, rmam=\E[?7l,
	rmcup=\E[?1049l, rmir=\E[4l, rmkx=\E[?1l\E>, rmso=\E[27m,
	rmul=\E[24m, rs1=\E]\E\\\Ec, sc=\E7,
	setab=\E[%?%p1%{8}%<%t4%p1%d%e%p1%{16}%<%t10%p1%{8}%-%d%e48;5;%p1%d%;m,
	setaf=\E[%?%p1%{8}%<%t3%p1%d%e%p1%{16}%<%t9%p1%{8}%-%d%e38;5;%p1%d%;m,
	sgr=%?%p9%t\E(0%e\E(B%;\E[0%?%p6%t;1%;%?%p2%t;4%;%?%p1%p3%|%t;7%;%?%p4%t;5%;%?%p7%t;8%;m,
	sgr0=\E(B\E[m, sitm=\E[3m, smacs=\E(0, smam=\E[?7h,
	smcup=\E[?1049h, smir=\E[4h, smkx=\E[?1h\E=, smso=\E[7m,
	smul=\E[4m, tbc=\E[3g, tsl=\E]2;, u6=\E[%i%d;%dR, u7=\E[6n,
	u8=\E[?%[;0123456789]c, u9=\E[c, vpa=\E[%i%p1%dd,
	BD=\E[?2004l, BE=\E[?2004h, Clmg=\E[s,
	Cmg=\E[%i%p1%d;%p2%ds, Dsmg=\E[?69l, E3=\E[3J,
	Enmg=\E[?69h, Ms=\E]52;%p1%s;%p2%s\007, PE=\E[201~,
	PS=\E[200~, RV=\E[>c, Se=\E[2 q,
	Setulc=\E[58:2::%p1%{65536}%/%d:%p1%{256}%/%{255}%&%d:%p1%{255}%&%d%;m,
	Smulx=\E[4:%p1%dm, Ss=\E[%p1%d q,
	Sync=\E[?2026%?%p1%{1}%-%tl%eh%;,
	XM=\E[?1006;1000%?%p1%{1}%=%th%el%;, XR=\E[>0q,
	fd=\E[?1004l, fe=\E[?1004h, kDC3=\E[3;3~, kDC4=\E[3;4~,
	kDC5=\E[3;5~, kDC6=\E[3;6~, kDC7=\E[3;7~, kDN=\E[1;2B,
	kDN3=\E[1;3B, kDN4=\E[1;4B, kDN5=\E[1;5B, kDN6=\E[1;6B,
	kDN7=\E[1;7B, kEND3=\E[1;3F, kEND4=\E[1;4F,
	kEND5=\E[1;5F, kEND6=\E[1;6F, kEND7=\E[1;7F,
	kHOM3=\E[1;3H, kHOM4=\E[1;4H, kHOM5=\E[1;5H,
	kHOM6=\E[1;6H, kHOM7=\E[1;7H, kIC3=\E[2;3~, kIC4=\E[2;4~,
	kIC5=\E[2;5~, kIC6=\E[2;6~, kIC7=\E[2;7~, kLFT3=\E[1;3D,
	kLFT4=\E[1;4D, kLFT5=\E[1;5D, kLFT6=\E[1;6D,
	kLFT7=\E[1;7D, kNXT3=\E[6;3~, kNXT4=\E[6;4~,
	kNXT5=\E[6;5~, kNXT6=\E[6;6~, kNXT7=\E[6;7~,
	kPRV3=\E[5;3~, kPRV4=\E[5;4~, kPRV5=\E[5;5~,
	kPRV6=\E[5;6~, kPRV7=\E[5;7~, kRIT3=\E[1;3C,
	kRIT4=\E[1;4C, kRIT5=\E[1;5C, kRIT6=\E[1;6C,
	kRIT7=\E[1;7C, kUP=\E[1;2A, kUP3=\E[1;3A, kUP4=\E[1;4A,
	kUP5=\E[1;5A, kUP6=\E[1;6A, kUP7=\E[1;7A, kxIN=\E[I,
	kxOUT=\E[O, rmxx=\E[29m, rv=\E\\[[0-9]+;[0-9]+;[0-9]+c,
	setrgbb=\E[48:2:%p1%d:%p2%d:%p3%dm,
	setrgbf=\E[38:2:%p1%d:%p2%d:%p3%dm, smxx=\E[9m,
	xm=\E[<%i%p3%d;%p1%d;%p2%d;%?%p4%tM%em%;,
	xr=\EP>\\|[ -~]+a\E\\,
TERMINFO
        log_success "Ghostty terminfo installed"
    fi

    # Set fish as default shell
    if has_cmd fish; then
        local fish_path
        fish_path=$(command -v fish)
        local current_shell
        current_shell=$(getent passwd "$USER" | cut -d: -f7)
        if [[ "$current_shell" != "$fish_path" ]]; then
            log_info "Setting fish as default shell..."
            $SUDO chsh -s "$fish_path" "$USER"
            log_success "Fish set as default shell"
        fi
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
    latest_tag=$(get_latest_release "eza-community/eza") || return 0
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
    latest_tag=$(get_latest_release "jj-vcs/jj") || return 0
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
    latest_tag=$(get_latest_release "denoland/deno") || return 0
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
    latest_tag=$(get_latest_release "casey/just") || return 0
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
    latest_tag=$(get_latest_release "cli/cli") || return 0
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
    latest_tag=$(get_latest_release "dandavison/delta") || return 0
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
    latest_tag=$(get_latest_release "chmln/sd") || return 0
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
    latest_tag=$(get_latest_release "starship/starship") || return 0
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
    latest_tag=$(get_latest_release "schpet/changelog") || return 0
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
    latest_tag=$(get_latest_release "schpet/svbump") || return 0
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

# Install atuin (shell history)
install_atuin() {
    local current_version=""
    if has_cmd atuin; then
        current_version=$(atuin --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    fi

    local latest_tag
    latest_tag=$(get_latest_release "atuinsh/atuin") || return 0
    local version="${latest_tag#v}"

    if [[ "$current_version" == "$version" ]] && [[ -z "${FORCE_UPDATE:-}" ]]; then
        log_success "atuin $current_version already installed (latest)"
        return
    fi

    log_info "Installing atuin $version..."
    local atuin_arch
    case "$ARCH" in
        x86_64)  atuin_arch="x86_64-unknown-linux-gnu" ;;
        aarch64) atuin_arch="aarch64-unknown-linux-gnu" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac

    curl -fsSL "https://github.com/atuinsh/atuin/releases/download/${latest_tag}/atuin-${atuin_arch}.tar.gz" \
        | $SUDO tar -xz -C /usr/local/bin --strip-components=1 "atuin-${atuin_arch}/atuin"
    log_success "atuin $version installed"
}

# Install direnv
install_direnv() {
    local current_version=""
    if has_cmd direnv; then
        current_version=$(direnv --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    fi

    local latest_tag
    latest_tag=$(get_latest_release "direnv/direnv") || return 0
    local version="${latest_tag#v}"

    if [[ "$current_version" == "$version" ]] && [[ -z "${FORCE_UPDATE:-}" ]]; then
        log_success "direnv $current_version already installed (latest)"
        return
    fi

    log_info "Installing direnv $version..."
    local direnv_arch
    case "$ARCH" in
        x86_64)  direnv_arch="linux-amd64" ;;
        aarch64) direnv_arch="linux-arm64" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac

    curl -fsSL "https://github.com/direnv/direnv/releases/download/${latest_tag}/direnv.${direnv_arch}" \
        -o /tmp/direnv
    $SUDO install -m 755 /tmp/direnv /usr/local/bin/direnv
    rm /tmp/direnv
    log_success "direnv $version installed"
}

# Install neovim
install_neovim() {
    local current_version=""
    if has_cmd nvim; then
        current_version=$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    fi

    local latest_tag
    latest_tag=$(get_latest_release "neovim/neovim") || return 0
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
    if has_cmd claude; then
        log_success "Claude Code already installed (run 'claude update' to update)"
        return
    fi
    log_info "Installing Claude Code CLI..."
    $SUDO npm install -g @anthropic-ai/claude-code@latest || log_warn "Claude Code install had issues"
    log_success "Claude Code CLI installed"
}

# Install Claude Code plugins
install_claude_plugins() {
    if ! has_cmd claude; then
        log_warn "Claude Code not installed, skipping plugins"
        return
    fi

    log_info "Installing Claude Code plugins..."
    claude plugin marketplace add schpet/toolbox 2>/dev/null || true
    claude plugin marketplace add anthropics/claude-plugins-official 2>/dev/null || true
    claude plugin install jj-vcs@toolbox 2>/dev/null || true
    claude plugin install changelog@toolbox 2>/dev/null || true
    claude plugin install svbump@toolbox 2>/dev/null || true
    claude plugin install chores@toolbox 2>/dev/null || true
    claude plugin install speccer@toolbox 2>/dev/null || true
    claude plugin install ralph-loop@claude-plugins-official 2>/dev/null || true

    log_info "Configuring MCP servers..."
    # Use --scope user for global config, --headless --isolated for headless Linux servers
    claude mcp add --scope user chrome-devtools -- npx chrome-devtools-mcp@latest --headless --isolated 2>/dev/null || true
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

# Clone cracked repo for easy development
install_cracked_repo() {
    local tools_dir="${HOME}/tools"
    mkdir -p "$tools_dir"

    local cracked_dir="${tools_dir}/cracked"
    if [[ -d "$cracked_dir" ]]; then
        log_info "Updating cracked repo..."
        cd "$cracked_dir"
        git pull --ff-only || log_warn "Could not update cracked"
    else
        log_info "Cloning cracked repo..."
        git clone --depth 1 https://github.com/schpet/cracked.git "$cracked_dir"
    fi
    log_success "Cracked repo available at ~/tools/cracked"
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

    # Add rbenv to fish PATH if fish is installed
    if has_cmd fish; then
        local fish_config_dir="${HOME}/.config/fish/conf.d"
        mkdir -p "$fish_config_dir"
        cat > "${fish_config_dir}/rbenv.fish" <<'FISHCONFIG'
# rbenv setup
set -gx RBENV_ROOT $HOME/.rbenv
fish_add_path -g $RBENV_ROOT/bin $RBENV_ROOT/shims
FISHCONFIG
        log_info "Added rbenv to fish PATH"
    fi

    # Get Ruby version (use provided version or detect latest)
    local ruby_version
    if [[ -n "$RUBY_VERSION" ]]; then
        ruby_version="$RUBY_VERSION"
        log_info "Using specified Ruby version: $ruby_version"
    else
        ruby_version=$("${RBENV_ROOT}/plugins/ruby-build/bin/ruby-build" --definitions | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -1)
        if [[ -z "$ruby_version" ]]; then
            ruby_version="3.3.0"
            log_warn "Could not detect latest Ruby, using $ruby_version"
        fi
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
    if ! latest_rubyfmt=$(get_latest_release "fables-tales/rubyfmt"); then
        log_warn "Could not fetch rubyfmt release, skipping"
        log_success "Ruby on Rails environment ready"
        ruby --version
        rails --version || log_warn "Rails not fully configured yet"
        return
    fi

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
    install_atuin
    install_direnv
    install_neovim

    # Claude Code
    if has_cmd npm; then
        install_claude_code
        install_claude_plugins
    else
        log_warn "npm not found, skipping Claude Code"
    fi

    # User-level setup (dotfiles, deno tools, cracked repo)
    if [[ $EUID -ne 0 ]]; then
        install_dotfiles
        install_cracked_repo
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
RUBY_VERSION=""

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
        --ruby-version)
            RUBY_VERSION="$2"
            shift 2
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
            echo "  --base           Install base tools only (default)"
            echo "  --deno           Install base + Deno environment"
            echo "  --rust           Install base + Rust toolchain"
            echo "  --rails          Install base + Ruby on Rails"
            echo "  --ruby-version   Ruby version to install (e.g., 3.4.1), used with --rails"
            echo "  --all            Install everything"
            echo "  --update         Force update of already installed tools"
            echo "  --help           Show this help message"
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
    echo "  3. To update Claude Code: claude update"
    echo ""
}

main
