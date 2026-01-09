# child-images

## summary

derivative docker images that inherit from the base image, adding language/framework-specific tooling for common development stacks. three initial variants planned: deno (test case), rust (with cargo ecosystem), and ruby on rails (with rbenv and rails tooling). each image extends the base with minimal additional layers while maintaining the core development environment and dotfiles.

## key requirements

- inherit from base image to preserve all core tooling and dotfiles
- deno image: use as test case (deno already in base, verify inheritance works)
- rust image: install cargo, rust toolchain, cargo-dist
- ruby on rails image: install rbenv, current stable ruby, rubyfmt, foreman, rails
- verification criteria defined per-image:
  - deno: (implicit - inheritance test)
  - rust: can create and run a rust cli that prints "hello world"
  - ruby on rails: can successfully run `rails new`
- images should follow dockerfile best practices (layer caching, minimal layers)
- publish to github container registry (ghcr.io) alongside base image

## ambiguities/questions

1. **what is "current stable ruby"?**
   - matters for: determining which ruby version to install via rbenv
   - options: latest stable release (e.g., 3.3.x), latest LTS, specific version pinned
   - impact: affects reproducibility and maintenance burden

2. **should ruby lsp be included?**
   - context: marked with "?" in requirements
   - matters for: editor integration and development experience
   - consideration: adds dependencies, but improves editor support for ruby development

3. **cargo-dist version/installation method?**
   - context: tool referenced by github url but no version specified
   - matters for: reproducibility and build stability
   - options: latest release, specific version, install via cargo install vs binary download

4. **layer optimization strategy?**
   - context: how should we balance layer count vs cacheability
   - matters for: build times and image size
   - consideration: install tooling in single RUN vs separate for better caching

5. **versioning strategy for child images?**
   - context: how do child image versions relate to base image versions
   - matters for: dependency management and release workflow
   - options: coupled versioning (child v1.0 uses base v1.0), independent versioning, date-based tags

6. **should rust image include common cargo plugins?**
   - context: rust verification only requires basic toolchain
   - matters for: completeness of development environment
   - examples: cargo-watch, cargo-edit, cargo-audit, clippy, rustfmt
   - consideration: what makes this a "s-tier development environment" for rust

7. **foreman vs other process managers?**
   - context: foreman specified but alternatives exist (overmind, hivemind)
   - matters for: rails development workflow compatibility
   - consideration: verify foreman is still the rails community standard

8. **dockerfile location structure?**
   - context: unclear where these dockerfiles live relative to base
   - matters for: build context and ci/cd workflow
   - options: `/deno/Dockerfile`, `/Dockerfile.deno`, separate repos

9. **dependency on base image - tag or digest?**
   - context: FROM line should reference base image
   - matters for: reproducibility and security
   - options: `FROM base:latest`, `FROM base:1.0`, `FROM base@sha256:...`

10. **installation verification in dockerfile vs external tests?**
    - context: verification criteria defined but implementation unclear
    - matters for: build-time validation vs runtime testing
    - options: RUN commands in dockerfile, separate test suite, both

## suggested issues

### issue: implement deno child image (test case)

**acceptance criteria:**
- [ ] dockerfile created that inherits from base image
- [ ] image builds successfully using base image as parent
- [ ] deno executable available and functional in resulting image
- [ ] all base image tools and dotfiles accessible
- [ ] image tagged and published to ghcr.io
- [ ] build time is reasonable (leverages layer caching)
- [ ] documentation added for building/using the image

### issue: implement rust child image

**acceptance criteria:**
- [ ] dockerfile created that inherits from base image
- [ ] rust toolchain installed (rustc, cargo)
- [ ] cargo-dist installed and available
- [ ] image builds successfully
- [ ] verification test passes: can run `cargo new hello && cd hello && cargo run` outputting "Hello, world!"
- [ ] image tagged and published to ghcr.io
- [ ] rust version documented (stable channel assumed)
- [ ] build process optimized for layer caching

### issue: implement ruby on rails child image

**acceptance criteria:**
- [ ] dockerfile created that inherits from base image
- [ ] rbenv installed and configured
- [ ] current stable ruby version installed via rbenv (version specified)
- [ ] rubyfmt installed and available
- [ ] foreman installed and available
- [ ] rails gem installed
- [ ] image builds successfully
- [ ] verification test passes: can run `rails new testapp` successfully
- [ ] image tagged and published to ghcr.io
- [ ] decision documented: ruby lsp included or excluded (with rationale)

### issue: establish child image build and release workflow

**acceptance criteria:**
- [ ] ci/cd workflow defined for building child images
- [ ] dependency relationship to base image established (how child images reference base)
- [ ] versioning strategy documented for child images
- [ ] automated builds trigger on base image updates (if desired)
- [ ] all child images can build in parallel or have defined build order
- [ ] build failures in one child image don't block others
- [ ] release process documented

### issue: document child image architecture and extension pattern

**acceptance criteria:**
- [ ] documentation explains relationship between base and child images
- [ ] dockerfile structure/location decided and documented
- [ ] guidelines for adding future child images
- [ ] best practices for layer optimization in child images
- [ ] examples of how to use each child image
- [ ] troubleshooting guide for common build issues
