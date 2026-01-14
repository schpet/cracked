# cracked

dev environment setup script and container images.

## quick start

```bash
curl -fsSL https://raw.githubusercontent.com/schpet/cracked/main/setup.sh | bash
```

this installs my preferred cli tools (fish, jj, ripgrep, fzf, starship, eza, etc) plus claude code and dotfiles on any linux machine.

## setup script options

```bash
# install base tools
curl -fsSL https://raw.githubusercontent.com/schpet/cracked/main/setup.sh | bash

# install base + specific environment
curl -fsSL https://raw.githubusercontent.com/schpet/cracked/main/setup.sh | bash -s -- --deno
curl -fsSL https://raw.githubusercontent.com/schpet/cracked/main/setup.sh | bash -s -- --rust
curl -fsSL https://raw.githubusercontent.com/schpet/cracked/main/setup.sh | bash -s -- --rails
curl -fsSL https://raw.githubusercontent.com/schpet/cracked/main/setup.sh | bash -s -- --rails --ruby-version 3.4.1
curl -fsSL https://raw.githubusercontent.com/schpet/cracked/main/setup.sh | bash -s -- --all

# update installed tools to latest versions
curl -fsSL https://raw.githubusercontent.com/schpet/cracked/main/setup.sh | bash -s -- --update
```

the script:
- installs system packages via apt (requires sudo)
- downloads CLI tools from github releases (eza, jj, just, gh, delta, sd, starship, etc)
- installs claude code cli via npm
- sets up dotfiles via stow
- handles architecture detection (x86_64/aarch64)
- skips already-installed tools unless --update is passed

## images

available on github container registry:

```
ghcr.io/schpet/cracked:base    # core tools and dotfiles
ghcr.io/schpet/cracked:deno    # + deno runtime
ghcr.io/schpet/cracked:rust    # + rust toolchain
ghcr.io/schpet/cracked:rails   # + ruby/rails environment
```

## exe.dev

create a new machine with the latest tag:

```bash
ssh exe.dev new --image "ghcr.io/schpet/cracked:$(gh api repos/schpet/cracked/tags --jq '.[0].name')" --json
```

## building locally

build the base image:

```bash
docker build -t cracked:base .
```

build a child image (e.g., rust):

```bash
docker build -t cracked:rust -f Dockerfile.rust .
```

build for a specific platform:

```bash
docker build --platform linux/amd64 -t cracked:base .
docker build --platform linux/arm64 -t cracked:base .
```

run the image:

```bash
docker run -it cracked:base
```

## production builds

images are built and pushed to ghcr.io via github actions.

### triggers

- **tag push**: push a tag matching `container-v*` (e.g., `container-v1.0.0`)
- **manual**: trigger workflow_dispatch from the actions tab

### creating a release

```bash
# tag and push to trigger build
jj bookmark set main -r @
jj git push
git tag container-v1.0.0
git push origin container-v1.0.0
```

or using gh cli:

```bash
gh workflow run container.yml
```

### what happens

1. workflow checks out the code
2. sets up qemu for multi-arch support
3. configures docker buildx
4. authenticates to github container registry
5. builds images for linux/amd64 and linux/arm64
6. pushes to ghcr.io with version tag and `latest`

## tagging strategy

- **version tags**: created from git tags (e.g., `container-v1.2.3` → image tagged as `1.2.3`)
- **latest**: updated on every build
- **variant tags**: each image type has its own tag (`:base`, `:deno`, `:rust`, `:rails`)

example: pushing `container-v1.2.3` creates:
- `ghcr.io/schpet/cracked:base` (latest)
- `ghcr.io/schpet/cracked:1.2.3`

## verifying builds

check if images were published:

```bash
# list available tags
gh api repos/schpet/cracked/packages/container/cracked/versions \
  --jq '.[].metadata.container.tags[]'

# pull and verify
docker pull ghcr.io/schpet/cracked:base
docker run ghcr.io/schpet/cracked:base fish -c "echo 'it works'"
```

check workflow status:

```bash
gh run list --workflow=container.yml
gh run view <run-id>
```

## troubleshooting

### build fails locally

```bash
# ensure docker daemon is running
docker info

# try with no cache
docker build --no-cache -t cracked:base .

# check disk space
docker system df
```

### multi-arch build issues

```bash
# create buildx builder if not exists
docker buildx create --name multiarch --driver docker-container --use

# verify platforms available
docker buildx inspect --bootstrap
```

### authentication errors on push

```bash
# login to ghcr
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# verify permissions (needs packages:write)
gh auth status
```

### workflow not triggering

- verify tag matches pattern `container-v*`
- check actions are enabled for the repo
- ensure workflow file exists at `.github/workflows/container.yml`

### image not found after push

- wait a few minutes for registry propagation
- check workflow completed successfully: `gh run list`
- verify package visibility settings in repo settings
