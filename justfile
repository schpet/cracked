# Container build recipes for cracked images
# Usage: just build [variant]

# Default registry and image name
registry := "ghcr.io/schpet"
image := "cracked"

# Available variants (base must be built first for others)
# base: Core tools and dotfiles
# deno: + Deno runtime
# rust: + Rust toolchain
# rails: + Ruby/Rails environment

# Build a container image
# Usage: just build [variant]
# Examples:
#   just build        # builds base
#   just build base   # builds base
#   just build rust   # builds rust variant
build variant="base":
    #!/usr/bin/env bash
    set -euo pipefail

    variant="{{variant}}"
    valid_variants="base deno rust rails"

    # Validate variant
    if ! echo "$valid_variants" | grep -qw "$variant"; then
        echo "Error: Invalid variant '$variant'"
        echo "Valid variants: $valid_variants"
        exit 1
    fi

    # Determine dockerfile
    if [ "$variant" = "base" ]; then
        dockerfile="Dockerfile"
    else
        dockerfile="Dockerfile.$variant"
    fi

    # Check dockerfile exists
    if [ ! -f "$dockerfile" ]; then
        echo "Error: Dockerfile not found: $dockerfile"
        echo "Hint: Child image dockerfiles should be named Dockerfile.<variant>"
        exit 1
    fi

    tag="{{image}}:$variant"
    echo "Building $tag from $dockerfile..."
    echo ""

    # Build the image
    if ! docker build -t "$tag" -f "$dockerfile" .; then
        echo ""
        echo "Error: Build failed for $tag"
        exit 1
    fi

    echo ""
    echo "Build successful!"
    echo ""

    # Output image details
    image_id=$(docker images --no-trunc -q "$tag" | head -1)
    image_size=$(docker images --format "{{{{.Size}}" "$tag" | head -1)

    echo "Image: $tag"
    echo "ID: $image_id"
    echo "Size: $image_size"

# Build all available images
build-all:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Building all available images..."
    echo ""

    # Always build base first
    just build base

    # Build child images if their dockerfiles exist
    for variant in deno rust rails; do
        dockerfile="Dockerfile.$variant"
        if [ -f "$dockerfile" ]; then
            echo ""
            echo "----------------------------------------"
            echo ""
            just build "$variant"
        else
            echo ""
            echo "Skipping $variant (no $dockerfile found)"
        fi
    done

    echo ""
    echo "========================================"
    echo "All builds complete!"
    echo ""
    just list

# List built images
list:
    @docker images "{{image}}" --format "table {{{{.Repository}}:{{{{.Tag}}\t{{{{.ID}}\t{{{{.Size}}\t{{{{.CreatedSince}}"

# Build for a specific platform
build-platform variant="base" platform="linux/amd64":
    #!/usr/bin/env bash
    set -euo pipefail

    variant="{{variant}}"
    platform="{{platform}}"

    # Determine dockerfile
    if [ "$variant" = "base" ]; then
        dockerfile="Dockerfile"
    else
        dockerfile="Dockerfile.$variant"
    fi

    # Check dockerfile exists
    if [ ! -f "$dockerfile" ]; then
        echo "Error: Dockerfile not found: $dockerfile"
        exit 1
    fi

    tag="{{image}}:$variant"
    echo "Building $tag for $platform..."

    docker build --platform "$platform" -t "$tag" -f "$dockerfile" .

    echo ""
    echo "Build successful!"
    image_id=$(docker images --no-trunc -q "$tag" | head -1)
    image_size=$(docker images --format "{{{{.Size}}" "$tag" | head -1)
    echo "Image: $tag"
    echo "ID: $image_id"
    echo "Size: $image_size"

# Remove built images
clean:
    @echo "Removing {{image}} images..."
    -docker rmi $(docker images "{{image}}" -q) 2>/dev/null || true
    @echo "Done"

# Show available recipes
help:
    @just --list
