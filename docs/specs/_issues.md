# issues

actionable issues with acceptance criteria, organized by implementation order.

decisions applied:
- base os: debian/ubuntu
- architectures: amd64 + arm64
- image naming: variant tags (ghcr.io/schpet/cracked:base, :deno, :rust, :rails)
- container user: root
- tools directory: ~/tools
- dotfiles: run install.sh from dotfiles repo
- jj verification: email = code@schpet.com
- ruby: latest stable + ruby lsp
- rust: clippy, rustfmt, cargo-watch, cargo-edit included
- onboarding: markdown checklist

---

## phase 1: base image foundation

### CRACKED-001: set up base dockerfile structure

**feature**: base-image

**acceptance criteria:**
- [ ] Dockerfile created with debian/ubuntu base image
- [ ] multi-arch support configured (amd64 + arm64)
- [ ] working directory established
- [ ] basic build succeeds and image can be run
- [ ] image tagged as `ghcr.io/schpet/cracked:base`

---

### CRACKED-002: install core system tools

**feature**: base-image

**acceptance criteria:**
- [ ] fish shell installed and set as default shell
- [ ] git installed and verified (`git --version`)
- [ ] ripgrep installed (`rg --version`)
- [ ] fd installed (`fd --version`)
- [ ] fzf installed (`fzf --version`)
- [ ] eza installed (`eza --version`)
- [ ] stow installed (`stow --version`)
- [ ] jq installed (`jq --version`)
- [ ] jo installed (`jo --version`)
- [ ] all tools accessible in PATH

---

### CRACKED-003: install jj (jujutsu) version control

**feature**: base-image

**acceptance criteria:**
- [ ] jj installed from appropriate source
- [ ] `jj --version` returns expected output
- [ ] basic jj commands functional (init, status)
- [ ] jj accessible in PATH

---

### CRACKED-004: install development tools (deno, just, gh)

**feature**: base-image

**acceptance criteria:**
- [ ] deno installed (`deno --version`)
- [ ] just installed (`just --version`)
- [ ] github cli installed (`gh --version`)
- [ ] all tools accessible in PATH

---

### CRACKED-005: install text processing utilities (git-delta, sd)

**feature**: base-image

**acceptance criteria:**
- [ ] git-delta installed (`delta --version`)
- [ ] sd installed (`sd --version`)
- [ ] both tools accessible in PATH

---

### CRACKED-006: install starship prompt

**feature**: base-image

**acceptance criteria:**
- [ ] starship installed (`starship --version`)
- [ ] starship configured to work with fish shell
- [ ] prompt renders correctly when fish shell starts

---

### CRACKED-007: install claude code cli

**feature**: base-image

**acceptance criteria:**
- [ ] claude code installed
- [ ] `claude --version` works
- [ ] tool accessible in PATH

---

### CRACKED-008: install custom github release binaries

**feature**: base-image

**acceptance criteria:**
- [ ] changelog binary downloaded from schpet/changelog releases
- [ ] svbump binary downloaded from schpet/svbump releases
- [ ] both binaries installed to /usr/local/bin
- [ ] both binaries are executable
- [ ] installation handles architecture detection (amd64/arm64)

---

### CRACKED-009: configure fish shell environment

**feature**: base-image

**acceptance criteria:**
- [ ] fish set as default shell (SHELL env var)
- [ ] fish configuration directory structure created
- [ ] starship prompt integration configured
- [ ] PATH includes deno bin directory (~/.deno/bin)
- [ ] shell starts without errors

---

## phase 2: dotfiles integration

### CRACKED-010: clone and install dotfiles

**feature**: dotfiles

**acceptance criteria:**
- [ ] schpet/dotfiles repository cloned during image build
- [ ] `install.sh` script from dotfiles repo executed successfully
- [ ] symlinks created in expected home directory locations
- [ ] stow output logged for debugging

---

### CRACKED-011: verify jj configuration

**feature**: dotfiles

**acceptance criteria:**
- [ ] jj config file exists (~/.config/jj/config.toml or ~/.jjconfig.toml)
- [ ] `jj config get user.email` returns `code@schpet.com`
- [ ] jj configuration functional

---

## phase 3: deno tools

### CRACKED-012: set up tools directory and clone repos

**feature**: deno-tools

**acceptance criteria:**
- [ ] ~/tools directory created
- [ ] gogreen repository cloned to ~/tools/gogreen
- [ ] easy-bead-oven repository cloned to ~/tools/easy-bead-oven
- [ ] .git directories preserved for update capability

---

### CRACKED-013: install gogreen with deno

**feature**: deno-tools

**acceptance criteria:**
- [ ] gogreen installed (via just install or deno install)
- [ ] gogreen command available after installation
- [ ] installation completes without errors

---

### CRACKED-014: install easy-bead-oven with deno

**feature**: deno-tools

**acceptance criteria:**
- [ ] `deno install -A -g -f -n ebo jsr:@schpet/easy-bead-oven` executed
- [ ] ebo command available after installation
- [ ] installation completes without errors

---

### CRACKED-015: verify deno tools in PATH

**feature**: deno-tools

**acceptance criteria:**
- [ ] gogreen executable in fish shell (`which gogreen`)
- [ ] ebo executable in fish shell (`which ebo`)
- [ ] PATH configuration persists across shell sessions

---

## phase 4: child images

### CRACKED-016: implement deno child image (test case)

**feature**: child-images

**acceptance criteria:**
- [ ] Dockerfile.deno created inheriting from base image
- [ ] image builds successfully using base as parent
- [ ] deno executable functional in resulting image
- [ ] all base image tools accessible
- [ ] image tagged as `ghcr.io/schpet/cracked:deno`

---

### CRACKED-017: implement rust child image

**feature**: child-images

**acceptance criteria:**
- [ ] Dockerfile.rust created inheriting from base image
- [ ] rust toolchain installed (rustc, cargo)
- [ ] cargo-dist installed and available
- [ ] clippy, rustfmt installed
- [ ] cargo-watch, cargo-edit installed
- [ ] verification: `cargo new hello && cd hello && cargo run` outputs "Hello, world!"
- [ ] image tagged as `ghcr.io/schpet/cracked:rust`

---

### CRACKED-018: implement ruby on rails child image

**feature**: child-images

**acceptance criteria:**
- [ ] Dockerfile.rails created inheriting from base image
- [ ] rbenv installed and configured
- [ ] latest stable ruby installed via rbenv
- [ ] ruby-lsp installed
- [ ] rubyfmt installed
- [ ] foreman installed
- [ ] rails gem installed
- [ ] verification: `rails new testapp` succeeds
- [ ] image tagged as `ghcr.io/schpet/cracked:rails`

---

## phase 5: build & ci/cd

### CRACKED-019: create local container build script

**feature**: build-ci

**acceptance criteria:**
- [ ] build script exists (justfile or build.sh)
- [ ] script can build all container images locally
- [ ] script accepts image variant as parameter
- [ ] script works with docker
- [ ] script provides clear error messages on failure
- [ ] script outputs image ID and size on success

---

### CRACKED-020: setup github actions workflow

**feature**: build-ci

**acceptance criteria:**
- [ ] workflow file at `.github/workflows/container.yml`
- [ ] triggers on `container-v*` tags and manual dispatch
- [ ] multi-arch support (QEMU + Buildx)
- [ ] authenticates to github container registry
- [ ] builds all image variants (base, deno, rust, rails)
- [ ] generates version + latest tags
- [ ] pushes to ghcr.io/schpet/cracked:*
- [ ] includes build caching

---

### CRACKED-021: implement container verification

**feature**: build-ci

**acceptance criteria:**
- [ ] verification step uses `gh` to confirm images published
- [ ] checks all expected tags present
- [ ] clear success/failure output
- [ ] can be run manually or as part of CI

---

## phase 6: documentation & onboarding

### CRACKED-022: create casual readme

**feature**: onboarding

**acceptance criteria:**
- [ ] `readme.md` created (lowercase)
- [ ] casual tone throughout
- [ ] describes: "github repo that has a collection of dockerfiles that i use for dev"
- [ ] mentions dotfiles baked in via stow
- [ ] disclaimer: "useful for me and just published for reference"
- [ ] minimal but informative

---

### CRACKED-023: create onboarding checklist

**feature**: onboarding

**acceptance criteria:**
- [ ] markdown checklist for environment setup
- [ ] step-by-step instructions for `gh auth login`
- [ ] step-by-step instructions for claude code login
- [ ] verification commands (`gh auth status`)
- [ ] links to relevant documentation
- [ ] notes prerequisites

---

### CRACKED-024: document build and release process

**feature**: build-ci

**acceptance criteria:**
- [ ] readme includes local build instructions
- [ ] explains how to trigger production builds
- [ ] documents tagging strategy
- [ ] documents how to verify successful publication
- [ ] troubleshooting section

---

## summary

| phase | issues | description |
|-------|--------|-------------|
| 1 | CRACKED-001 to CRACKED-009 | base image foundation |
| 2 | CRACKED-010 to CRACKED-011 | dotfiles integration |
| 3 | CRACKED-012 to CRACKED-015 | deno tools |
| 4 | CRACKED-016 to CRACKED-018 | child images |
| 5 | CRACKED-019 to CRACKED-021 | build & ci/cd |
| 6 | CRACKED-022 to CRACKED-024 | documentation & onboarding |

**total: 24 issues across 6 phases**
