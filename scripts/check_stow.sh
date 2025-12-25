#!/usr/bin/env bash

# check_stow.sh
# Usage: ./check_stow.sh <package_name> [target_dir]
# Example: ./check_stow.sh crazy-diamond
# Example: ./check_stow.sh global

PACKAGE=$1
TARGET=${2:-/} # Default target is root (/), consistent with your NixOS setup
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
    echo "Available packages:"
    ls -d "$STOW_DIR"/*/ 2>/dev/null | xargs -n 1 basename || echo "  (none found)"
    exit 1
fi

echo "Checking for conflicts in package: '$PACKAGE' (Target: $TARGET)..."

# Update sudo timestamp to avoid password prompt being captured
sudo -v

# Run stow in simulation mode (-n) with verbose (-v).
# We redirect stderr to stdout (2>&1) to capture warning messages.
OUTPUT=$(eval sudo stow -n -v -d "$STOW_DIR" --dotfiles --target "$TARGET" $IGNORE_OPTS "$PACKAGE" 2>&1)
STOW_EXIT_CODE=$?

# Check for "existing target" warning or non-zero exit code
if echo "$OUTPUT" | grep -q "existing target"; then
    echo ""
    echo -e "\033[0;31mCONFLICTS DETECTED! Operation aborted.\033[0m"
    echo "The following files already exist in the target directory and block the stow:"
    echo "---------------------------------------------------"
    # Filter output to show only conflict lines and colorize them
    echo "$OUTPUT" | grep "existing target" --color=always
    echo "---------------------------------------------------"
    echo "Recommended Actions:"
    echo "  1. Backup & Remove: 'mv /path/to/file /path/to/file.bak'"
    echo "  2. Adopt (if intended): use '--adopt' to pull the file into your repo."
    echo "  3. Use backup_configs.sh to automatically backup conflicting files"
    exit 1
elif [ $STOW_EXIT_CODE -ne 0 ]; then
    echo ""
    echo -e "\033[0;31mSTOW FAILED (Unknown Error)\033[0m"
    echo "Output:"
    echo "$OUTPUT"
    exit $STOW_EXIT_CODE
else
    echo -e "\033[0;32mNo conflicts found. Ready to stow.\033[0m"
fi
