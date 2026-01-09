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

When pushing changes, advance the `main` bookmark:

```bash
jj bookmark set main -r @
jj git push
```
