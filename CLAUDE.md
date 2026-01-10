# Project Instructions

## Specifications

Project specs are in [docs/specs/](docs/specs/):

- [docs/specs/index.md](docs/specs/index.md) - Specification overview
- [docs/specs/base-image.md](docs/specs/base-image.md) - Base image spec
- [docs/specs/child-images.md](docs/specs/child-images.md) - Child images spec
- [docs/specs/build-ci.md](docs/specs/build-ci.md) - Build and CI spec
- [docs/specs/deno-tools.md](docs/specs/deno-tools.md) - Deno tools spec
- [docs/specs/dotfiles.md](docs/specs/dotfiles.md) - Dotfiles spec
- [docs/specs/onboarding.md](docs/specs/onboarding.md) - Onboarding spec

## Version Control

This project uses **jj** (Jujutsu) for version control, not git directly. Use the `/jj` skill to learn more about jj commands and workflows.

### Basic jj Commands

```bash
jj status                    # show working copy status
jj diff                      # show changes
jj describe -m "message"     # set commit message for current change
jj new                       # create a new change
jj log                       # show commit history
jj log --ignore-working-copy # faster log (skip snapshotting)
```

### Pushing Changes

Advance the `main` bookmark and push:

```bash
jj bookmark set main -r @
jj git push --bookmark main
```

### Releasing

1. Describe the change and move main:
   ```bash
   jj describe -m "Your commit message"
   jj bookmark set main -r @
   ```

2. Check the latest tag and create a new one (increment patch):
   ```bash
   jj tag list --ignore-working-copy  # see existing tags
   jj tag set v0.1.X -r @             # create new tag
   ```

3. Push bookmark and tag (jj doesn't push tags, use git):
   ```bash
   jj git push --bookmark main
   git push origin v0.1.X
   ```

4. Monitor CI:
   ```bash
   gh run list --limit 3
   gh run view <run-id> --log-failed
   ```
