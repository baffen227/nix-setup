#!/usr/bin/env bash

# validate_nix.sh
# Validates NixOS configuration without applying changes
# Usage: ./validate_nix.sh [--verbose]

set -e

VERBOSE=false

# Parse flags
for arg in "$@"; do
    if [ "$arg" = "--verbose" ] || [ "$arg" = "-v" ]; then
        VERBOSE=true
    fi
done

echo "Validating NixOS configuration..."
echo ""

# Check if configuration files exist
if [ ! -f /etc/nixos/configuration.nix ]; then
    echo -e "\033[0;31mERROR: /etc/nixos/configuration.nix not found\033[0m"
    exit 1
fi

if [ ! -f /etc/nixos/hardware-configuration.nix ]; then
    echo -e "\033[0;33mWARNING: /etc/nixos/hardware-configuration.nix not found\033[0m"
fi

# Run syntax check with dry-build
echo "Running nixos-rebuild dry-build..."
if [ "$VERBOSE" = true ]; then
    if sudo nixos-rebuild dry-build; then
        echo ""
        echo -e "\033[0;32mConfiguration validation successful!\033[0m"
        echo "No syntax errors found."
    else
        echo ""
        echo -e "\033[0;31mConfiguration validation failed.\033[0m"
        exit 1
    fi
else
    # Capture output
    if output=$(sudo nixos-rebuild dry-build 2>&1); then
        echo ""
        echo -e "\033[0;32mConfiguration validation successful!\033[0m"
        echo "No syntax errors found."
    else
        echo ""
        echo -e "\033[0;31mConfiguration validation failed.\033[0m"
        echo ""
        echo "Errors:"
        echo "$output"
        exit 1
    fi
fi

echo ""
echo "Next steps:"
echo "  - Test configuration: sudo nixos-rebuild test"
echo "  - Apply permanently: sudo nixos-rebuild switch"
echo "  - Or use: ./rebuild_nixos.sh \$(hostname) [test|switch]"
