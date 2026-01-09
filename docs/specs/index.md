# project: cracked

## overview

a github repo containing dockerfiles for a personal s-tier development environment. includes a base image with preferred tools, dotfiles baked in via stow, and derivative images for common development stacks (deno, rust, ruby on rails).

## status

specification complete - 24 issues ready for implementation

## key decisions

- **base os**: debian/ubuntu
- **architectures**: amd64 + arm64 (multi-arch)
- **image naming**: variant tags (`ghcr.io/schpet/cracked:base`, `:deno`, `:rust`, `:rails`)
- **container user**: root
- **tools directory**: ~/tools
- **dotfiles**: run `install.sh` from dotfiles repo
- **jj verification**: email = `code@schpet.com`
- **ruby**: latest stable + ruby-lsp included
- **rust**: clippy, rustfmt, cargo-watch, cargo-edit included
- **onboarding**: markdown checklist

## features

- [base-image](./base-image.md) - core dockerfile with all development tools
- [deno-tools](./deno-tools.md) - clone and install deno projects from github
- [dotfiles](./dotfiles.md) - install dotfiles via install.sh script
- [child-images](./child-images.md) - derivative images for deno, rust, rails
- [build-ci](./build-ci.md) - local build scripts and github actions
- [onboarding](./onboarding.md) - markdown checklist for setup

## documents

- [questions](./_questions.md) - all 14 questions resolved
- [issues](./_issues.md) - 24 issues across 6 implementation phases

## notes

- readme should be lowercase/casual tone
- container registry: github container registry (ghcr.io)
- reference workflow: schpet/easy-bead-oven container.yml
