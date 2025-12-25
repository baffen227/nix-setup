#!/usr/bin/env bash

# list_packages.sh
# Lists all available stow packages (hosts and global)
# Usage: ./list_packages.sh

set -e

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
STOW_DIR=$(dirname "$SCRIPT_DIR")

# Verify we're in the nix-setup repository root
if [ ! -f "$STOW_DIR/CLAUDE.md" ] || [ ! -d "$STOW_DIR/global" ]; then
    echo "ERROR: Unable to locate nix-setup repository root"
    echo "Expected repository root: $STOW_DIR"
    exit 1
fi

echo "Available stow packages in $STOW_DIR:"
echo ""

# List host-specific packages
echo "Host-specific packages:"
for dir in "$STOW_DIR"/*/; do
    basename=$(basename "$dir")
    # Skip global directory and hidden directories
    if [ "$basename" != "global" ] && [[ ! "$basename" =~ ^\. ]]; then
        # Check if it has NixOS config
        if [ -d "$dir/etc/nixos" ]; then
            echo "  - $basename (NixOS host configuration)"
        else
            echo "  - $basename"
        fi
    fi
done

# List global package
echo ""
echo "Shared packages:"
if [ -d "$STOW_DIR/global" ]; then
    echo "  - global (shared dotfiles across all hosts)"
    # Show what's inside global
    if [ -d "$STOW_DIR/global/home" ]; then
        user_dirs=$(ls -1 "$STOW_DIR/global/home" 2>/dev/null || echo "")
        if [ -n "$user_dirs" ]; then
            echo "    Users: $user_dirs"
        fi
    fi
fi

echo ""
echo "Current hostname: $(hostname)"
