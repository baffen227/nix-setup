#!/usr/bin/env bash

# show_links.sh
# Shows all symlinks created by a stow package
# Usage: ./show_links.sh <package_name> [target_dir]
# Example: ./show_links.sh crazy-diamond
# Example: ./show_links.sh global

set -e

PACKAGE=$1
TARGET=${2:-/}
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
STOW_DIR=$(dirname "$SCRIPT_DIR")

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

echo "Symlinks created by package '$PACKAGE' (Target: $TARGET):"
echo ""

# Find all files in the package and check if they exist as symlinks in target
# Skip files in dot-claude and dot-gemini except settings.json
found_links=0

while IFS= read -r -d '' file; do
    # Skip dot-claude and dot-gemini files except settings.json
    if [[ "$file" == */dot-claude/* && "$file" != */dot-claude/settings.json ]]; then
        continue
    fi
    if [[ "$file" == */dot-gemini/* && "$file" != */dot-gemini/settings.json ]]; then
        continue
    fi
    # Get relative path from package directory
    rel_path="${file#$STOW_DIR/$PACKAGE/}"

    # Convert dot- prefix to . for dotfiles
    target_path="$TARGET/$rel_path"
    target_path="${target_path//\/dot-/\/.}"

    # Check if it's a symlink pointing to our repo
    if [ -L "$target_path" ]; then
        link_target=$(readlink "$target_path")
        if [[ "$link_target" == *"$PACKAGE"* ]]; then
            echo "  $target_path -> $link_target"
            ((found_links++))
        fi
    fi
done < <(find "$STOW_DIR/$PACKAGE" -type f -print0)

echo ""
if [ $found_links -eq 0 ]; then
    echo "No symlinks found for package '$PACKAGE'"
    echo "Run './apply_stow.sh $PACKAGE' to create symlinks"
else
    echo "Total: $found_links symlinks"
fi
