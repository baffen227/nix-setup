# GEMINI.md

This file provides guidance to Google Gemini when working with code in this repository.

## Team Roles

In this project, responsibilities are divided as follows:
- **Gemini (Project Manager)**: Responsible for overall project planning, architecture design, task breakdown, and strategic decision-making. Focuses on the "why" and "what".
- **Claude (Technical Engineer)**: Responsible for technical implementation, coding, bug fixing, and ensuring the technical integrity of the solution. Focuses on the "how".

## Strategic Roadmap

**Current Focus:** Migration to Flake-based Architecture
- We are currently transitioning from a Stow-based setup to a pure Nix Flake architecture (inspired by hlissner/dotfiles).
- See `MIGRATION_PLAN.md` for the detailed execution plan.
- **Goal:** modular configuration, declarative dotfiles via home-manager, and eliminating Stow.

## Repository Overview

This is a personal NixOS dotfiles repository managed with GNU Stow for multiple hosts. The repository uses a host-based directory structure where each hostname contains its own configuration files that are symlinked to the appropriate locations on the system.

## Repository Structure

```
.
├── .gitignore
├── CLAUDE.md
├── GEMINI.md
├── MIGRATION_PLAN.md
├── README.md
├── docs/
│   └── archive/             # Completed planning documents
│       └── REFACTOR_PLAN_COMMON_NIX.md  # ✅ Completed: common.nix refactoring
├── crazy-diamond/           # Host: crazy-diamond
│   └── etc/
│       └── nixos/
│           ├── configuration.nix
│           └── hardware-configuration.nix
├── global/                  # Shared configurations
│   ├── etc/
│   │   └── nixos/
│   │       └── packages/
│   └── home/
│       └── bagfen/
│           ├── dot-gitconfig
│           ├── dot-tmux.conf
│           ├── dot-claude/
│           ├── dot-config/
│           │   ├── ghostty/
│           │   ├── lazygit/
│           │   └── zed/
│           └── dot-gemini/
├── scripts/                 # Management scripts
│   ├── apply_stow.sh
│   ├── backup_configs.sh
│   ├── check_stow.sh
│   ├── list_packages.sh
│   ├── rebuild_nixos.sh
│   ├── show_links.sh
│   ├── unstow.sh
│   └── validate_nix.sh
└── thehand/                 # Host: thehand
    └── etc/
        └── nixos/
            ├── configuration.nix
            └── hardware-configuration.nix
```

**Key Architecture Points:**
- Each hostname directory (e.g., `crazy-diamond/`, `thehand/`) contains configurations specific to that machine
- The `global/` directory contains shared dotfiles that apply to all hosts
- Stow manages symlinks with the `--dotfiles` flag (files prefixed with `dot-` become `.` in the target)
- NixOS configuration files are in `etc/nixos/` and symlinked to `/etc/nixos/`
- User dotfiles are in `home/<username>/` and symlinked to the user's home directory

## Helper Scripts

The `scripts/` directory contains utility scripts to simplify common tasks. These scripts should be executed from the repository root.

- `scripts/apply_stow.sh`: Applies configuration symlinks using Stow.
- `scripts/rebuild_nixos.sh`: Rebuilds and switches the NixOS configuration.
- `scripts/backup_configs.sh`: Backups existing configurations.
- `scripts/check_stow.sh`: Verifies Stow symlinks.
- `scripts/validate_nix.sh`: Validates Nix configuration syntax.
- `scripts/unstow.sh`: Removes Stow symlinks.
- `scripts/list_packages.sh`: Lists installed packages.
- `scripts/show_links.sh`: Shows current Stow links.

## Essential Commands

### Primary Workflow (Using Scripts)

The `scripts/` directory provides the recommended workflow for deployment, ensuring safety checks and consistent state.

```bash
# 1. Deploy & Switch (Recommended)
# Handles global/host stow, validates config, and switches system.
./scripts/rebuild_nixos.sh switch

# 2. Test Changes (Temporary)
# Applies changes but reverts on reboot.
./scripts/rebuild_nixos.sh test

# 3. Dry Run (Validation Only)
./scripts/rebuild_nixos.sh dry-build
```

### Manual/Legacy Commands

Use these only if scripts fail or for granular control.

#### Setup and Deployment

```bash
# Apply configuration for current host
sudo stow -d ~/nix-setup --dotfiles --target / $(hostname)

# Apply configuration for specific host
sudo stow -d ~/nix-setup --dotfiles --target / crazy-diamond

# Remove configuration symlinks
sudo stow -D -d ~/nix-setup --dotfiles --target / <hostname>
```

### NixOS System Management

```bash
# Test configuration without switching (dry-run)
sudo nixos-rebuild dry-build

# Test configuration (temporarily, reverts on reboot)
sudo nixos-rebuild test

# Apply and switch to new configuration
sudo nixos-rebuild switch

# Update channels and rebuild system
sudo nix-channel --update && sudo nixos-rebuild switch --upgrade

# Clean up old generations
sudo nix-collect-garbage -d

# Search for packages
nix search <package-name>
```

### Required Nix Channels

The system requires these channels to be configured:
```bash
sudo nix-channel --add https://channels.nixos.org/nixos-25.11 nixos
sudo nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware
sudo nix-channel --add https://channels.nixos.org/nixos-unstable unstable
sudo nix-channel --update
```

## NixOS Configuration Details

### Current Host: crazy-diamond

**Hardware:**
- AMD Ryzen 7 7840HS CPU (Zen 4)
- AMD Radeon 780M iGPU (Phoenix architecture)
- Uses latest kernel (`pkgs.linuxPackages_latest`)
- AMD P-State EPP driver enabled via `boot.kernelParams = [ "amd_pstate=active" ]`

**Desktop Environment:**
- GNOME with GDM display manager
- Excluded many default GNOME applications (see configuration.nix:267-286)
- fcitx5 input method with Chewing (Traditional Chinese)

**Key Configuration Imports:**
- Hardware profiles from nixos-hardware:
  - `<nixos-hardware/common/pc/laptop>`
  - `<nixos-hardware/common/pc/ssd>`
  - `<nixos-hardware/common/cpu/amd>`
  - `<nixos-hardware/common/gpu/amd>`

### Host: thehand

**Hardware:**
- Lenovo ThinkPad T14s
- Uses systemd-boot bootloader
- Standard kernel (no special kernel parameters)

**Desktop Environment:**
- GNOME with GDM display manager
- Excluded many default GNOME applications (see configuration.nix:232-251)
- fcitx5 input method with Chewing (Traditional Chinese)

**Key Configuration Imports:**
- Hardware profile from nixos-hardware:
  - `<nixos-hardware/lenovo/thinkpad/t14s>`

### Accessing Unstable Packages

The configuration includes an `unstable` package set:
```nix
let
  unstable = import <unstable> { config = { allowUnfree = true; }; };
in
```

To use unstable packages in configuration.nix, prefix with `unstable.`:
```nix
environment.systemPackages = [ unstable.some-package ];
```

## Important Files

- `<hostname>/etc/nixos/configuration.nix` - Main NixOS system configuration
- `<hostname>/etc/nixos/hardware-configuration.nix` - Auto-generated hardware config (DO NOT manually edit)
- `global/home/bagfen/dot-gitconfig` - Git configuration with aliases
- `global/home/bagfen/dot-tmux.conf` - tmux configuration (prefix: C-a)
- `global/home/bagfen/dot-gemini/settings.json` - Gemini settings
- `global/home/bagfen/dot-claude/settings.json` - Claude settings
- `global/home/bagfen/dot-config/ghostty/config` - Ghostty terminal configuration
- `global/home/bagfen/dot-config/lazygit/config.yml` - Lazygit configuration
- `global/home/bagfen/dot-config/zed/settings.json` - Zed editor settings

## Development Guidelines

### When Modifying NixOS Configuration

1. Always read the current configuration.nix before making changes
2. Test configuration before switching: `sudo nixos-rebuild dry-build` or `sudo nixos-rebuild test`
3. Do not modify `hardware-configuration.nix` - it's auto-generated
4. Keep host-specific configuration in `<hostname>/etc/nixos/configuration.nix`
5. System state version (currently 25.11) should not be changed after initial install

### When Adding New Dotfiles

1. Determine if the dotfile is host-specific or global
2. Host-specific: place in `<hostname>/home/<username>/`
3. Global: place in `global/home/<username>/`
4. Use `dot-` prefix for files that should become `.` files (e.g., `dot-bashrc` → `.bashrc`)
5. Use `dot-config/app/file` for `.config/app/file` structure
6. After adding files, run stow command to create symlinks

### Stow Important Notes

- Stow only handles one layer of symlinks; the `/etc/nixos` folder itself is not symlinked, only its contents
- Always backup existing files before stowing: `sudo mv /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup`
- Use `--dotfiles` flag to convert `dot-` prefix to `.`
- Use `-d` to specify the stow directory and `--target` for the destination

## Git Aliases (from .gitconfig)

```bash
git st       # status
git co       # checkout
git br       # branch
git ci       # commit
git df       # diff
git lg       # log --oneline --graph --decorate
git last     # log -1 HEAD
git unstage  # reset HEAD --
```

## tmux Key Bindings (from .tmux.conf)

- Prefix: `C-a` (not default C-b)
- `prefix + r` - Reload tmux config
- `prefix + |` - Split pane horizontally
- `prefix + -` - Split pane vertically
- `prefix + h/j/k/l` - Navigate panes (vim-style)
- `prefix + H/J/K/L` - Resize panes
- `prefix + C-h/C-l` - Switch windows