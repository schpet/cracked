# feature: dotfiles

## summary

Install and configure dotfiles from the schpet/dotfiles GitHub repository using GNU Stow during Docker image build. The feature must ensure symlinks are properly created in the home directory and that configuration files are applied for all relevant tools, with jj (Jujutsu) configuration serving as the primary verification point where user details must be correctly set as the author.

## key requirements

- Clone schpet/dotfiles repository from GitHub during Docker build
- Install GNU Stow package in the base image
- Execute stow to create symlinks from dotfiles to appropriate home directory locations
- Verify jj configuration is applied with correct user.name and user.email as author
- Handle dotfile directory structure that follows stow conventions (packages as subdirectories)
- Ensure dotfiles are applied for the correct user context within the container
- Dotfiles must be baked into the image (not mounted at runtime)

## ambiguities/questions

1. **What is the exact GitHub URL for schpet/dotfiles?**
   - Matters for: Determining if it's public/private, selecting appropriate git clone method, understanding access requirements
   - Web search did not locate a public schpet/dotfiles repository

2. **Which packages from the dotfiles repo should be stowed?**
   - Matters for: Whether to stow all packages or selectively stow specific ones (e.g., `stow jj vim zsh` vs `stow *`)
   - Different packages may have different priority levels or dependencies

3. **What are the specific jj user configuration values to verify?**
   - Matters for: Defining concrete acceptance criteria for verification
   - Need actual user.name and user.email values that should be configured
   - Example: "user.name = 'schpet'" or different name/email?

4. **Should dotfiles installation happen in the base image or child images?**
   - Matters for: Image layer optimization, whether child images might need different dotfiles
   - Current spec suggests base image, but worth confirming

5. **What happens if stow encounters conflicts?**
   - Matters for: Error handling strategy, whether to override existing files or fail the build
   - Need to decide on stow flags: `--adopt`, `--override`, or strict conflict detection

6. **Are there other tools besides jj that require verification?**
   - Matters for: Comprehensive testing strategy, identifying all critical configurations
   - Verification mentions "e.g. jj" suggesting there may be others

7. **Should the dotfiles repository be cloned at a specific commit/tag/branch?**
   - Matters for: Build reproducibility, stability vs getting latest configurations
   - Using a pinned version provides consistent builds

8. **What is the target directory structure inside the container?**
   - Matters for: Determining the stow target directory (`-t` flag)
   - Typically `~/` but container might use different home directory location
   - Need to confirm the user and home directory in the container (root vs non-root user)

9. **Should the .git directory from dotfiles be retained or removed?**
   - Matters for: Image size optimization, whether to track dotfile changes inside container
   - Stow ignores .git by default, but the cloned repo contains it

10. **Are there any dotfiles that should NOT be stowed in the Docker environment?**
    - Matters for: Container-specific configurations that differ from local machine setup
    - Some local machine configs might be inappropriate for containers (e.g., display settings, SSH agent forwarding)

## suggested issues

### issue: install gnu stow package
**acceptance criteria:**
- GNU Stow is installed in the base image
- Stow version can be queried successfully (`stow --version`)
- Stow is available on PATH for subsequent build steps
- Installation uses appropriate package manager for the base image OS

### issue: clone schpet/dotfiles repository
**acceptance criteria:**
- Repository is cloned to a known location during image build
- Clone succeeds without requiring authentication (or auth mechanism is documented)
- Clone location is accessible to subsequent build steps
- Repository contents are present and not corrupted

### issue: apply dotfiles with stow
**acceptance criteria:**
- Stow command executes successfully during image build
- No stow conflicts cause build failure
- Symlinks are created in the expected home directory locations
- Stow output is logged for debugging purposes
- Appropriate stow flags are used based on conflict resolution strategy

### issue: verify jj configuration
**acceptance criteria:**
- `~/.config/jj/config.toml` (or `~/.jjconfig.toml`) exists
- File contains `[user]` section with `name` field
- File contains `[user]` section with `email` field
- Values match expected author details from schpet/dotfiles
- Configuration can be verified with `jj config list --user` or equivalent
- Running `jj config get user.name` and `jj config get user.email` returns expected values

### issue: document dotfiles installation process
**acceptance criteria:**
- README documents that dotfiles are included in the image
- Source repository (schpet/dotfiles) is referenced
- Stow usage is briefly explained
- Instructions for modifying or rebuilding with different dotfiles
- List of key tools configured via dotfiles

### issue: handle dotfiles build failures gracefully
**acceptance criteria:**
- Build fails fast if dotfiles repository cannot be cloned
- Build fails fast if stow encounters unresolvable conflicts
- Error messages clearly indicate the failure point
- Logs provide actionable information for debugging
- Consider fallback behavior if dotfiles are optional

## implementation considerations

### stow basics
- Stow creates symlinks from a source directory (stow package) to a target directory
- Default target is parent directory of the stow directory
- Package structure must mirror desired target structure
- Example: `dotfiles/jj/.config/jj/config.toml` stows to `~/.config/jj/config.toml`

### docker build context
- Dotfiles should be installed during `docker build`, not at runtime
- Layer ordering matters for cache efficiency (install stow early, clone/stow later if dotfiles change frequently)
- Consider multi-stage builds if dotfiles repo should not be in final image

### verification strategy
- Verification should happen in the Dockerfile (RUN step after stow)
- Simple file existence checks: `test -f ~/.config/jj/config.toml`
- Content validation: `grep -q "name =" ~/.config/jj/config.toml`
- Functional validation: `jj config get user.name` (requires jj to be installed first)

### user context
- Ensure stow runs as the correct user (the one who will use the dotfiles)
- Home directory must exist before stowing
- File permissions should allow the target user to read/write configs

### stow flags to consider
- `stow -v` for verbose output during build
- `stow -n` for dry-run testing (separate verification step)
- `stow --adopt` to adopt existing files if conflicts occur
- `stow -t <target>` to specify non-default target directory
- `stow --ignore=<pattern>` to skip certain files

## references

- [Using GNU Stow to manage dotfiles](https://gist.github.com/andreibosco/cb8506780d0942a712fc)
- [Managing Dotfiles with GNU Stow](https://medium.com/quick-programming/managing-dotfiles-with-gnu-stow-9b04c155ebad)
- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html)
- [Jujutsu Config Documentation](https://docs.jj-vcs.dev/latest/config/)
- [Configuring Jujutsu](https://oppi.li/posts/configuring_jujutsu/)
- [Dotfiles with Docker and Stow](https://github.com/math0ne/dotfiles)
