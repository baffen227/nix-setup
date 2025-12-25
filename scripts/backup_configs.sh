#!/usr/bin/env bash

# backup_configs.sh
# Backs up existing files that would conflict with stow
# Usage: ./backup_configs.sh <package_name> [target_dir] [--move]
# Example: ./backup_configs.sh crazy-diamond
# Example: ./backup_configs.sh global / --move

set -e

PACKAGE=$1
TARGET=${2:-/}
MOVE_FILES=false
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
STOW_DIR=$(dirname "$SCRIPT_DIR")
BACKUP_DIR="$HOME/.config-backups/$(date +%Y%m%d_%H%M%S)_${PACKAGE}"

# Ignore patterns: only settings.json should be symlinked for .claude and .gemini
# Uses negative lookahead to ignore everything except settings.json
IGNORE_OPTS="--ignore='dot-claude/(?!settings\.json$).+' --ignore='dot-gemini/(?!settings\.json$).+'"

# Parse flags
for arg in "$@"; do
    if [ "$arg" = "--move" ]; then
        MOVE_FILES=true
    fi
done

# Validate arguments
if [ -z "$PACKAGE" ]; then
    echo "Usage: $0 <package_name> [target_directory] [--move]"
    echo ""
    echo "Options:"
    echo "  --move    Move conflicting files instead of copying (resolves conflicts immediately)"
    echo ""
    echo "Default behavior (copy):"
    echo "  - Safer: Original files remain in place"
    echo "  - Requires manual removal of originals after review"
    echo ""
    echo "With --move flag:"
    echo "  - Convenient: Conflicts resolved automatically"
    echo "  - Original files moved to backup location"
    echo "  - Can proceed directly to apply_stow.sh"
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

if [ "$MOVE_FILES" = true ]; then
    echo "Checking for conflicts in package: '$PACKAGE' (move mode)..."
else
    echo "Checking for conflicts in package: '$PACKAGE' (copy mode)..."
fi

# Update sudo timestamp to avoid password prompt being captured
sudo -v

# Run stow in simulation mode to detect conflicts
OUTPUT=$(eval sudo stow -n -v -d "$STOW_DIR" --dotfiles --target "$TARGET" $IGNORE_OPTS "$PACKAGE" 2>&1 || true)

# Check if there are conflicts
if ! echo "$OUTPUT" | grep -q "existing target"; then
    echo ""
    echo "No conflicts found. No backup needed."
    exit 0
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"
echo ""
echo "Backup directory created: $BACKUP_DIR"
echo ""

# Extract conflicting files and back them up
backup_count=0
while IFS= read -r line; do
    # Extract the file path from the conflict message
    # Format: "  * existing target is ..."
    if [[ "$line" =~ "existing target is" ]]; then
        # Extract path after "existing target is "
        conflict_file=$(echo "$line" | sed -n 's/.*existing target is \(.*\)/\1/p' | xargs)

        if [ -n "$conflict_file" ] && [ -e "$conflict_file" ]; then
            # Create parent directory in backup
            backup_path="$BACKUP_DIR$conflict_file"
            backup_parent=$(dirname "$backup_path")
            mkdir -p "$backup_parent"

            # Copy or move file to backup (preserve permissions and timestamps)
            if [ "$MOVE_FILES" = true ]; then
                if sudo mv "$conflict_file" "$backup_path"; then
                    echo "Moved: $conflict_file"
                    ((backup_count++))
                fi
            else
                if sudo cp -a "$conflict_file" "$backup_path"; then
                    echo "Backed up: $conflict_file"
                    ((backup_count++))
                fi
            fi
        fi
    fi
done <<< "$OUTPUT"

echo ""
if [ $backup_count -gt 0 ]; then
    if [ "$MOVE_FILES" = true ]; then
        echo -e "\033[0;32mSuccessfully moved $backup_count files to:\033[0m"
        echo "  $BACKUP_DIR"
        echo ""
        echo -e "\033[0;32mConflicts resolved! You can now apply stow:\033[0m"
        echo "  ./apply_stow.sh $PACKAGE"
        echo ""
        echo "To restore from backup:"
        echo "  sudo cp -a $BACKUP_DIR/* /"
    else
        echo -e "\033[0;32mSuccessfully backed up $backup_count files to:\033[0m"
        echo "  $BACKUP_DIR"
        echo ""
        echo "Next steps:"
        echo "  1. Review backed up files in $BACKUP_DIR"
        echo "  2. Remove original files: sudo rm <file>"
        echo "     OR rerun with --move flag: ./backup_configs.sh $PACKAGE --move"
        echo "  3. Apply stow: ./apply_stow.sh $PACKAGE"
        echo ""
        echo "To restore from backup:"
        echo "  sudo cp -a $BACKUP_DIR/* /"
    fi
else
    echo "No files were backed up."
    rm -rf "$BACKUP_DIR"
fi
