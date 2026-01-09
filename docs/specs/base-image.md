# Feature: base-image

## Summary

The base-image is the foundational Docker image for the "cracked" development environment, containing a curated collection of modern CLI tools and development utilities. This image will serve as the parent for specialized derivative images (deno, rust, rails) and needs to provide a consistent, fish-shell-based environment with version control, search, and utility tools. The primary challenge lies in balancing image size with tool availability, managing installation methods across diverse tools, and ensuring reproducible builds with appropriate version pinning.

## Key Requirements

- Base OS selection (likely Debian/Ubuntu or Alpine-based)
- Fish shell configured as default shell
- Version control tools: jj (jujutsu), git
- Search and navigation: ripgrep, fd, fzf, eza
- Development utilities: deno, just, gh, jq, jo, git-delta, sd, stow
- CLI enhancement: starship prompt
- IDE/Editor: claude code
- Custom tools from GitHub releases:
  - changelog (schpet/changelog)
  - svbump (schpet/svbump)
- All tools properly installed in PATH
- Image must be publishable to ghcr.io

## Ambiguities/Questions

1. **What base OS should be used?**
   - **Why it matters**: Impacts installation methods, package availability, image size, and security update mechanisms. Alpine is smaller but may have compatibility issues with some tools. Debian/Ubuntu are larger but offer broader package support.

2. **What are the version pinning requirements?**
   - **Why it matters**: Determines build reproducibility and maintenance burden. Should versions be pinned to specific releases, use "latest", or follow semantic version ranges? Affects both stability and security update strategy.

3. **What is the target image size constraint?**
   - **Why it matters**: Influences decisions about multi-stage builds, cleanup steps, and whether to include certain tools. Compressed vs uncompressed size targets affect usability and CI/CD performance.

4. **How should tools with multiple installation methods be prioritized?**
   - **Why it matters**: Many tools can be installed via package managers (apt/apk), cargo, npm, or direct binary downloads. The choice affects build time, reproducibility, and image layers. For example: ripgrep via apt vs cargo vs GitHub releases.

5. **What are the architecture requirements (amd64, arm64, multi-arch)?**
   - **Why it matters**: Determines build complexity and whether multi-platform builds are needed. Some tools may not have pre-built binaries for all architectures, requiring compilation or alternative approaches.

6. **Should the image include development dependencies (compilers, build tools)?**
   - **Why it matters**: Some tools may require compilation from source if binaries aren't available. This significantly increases image size but provides flexibility. Alternatively, multi-stage builds could be used.

7. **What shell configuration should be included?**
   - **Why it matters**: Fish requires configuration files for plugins, themes, and custom functions. Should these be minimal or comprehensive? How should starship be configured? Should fish plugins be included?

8. **How should GitHub release binaries be updated?**
   - **Why it matters**: changelog and svbump need to fetch from GitHub releases. This requires a strategy for version tracking and updates, plus handling GitHub API rate limits during builds.

9. **What are the security and vulnerability scanning requirements?**
   - **Why it matters**: Determines whether to include security scanning in CI, how to handle CVEs in dependencies, and update policies for base images.

10. **Should there be an "entrypoint" or just bash/fish shell?**
    - **Why it matters**: Affects how the container is used - as an interactive development environment, as a base for other images, or for running specific commands. The entrypoint design impacts usability.

11. **What is the update/maintenance cadence?**
    - **Why it matters**: Influences automation needs for dependency updates, whether to use dependabot-like tooling, and how aggressively to track upstream tool versions.

12. **Are there specific version requirements for any of the listed tools?**
    - **Why it matters**: Some tools have breaking changes between versions (especially jj which is pre-1.0). Knowing minimum required versions helps ensure compatibility with expected workflows.

## Suggested Issues

### Issue: Set up base Dockerfile structure

**Acceptance Criteria:**
- [ ] Dockerfile created with chosen base image declared
- [ ] Multi-stage build structure implemented (if applicable)
- [ ] Non-root user created with appropriate permissions
- [ ] Working directory established
- [ ] Basic build succeeds and image can be run
- [ ] Image tagged with appropriate naming convention
- [ ] Documentation includes justification for base OS choice

### Issue: Install system package manager tools

**Acceptance Criteria:**
- [ ] Fish shell installed and set as default shell (/etc/passwd or SHELL env)
- [ ] Ripgrep installed and verified (rg --version)
- [ ] fd installed and verified (fd --version)
- [ ] fzf installed and verified (fzf --version)
- [ ] eza installed and verified (eza --version)
- [ ] git installed with minimum required version
- [ ] stow installed and verified
- [ ] jq installed and verified
- [ ] All tools accessible in PATH
- [ ] Build layer optimized for caching

### Issue: Install jj (jujutsu) version control

**Acceptance Criteria:**
- [ ] jj installed from appropriate source (cargo, binary release, or package)
- [ ] Installation method documented in Dockerfile comments
- [ ] jj --version returns expected output
- [ ] Basic jj commands functional (init, status)
- [ ] jj accessible in PATH
- [ ] Version pinned or version strategy documented

### Issue: Install development tools (deno, just, gh)

**Acceptance Criteria:**
- [ ] Deno installed and verified (deno --version)
- [ ] Just installed and verified (just --version)
- [ ] GitHub CLI (gh) installed and verified (gh --version)
- [ ] All tools accessible in PATH
- [ ] Installation methods optimized for image size
- [ ] Version pinning implemented according to project strategy

### Issue: Install text processing utilities (jo, git-delta, sd)

**Acceptance Criteria:**
- [ ] jo installed and verified (jo --version)
- [ ] git-delta installed and verified (delta --version)
- [ ] sd installed and verified (sd --version)
- [ ] All tools accessible in PATH
- [ ] Build succeeds with all utilities functional

### Issue: Install starship prompt

**Acceptance Criteria:**
- [ ] Starship installed and verified (starship --version)
- [ ] Starship configured to work with fish shell
- [ ] Configuration file placed in appropriate location
- [ ] Prompt renders correctly when fish shell starts
- [ ] Custom configuration (if any) documented

### Issue: Install claude code CLI

**Acceptance Criteria:**
- [ ] Claude code installed from appropriate source
- [ ] Installation method documented
- [ ] claude --version or equivalent command works
- [ ] Tool accessible in PATH
- [ ] Any authentication/setup requirements documented

### Issue: Install custom GitHub release binaries (changelog, svbump)

**Acceptance Criteria:**
- [ ] changelog binary downloaded from schpet/changelog releases
- [ ] svbump binary downloaded from schpet/svbump releases
- [ ] Both binaries installed to appropriate PATH location (e.g., /usr/local/bin)
- [ ] Both binaries are executable
- [ ] changelog --version works (if supported)
- [ ] svbump --version works (if supported)
- [ ] Installation handles architecture detection (amd64/arm64)
- [ ] GitHub API rate limits considered/handled

### Issue: Configure fish shell environment

**Acceptance Criteria:**
- [ ] Fish set as default shell (SHELL environment variable)
- [ ] Fish configuration directory structure created
- [ ] Starship prompt integration configured
- [ ] Basic fish config.fish created with PATH setup
- [ ] Shell starts without errors
- [ ] Interactive and non-interactive modes both work
- [ ] Environment variables properly passed to fish

### Issue: Optimize image size and layers

**Acceptance Criteria:**
- [ ] Package manager caches cleaned up
- [ ] Temporary build files removed
- [ ] Related commands combined in single RUN statements where beneficial
- [ ] .dockerignore file created if needed
- [ ] Image size documented (compressed and uncompressed)
- [ ] Layer count optimized (target: < 20 layers if possible)
- [ ] Build cache strategy documented

### Issue: Create image build and test script

**Acceptance Criteria:**
- [ ] Local build script created (e.g., build.sh or justfile target)
- [ ] Build script includes tagging strategy
- [ ] Smoke test script verifies all tools are installed
- [ ] Test script checks all tools are in PATH
- [ ] Test script verifies fish shell is default
- [ ] Test runs in CI/CD environment (if applicable)
- [ ] Script handles build failures gracefully

### Issue: Document base image usage and architecture

**Acceptance Criteria:**
- [ ] README or docs section explains base image purpose
- [ ] Tool list with versions documented
- [ ] Build instructions provided
- [ ] Usage examples included (docker run commands)
- [ ] Architecture decisions documented (OS choice, installation methods)
- [ ] Update/maintenance process documented
- [ ] Known limitations or gotchas listed

### Issue: Set up multi-architecture support (if required)

**Acceptance Criteria:**
- [ ] Dockerfile supports amd64 architecture
- [ ] Dockerfile supports arm64 architecture (if required)
- [ ] Architecture-specific logic implemented where needed
- [ ] Build process supports --platform flag
- [ ] Both architectures tested
- [ ] Multi-arch manifest created
- [ ] Documentation updated with architecture support details
