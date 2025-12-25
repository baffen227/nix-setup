#!/usr/bin/env bash

# unstow.sh
# Safely removes stow symlinks
# Usage: ./unstow.sh <package_name> [target_dir]
# Example: ./unstow.sh crazy-diamond
# Example: ./unstow.sh global

set -e

PACKAGE=$1
TARGET=${2:-/}
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
STOW_DIR=$(dirname "$SCRIPT_DIR")

# Ignore patterns: only settings.json should be symlinked for .claude and .gemini
# Uses negative lookahead to ignore everything except settings.json
IGNORE_OPTS="--ignore='dot-claude/(?!settings\.json$).+' --ignore='dot-gemini/(?!settings\.json$).+'"

# Validate arguments
if [ -z "$PACKAGE" ]; then
    echo "Usage: $0 <package_name> [target_directory]"
    exit 1
fi

# Verify we're in the nix-setup repository root
if [ ! -f "$STOW_DIR/CLAUDE.md" ] || [ ! -d "$STOW_DIR/global" ]; then
    echo "ERROR: Unable to locate nix-setup repository root"
    echo "Expected repository root: $STOW_DIR"
    exit 1
fi

# Check if package directory exists
if [ ! -d "$STOW_DIR/$PACKAGE" ]; then
    echo "ERROR: Package '$PACKAGE' not found in $STOW_DIR"
    exit 1
fi

echo "Removing symlinks for package: '$PACKAGE' (Target: $TARGET)..."

# Run stow with -D flag to delete symlinks
if eval sudo stow -D -v -d "$STOW_DIR" --dotfiles --target "$TARGET" $IGNORE_OPTS "$PACKAGE"; then
    echo ""
    echo -e "\033[0;32mSuccessfully removed symlinks for package: $PACKAGE\033[0m"
else
    echo ""
    echo -e "\033[0;31mFailed to remove symlinks\033[0m"
    exit 1
fi
