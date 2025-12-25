#!/usr/bin/env bash

# rebuild_nixos.sh
# Complete NixOS configuration deployment workflow
# Usage: ./rebuild_nixos.sh [hostname] [test|switch|boot] [--skip-stow] [--skip-git-check] [--force]
# Example: ./rebuild_nixos.sh crazy-diamond switch
# Example: ./rebuild_nixos.sh $(hostname) test --skip-stow
# Example: ./rebuild_nixos.sh crazy-diamond switch --force

set -e

HOSTNAME=${1:-$(hostname)}
MODE=${2:-test}
SKIP_STOW=false
SKIP_GIT_CHECK=false
FORCE=false
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
STOW_DIR=$(dirname "$SCRIPT_DIR")

# Parse flags
for arg in "$@"; do
    if [ "$arg" = "--skip-stow" ]; then
        SKIP_STOW=true
    elif [ "$arg" = "--skip-git-check" ]; then
        SKIP_GIT_CHECK=true
    elif [ "$arg" = "--force" ]; then
        FORCE=true
    fi
done

# Validate mode
if [[ ! "$MODE" =~ ^(test|switch|boot|dry-build)$ ]]; then
    echo "ERROR: Invalid mode '$MODE'"
    echo "Valid modes: test, switch, boot, dry-build"
    exit 1
fi

# Check if hostname package exists
if [ ! -d "$STOW_DIR/$HOSTNAME" ]; then
    echo "ERROR: Configuration for host '$HOSTNAME' not found"
    echo "Available hosts:"
    ls -d "$STOW_DIR"/*/ 2>/dev/null | grep -v global | xargs -n 1 basename || echo "  (none found)"
    exit 1
fi

# Git dirty check (unless skipped)
if [ "$SKIP_GIT_CHECK" = false ]; then
    cd "$STOW_DIR"
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo ""
        echo -e "\033[0;33m=== WARNING: Uncommitted changes detected ===\033[0m"
        echo ""
        echo "The following files have uncommitted changes:"
        git status --short
        echo ""
        echo "Consider committing changes before rebuilding for better version control."
        echo "This ensures the system state corresponds to a specific commit."
        echo ""
        echo "To suppress this warning: use --skip-git-check flag"
        echo ""

        if [ "$FORCE" = false ]; then
            read -p "Continue anyway? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Aborted by user."
                exit 1
            fi
        else
            echo "(Continuing due to --force flag)"
        fi
        echo ""
    fi
fi

# Step 1: Apply global configuration (unless skipped)
if [ "$SKIP_STOW" = false ]; then
    echo "=== Step 1/4: Applying global configuration ==="
    if ! "$SCRIPT_DIR/apply_stow.sh" "global"; then
        echo ""
        echo -e "\033[0;31mGlobal stow deployment failed. Aborting.\033[0m"
        exit 1
    fi
    echo ""
else
    echo "=== Skipping global stow deployment (--skip-stow flag provided) ==="
fi

# Step 2: Apply host-specific configuration (unless skipped)
if [ "$SKIP_STOW" = false ]; then
    echo "=== Step 2/4: Applying host-specific configuration for $HOSTNAME ==="
    if ! "$SCRIPT_DIR/apply_stow.sh" "$HOSTNAME"; then
        echo ""
        echo -e "\033[0;31mHost stow deployment failed. Aborting.\033[0m"
        exit 1
    fi
else
    echo "=== Skipping host stow deployment (--skip-stow flag provided) ==="
fi

# Step 3: Validate NixOS configuration
echo ""
echo "=== Step 3/4: Validating NixOS configuration ==="
if ! sudo nixos-rebuild dry-build; then
    echo ""
    echo -e "\033[0;31mNixOS configuration validation failed.\033[0m"
    echo "Please fix the errors in /etc/nixos/configuration.nix"
    exit 1
fi

# Step 4: Apply NixOS configuration
echo ""
echo "=== Step 4/4: Rebuilding NixOS (mode: $MODE) ==="
case $MODE in
    test)
        echo "Note: This will temporarily apply changes (reverts on reboot)"
        sudo nixos-rebuild test
        ;;
    switch)
        echo "Note: This will permanently apply changes and switch to new generation"
        sudo nixos-rebuild switch
        ;;
    boot)
        echo "Note: Changes will apply on next boot"
        sudo nixos-rebuild boot
        ;;
    dry-build)
        echo "Dry-build only (no changes applied)"
        sudo nixos-rebuild dry-build
        ;;
esac

echo ""
echo -e "\033[0;32mNixOS rebuild completed successfully!\033[0m"
echo "Mode: $MODE"
echo "Host: $HOSTNAME"
