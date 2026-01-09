# feature: deno-tools

## summary

This feature establishes a 'tools' directory containing cloned deno projects (gogreen and easy-bead-oven) that are installed via deno and available on the $PATH. The tools are cloned from GitHub rather than installed directly from JSR to enable easy updates and local modifications. The feature must support both bash and fish shells, with fish being the primary shell environment.

## key requirements

- Create a 'tools' directory in the container/repository
- Use gh (GitHub CLI) to clone schpet/gogreen and schpet/easy-bead-oven
- Evaluate both projects for suitability and dependencies
- Install both tools using deno install commands
- Verify tools are accessible on $PATH in bash
- Verify tools are accessible on $PATH in fish (primary shell)
- Tools must remain cloneable/updateable (not just installed from JSR)

## tool details

### gogreen
- Purpose: Runs claude code in a loop to fix GitHub CI status checks
- Installation: `just install` (requires just command runner)
- Dependencies: Deno, Just
- Language: TypeScript (99.6%)

### easy-bead-oven
- Purpose: Orchestrator that runs claude code in a loop, polling for beads issues
- Installation: `deno install -A -g -f -n ebo jsr:@schpet/easy-bead-oven`
- Dependencies: Deno, Claude Code CLI, Beads
- Language: TypeScript
- Status: Experimental, early development
- Container: Available at ghcr.io/schpet/ebo-agent:latest

## ambiguities/questions

1. **Where should the tools directory live?**
   - Should it be at the root of the repo?
   - Should it be in a specific subdirectory like /opt/tools or ~/tools?
   - Does the location matter for Docker layers/caching?
   - Context: This affects Dockerfile structure, PATH configuration, and rebuild performance

2. **Which installation method for gogreen?**
   - Should we use `just install` as documented?
   - Should we use `deno install` directly?
   - Do we need to install 'just' as a dependency?
   - Context: gogreen's README shows `just install` but the requirement to clone suggests we need the source-based approach

3. **How should PATH be configured for both shells?**
   - Should deno's bin directory be added to PATH in shell rc files?
   - Should it be configured in the Dockerfile ENV?
   - Do we need separate configuration for bash and fish?
   - Context: Deno typically installs to ~/.deno/bin, but Docker may need different conventions

4. **What does "evaluate them" mean specifically?**
   - Should we verify they compile/run without errors?
   - Should we run their test suites?
   - Should we check for security issues?
   - Should we verify all dependencies are available?
   - Context: This determines what verification steps are needed in the Dockerfile or setup scripts

5. **Update mechanism expectations?**
   - Should there be a script to update tools?
   - Should updates happen at container build time or runtime?
   - Should we use git pull or gh repo sync?
   - Context: Affects whether we need update automation and how frequently tools are refreshed

6. **Should easy-bead-oven dependencies be installed?**
   - Claude Code CLI is listed as a dependency - should this be pre-installed?
   - Beads is required - should this also be installed in this feature?
   - Or are these assumed to be in base-image?
   - Context: Determines scope of this feature vs base-image feature

7. **Version pinning strategy?**
   - Should tools be pinned to specific commits/tags?
   - Should they track main/latest?
   - How do we handle breaking changes?
   - Context: Affects stability vs freshness tradeoff

8. **Installation flags for deno install?**
   - easy-bead-oven uses `-A -g -f -n ebo` flags
   - Should gogreen use similar flags?
   - What about the `-f` (force) flag for rebuilds?
   - Context: Determines installation behavior and upgrade path

9. **Fish shell PATH configuration specifics?**
   - Should we use fish_add_path?
   - Should we modify config.fish?
   - Should we use universal variables?
   - Context: Fish has different PATH handling than bash, affects reliability

10. **Testing/verification in CI?**
    - Should the build-ci feature test these tools?
    - What constitutes a passing test (--version, --help, actual execution)?
    - Context: Determines integration with build-ci feature

## suggested issues

### Issue 1: Set up tools directory structure
**Acceptance Criteria:**
- [ ] Create tools directory at agreed-upon location
- [ ] Document tools directory purpose in README
- [ ] Ensure directory is created in Dockerfile at appropriate layer
- [ ] Directory permissions allow tool installation

### Issue 2: Clone deno tools from GitHub
**Acceptance Criteria:**
- [ ] gh CLI is available in the container
- [ ] gogreen repository is cloned to tools/gogreen
- [ ] easy-bead-oven repository is cloned to tools/easy-bead-oven
- [ ] Both repositories clone successfully during container build
- [ ] .git directories are preserved for update capability

### Issue 3: Install gogreen with deno
**Acceptance Criteria:**
- [ ] Determine correct installation method (just install vs deno install)
- [ ] Install any required dependencies (e.g., just if needed)
- [ ] gogreen binary is installed successfully
- [ ] Installation completes without errors during container build
- [ ] gogreen command is available after installation

### Issue 4: Install easy-bead-oven with deno
**Acceptance Criteria:**
- [ ] Run `deno install -A -g -f -n ebo jsr:@schpet/easy-bead-oven` or appropriate variant
- [ ] ebo binary is installed successfully
- [ ] Installation completes without errors during container build
- [ ] ebo command is available after installation
- [ ] Verify required dependencies (claude, beads) are available or documented

### Issue 5: Configure PATH for bash
**Acceptance Criteria:**
- [ ] Deno bin directory is added to PATH in bash environment
- [ ] gogreen command is executable in bash shell
- [ ] ebo command is executable in bash shell
- [ ] PATH configuration persists across shell sessions
- [ ] Verify with `which gogreen` and `which ebo` in bash

### Issue 6: Configure PATH for fish shell
**Acceptance Criteria:**
- [ ] Deno bin directory is added to PATH in fish environment
- [ ] gogreen command is executable in fish shell
- [ ] ebo command is executable in fish shell
- [ ] PATH configuration persists across shell sessions
- [ ] Verify with `which gogreen` and `which ebo` in fish
- [ ] Use fish-appropriate PATH configuration (fish_add_path or config.fish)

### Issue 7: Verify tool functionality
**Acceptance Criteria:**
- [ ] Define what "evaluate" means for each tool
- [ ] gogreen passes evaluation checks (compilation, basic execution, etc.)
- [ ] ebo passes evaluation checks (compilation, basic execution, etc.)
- [ ] Document any known limitations or requirements
- [ ] Both tools can display help or version information

### Issue 8: Create tool update mechanism
**Acceptance Criteria:**
- [ ] Document how to update tools (git pull in tools directory)
- [ ] Consider creating update script if needed
- [ ] Verify update process works for both tools
- [ ] Document update process in README or tool documentation

### Issue 9: Document deno-tools feature
**Acceptance Criteria:**
- [ ] Add section to README explaining installed tools
- [ ] Document what gogreen and ebo do
- [ ] Explain why tools are cloned vs installed from JSR
- [ ] Document how to update tools
- [ ] Include troubleshooting for PATH issues
