# onboarding

## summary

This feature provides new users with environment setup guidance for the "cracked" development environment. It involves authenticating with GitHub (via `gh` CLI) and Claude Code, with a fallback to manual checklist instructions if automation proves infeasible. Additionally, a casual-toned README should be created to explain the repository's purpose as a personal collection of Dockerfiles with baked-in dotfiles.

## key requirements

- **Authentication Setup**: Guide users through authenticating two tools:
  - GitHub CLI (`gh`) for GitHub interactions
  - Claude Code CLI for AI-assisted development

- **Scriptability Constraint**: Both authentication flows should be scripted if possible; otherwise, provide a markdown checklist for manual completion

- **README Documentation**: Create a `readme.md` (lowercase) with casual tone containing:
  - Description: GitHub repo with personal dev environment Dockerfiles
  - Context: Contains user's dotfiles baked in
  - Audience disclaimer: Published primarily for the owner's use, shared as reference

- **User Experience**: The onboarding should be approachable and guide users step-by-step through environment setup

## ambiguities/questions

1. **Script vs. Checklist Decision Criteria**
   - *Why it matters*: The user is uncertain about scriptability. We need to determine:
     - Should we attempt automated script first and fallback to checklist?
     - Or go directly to checklist approach?
     - What level of interactivity is acceptable in the script (e.g., prompting for tokens)?

2. **Authentication Token Management**
   - *Why it matters*: Both tools support token-based authentication:
     - `gh` supports `--with-token` flag and `GH_TOKEN` environment variable
     - Should the script prompt users to provide tokens interactively?
     - Should it guide users to create tokens first?
     - How should tokens be stored securely?

3. **Interactive vs. Headless Authentication**
   - *Why it matters*:
     - `gh auth login` defaults to web-based browser flow (interactive)
     - `gh` can use environment variables for headless auth
     - Claude Code login mechanism is unclear from help output
     - Need to determine if Docker context can support browser-based flows

4. **Onboarding Script Location and Naming**
   - *Why it matters*:
     - Where should the script live in the repo? (root? `/scripts`? `/bin`?)
     - What should it be named? (`setup.sh`? `onboard.sh`? `bootstrap.sh`?)
     - Should it be executable by default?

5. **Markdown Checklist Scope**
   - *Why it matters*:
     - If providing a checklist, should it include:
       - Prerequisites (e.g., installing `gh` and `claude` if not present)?
       - Links to documentation for manual authentication?
       - Verification steps to confirm successful auth?
     - Should there be separate checklists for different operating systems?

6. **README Content Depth**
   - *Why it matters*:
     - Should the README include:
       - Build instructions?
       - Usage examples?
       - List of available images?
       - Prerequisites/dependencies?
     - Or should it be minimal and point to documentation elsewhere?

7. **Claude Code Authentication Process**
   - *Why it matters*:
     - The `claude --help` output doesn't show explicit `auth` or `login` commands
     - Need to understand:
       - How does a user authenticate Claude Code for the first time?
       - Is it API key-based, OAuth-based, or something else?
       - Can it be automated or does it require manual intervention?

8. **Error Handling and Verification**
   - *Why it matters*:
     - How should the onboarding process verify successful authentication?
     - Should it check `gh auth status` and equivalent for Claude?
     - What error messages should be shown for common failure scenarios?

9. **Docker Context Considerations**
   - *Why it matters*:
     - Will users run this onboarding inside a Docker container or on host?
     - If inside container, does auth state persist across container rebuilds?
     - Should credentials be mounted from host or configured per-container?

## suggested issues

### Issue 1: Investigate CLI Authentication Capabilities

**Title**: Research `gh` and `claude` CLI authentication scriptability

**Acceptance Criteria**:
- [ ] Document `gh auth login` options and determine if fully scriptable
- [ ] Test `gh auth login --with-token` with token via stdin
- [ ] Test `gh` authentication via `GH_TOKEN` environment variable
- [ ] Identify how Claude Code CLI handles authentication (API keys, OAuth, etc.)
- [ ] Document whether Claude authentication can be scripted
- [ ] Create decision matrix: script vs. checklist for each tool
- [ ] Document findings in `docs/specs/onboarding.md` or separate technical doc

### Issue 2: Create Onboarding Script or Checklist

**Title**: Implement environment setup onboarding flow

**Acceptance Criteria**:
- [ ] Create onboarding script (if authentication is scriptable) that:
  - [ ] Prompts user for necessary credentials/tokens
  - [ ] Authenticates with GitHub CLI
  - [ ] Authenticates with Claude Code
  - [ ] Verifies successful authentication for both tools
  - [ ] Provides clear error messages on failure
- [ ] OR create markdown checklist (if not scriptable) that:
  - [ ] Lists step-by-step manual authentication instructions
  - [ ] Includes links to relevant documentation
  - [ ] Provides verification commands to confirm success
  - [ ] Notes prerequisites (installing CLIs if needed)
- [ ] Place deliverable in appropriate location (determine in Issue 1)
- [ ] Ensure script is executable (if applicable)
- [ ] Test onboarding flow on clean environment

### Issue 3: Create Casual README

**Title**: Write lowercase casual-toned README for repository

**Acceptance Criteria**:
- [ ] Create `readme.md` (lowercase filename)
- [ ] Use casual, approachable tone throughout
- [ ] Include description: "github repo that has a collection of dockerfiles that i use for dev"
- [ ] Mention dotfiles are baked in via stow
- [ ] Add disclaimer: "useful for me and just published for reference"
- [ ] Keep content minimal but informative
- [ ] Optionally include link to onboarding script/checklist
- [ ] Review for tone consistency with project style

### Issue 4: Document Onboarding Prerequisites

**Title**: Create prerequisite documentation for onboarding

**Acceptance Criteria**:
- [ ] List required tools (`gh`, `claude`, `docker`, etc.)
- [ ] Provide installation instructions or links for each tool
- [ ] Document supported operating systems (if applicable)
- [ ] Note any minimum version requirements
- [ ] Include in README or separate SETUP.md (decide on location)
- [ ] Ensure prerequisites are clear before user starts onboarding

### Issue 5: Add Authentication Verification

**Title**: Implement auth verification in onboarding process

**Acceptance Criteria**:
- [ ] Add `gh auth status` check to verify GitHub authentication
- [ ] Identify equivalent verification command for Claude Code
- [ ] Display clear success/failure messages
- [ ] If script: exit with appropriate status codes
- [ ] If checklist: provide verification commands for user to run
- [ ] Include troubleshooting hints for common failures
