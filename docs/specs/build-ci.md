# build-ci: Build & CI/CD

## summary

This feature area covers local container build tooling and automated GitHub Actions workflows for building and publishing container images to GitHub Container Registry (ghcr.io). The implementation should enable both manual local builds for development/testing and automated CI/CD pipelines triggered by version tags, mirroring the pattern used in schpet/easy-bead-oven.

## key requirements

- **Local Build Script**: Create script(s) to build container images locally using Docker or a lightweight alternative (e.g., podman, finch)
- **GitHub CLI Integration**: Use `gh` command to push changes to schpet/cracked repository
- **GitHub Actions Workflow**: Implement `.github/workflows/*.yml` to build and push containers automatically
- **Container Registry**: Publish images to GitHub Container Registry (ghcr.io)
- **Verification**: Use `gh` to verify successful container publication
- **Reference Implementation**: Follow patterns from https://github.com/schpet/easy-bead-oven/blob/main/.github/workflows/container.yml
- **Multi-architecture Support**: Based on reference, likely needs amd64 and arm64 builds
- **Tagging Strategy**: Support version tagging (e.g., container-v*) and latest tags

## ambiguities/questions

1. **Which container tool should the local build script support?**
   - Context: The requirement says "docker (or appropriate lightweight container tool)" but doesn't specify alternatives
   - Why it matters: Affects script compatibility, installation requirements, and whether to support multiple tools
   - Options: Docker only, Docker + Podman, Docker + Finch, auto-detect available tool

2. **What triggers the GitHub Actions workflow?**
   - Context: Reference workflow uses tag pattern `container-v*` and manual dispatch
   - Why it matters: Determines release process and whether builds happen on every push, PR, tag, or manual trigger
   - Options: Tags only, tags + PRs, tags + main branch pushes, manual only

3. **How many container images need to be built?**
   - Context: Project has base-image and child-images (deno, rust, rails) features
   - Why it matters: Could be one workflow with matrix builds, separate workflows, or sequential dependent builds
   - Questions: Build all images in parallel? Build base then children? Separate workflows per image?

4. **What naming convention for container images?**
   - Context: Reference uses `${{ github.repository_owner }}/ebo-agent`
   - Why it matters: Affects discoverability and organization in ghcr.io
   - Options: Single image name, separate names per variant (cracked-base, cracked-deno), tags to distinguish variants

5. **What is the relationship between build script and CI workflow?**
   - Context: Both local script and GitHub Actions need to build images
   - Why it matters: Can avoid duplication if CI calls the same script, or keep them separate for flexibility
   - Options: CI uses same script, CI has own build logic, hybrid approach

6. **Should builds include layer caching optimization?**
   - Context: Reference workflow uses GitHub Actions cache with max retention
   - Why it matters: Affects build speed and GitHub Actions storage costs
   - Default assumption: Yes, follow reference pattern

7. **What container file naming convention?**
   - Context: Reference uses `Containerfile.base`, project overview mentions "dockerfiles"
   - Why it matters: Script needs to know what to build
   - Options: Dockerfile vs Containerfile, naming pattern for multiple images

8. **What permissions/secrets need to be configured?**
   - Context: Reference needs "contents: read" and "packages: write"
   - Why it matters: Repository settings must be configured before workflow works
   - Questions: Document in onboarding? Handle in workflow setup? Assume already configured?

9. **Should the local build script support pushing to registry?**
   - Context: Not explicitly mentioned, but may be useful for manual releases
   - Why it matters: Affects script complexity and authentication requirements
   - Options: Build only, build + optional push, build + push + verify

10. **What testing/validation should happen before push?**
    - Context: Not mentioned in requirements
    - Why it matters: Affects workflow steps and issue acceptance criteria
    - Options: No testing, basic smoke tests, run test suite in container

## suggested issues

### Issue: Create local container build script

**Acceptance Criteria:**
- Script exists in repository root or scripts directory
- Script can build base container image locally
- Script accepts image name/tag as parameter
- Script works with Docker (and optionally other container tools)
- Script provides clear error messages on failure
- Script outputs image ID and size on success
- Documentation included (inline comments or README section)

### Issue: Setup GitHub Actions workflow for container builds

**Acceptance Criteria:**
- Workflow file exists at `.github/workflows/container.yml` (or similar)
- Workflow triggers on appropriate events (tags/manual/etc - TBD)
- Workflow checks out repository code
- Workflow sets up multi-architecture build support (QEMU + Buildx)
- Workflow authenticates to GitHub Container Registry
- Workflow builds container image(s)
- Workflow generates appropriate tags (version + latest)
- Workflow pushes to ghcr.io/schpet/[image-name]
- Workflow has required permissions configured (contents:read, packages:write)
- Workflow includes build caching optimization

### Issue: Implement container verification using gh CLI

**Acceptance Criteria:**
- Script or workflow step uses `gh` to verify container publication
- Verification confirms image exists in registry
- Verification checks expected tags are present
- Clear success/failure output
- Can be run manually or as part of CI
- Documents expected `gh` version or required extensions

### Issue: Document build and release process

**Acceptance Criteria:**
- README includes section on local builds
- README explains how to trigger production builds
- Document tagging strategy for releases
- Document how to verify successful publication
- Include troubleshooting section for common build issues
- Note any required repository settings or secrets

### Issue: Support building child images in CI

**Acceptance Criteria:**
- Workflow can build derivative images (deno, rust, rails)
- Build order respects dependencies (base before children)
- Each image pushed to registry with appropriate naming
- Option to build all images or specific subset
- Build matrix or sequential strategy documented

## implementation notes

### reference workflow patterns

The easy-bead-oven reference implementation provides these patterns:
- **Trigger**: Tag-based releases (`container-v*`) + manual workflow_dispatch
- **Multi-arch**: Supports both amd64 and arm64 platforms
- **Registry**: GitHub Container Registry (ghcr.io)
- **Caching**: Leverages GitHub Actions cache for faster builds
- **Metadata**: Uses docker/metadata-action for tag generation
- **Authentication**: Uses built-in GITHUB_TOKEN for registry auth

### container tool considerations

Docker is the standard but alternatives exist:
- **Podman**: Daemon-less, rootless, Docker CLI compatible
- **Finch**: AWS's open source container tool
- **Buildah**: Specialized for building OCI images

Local script could detect available tool or require explicit specification.

### potential build strategies

For multiple container images:
1. **Monolithic**: One workflow, build all images, use matrix if possible
2. **Separate**: Individual workflows per image type
3. **Dependent**: Base workflow triggers child workflows
4. **Conditional**: One workflow with path filters or manual input

### registry naming patterns

Options for ghcr.io naming:
- Single image with variant tags: `ghcr.io/schpet/cracked:base`, `ghcr.io/schpet/cracked:deno`
- Separate images: `ghcr.io/schpet/cracked-base`, `ghcr.io/schpet/cracked-deno`
- Nested: `ghcr.io/schpet/cracked/base`, `ghcr.io/schpet/cracked/deno` (may not be supported)

## dependencies

- Completion of base-image spec (determines what gets built)
- Completion of child-images spec (determines build matrix)
- Resolution of dotfiles strategy (affects what's baked into images)
- Repository permissions for packages:write

## risks

- **Build time**: Multi-arch builds can be slow, especially without caching
- **Storage costs**: GitHub Container Registry storage and GitHub Actions cache have limits
- **Authentication complexity**: Local builds need different auth than CI builds
- **Breaking changes**: Updates to Docker/Buildx/Actions can break workflows
- **Tag conflicts**: Poorly designed tagging strategy can cause confusion or overwrites
