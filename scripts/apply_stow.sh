#!/usr/bin/env bash

# apply_stow.sh
# Safely applies stow configuration with conflict checking
# Usage: ./apply_stow.sh <package_name> [target_dir] [--restow]
# Example: ./apply_stow.sh crazy-diamond
# Example: ./apply_stow.sh global / --restow

set -e

PACKAGE=$1
TARGET=${2:-/}
RESTOW=false
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
STOW_DIR=$(dirname "$SCRIPT_DIR")

# Ignore patterns: only settings.json should be symlinked for .claude and .gemini
# Uses negative lookahead to ignore everything except settings.json
IGNORE_OPTS="--ignore='dot-claude/(?!settings\.json$).+' --ignore='dot-gemini/(?!settings\.json$).+'"

# Parse flags
for arg in "$@"; do
    if [ "$arg" = "--restow" ] || [ "$arg" = "-R" ]; then
        RESTOW=true
    fi
done

# Validate arguments
if [ -z "$PACKAGE" ]; then
    echo "Usage: $0 <package_name> [target_directory] [--restow]"
    echo ""
    echo "Options:"
    echo "  --restow, -R    Restow (remove old links and reapply)"
    echo ""
    echo "When to use --restow:"
    echo "  - After deleting files from the package"
    echo "  - After renaming files in the package"
    echo "  - For major structural changes"
    echo "  - When adding new files: --restow is optional but safer"
    exit 1
fi

# Skip conflict check if using --restow (since it will remove old links first)
if [ "$RESTOW" = false ]; then
    echo "Step 1/2: Checking for conflicts..."
    if ! "$SCRIPT_DIR/check_stow.sh" "$PACKAGE" "$TARGET"; then
        echo ""
        echo -e "\033[0;31mConflict check failed. Aborting deployment.\033[0m"
        echo "Run 'backup_configs.sh $PACKAGE' to backup conflicting files first."
        exit 1
    fi
    echo ""
else
    echo "Using --restow mode (will remove old links and reapply)..."
    echo ""
fi

# Apply stow
if [ "$RESTOW" = true ]; then
    echo "Step 2/2: Restowing configuration (unstow + stow)..."
    STOW_CMD="sudo stow -R -v -d \"$STOW_DIR\" --dotfiles --target \"$TARGET\" $IGNORE_OPTS \"$PACKAGE\""
else
    echo "Step 2/2: Applying stow configuration..."
    STOW_CMD="sudo stow -v -d \"$STOW_DIR\" --dotfiles --target \"$TARGET\" $IGNORE_OPTS \"$PACKAGE\""
fi

if eval $STOW_CMD; then
    echo ""
    echo -e "\033[0;32mSuccessfully applied package: $PACKAGE\033[0m"
    echo "Symlinks created in: $TARGET"
    if [ "$RESTOW" = true ]; then
        echo "Old broken links have been cleaned up."
    fi
else
    echo ""
    echo -e "\033[0;31mFailed to apply stow configuration\033[0m"
    exit 1
fi
