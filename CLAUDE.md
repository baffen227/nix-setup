# CLAUDE.md

This file provides **technical engineering guidance** to Claude Code (claude.ai/code) when working with code in this repository. It emphasizes implementation details, troubleshooting, testing workflows, and system internals.

**For user-friendly guides**: See `README.md`
**For project planning**: See `GEMINI.md`

## Team Roles

In this project, responsibilities are divided as follows:
- **Gemini (Project Manager)**: Responsible for overall project planning, architecture design, task breakdown, and strategic decision-making. Focuses on the "why" and "what".
- **Claude (Technical Engineer)**: Responsible for technical implementation, coding, bug fixing, and ensuring the technical integrity of the solution. Focuses on the "how".

## Repository Overview

This is a personal NixOS dotfiles repository managed with GNU Stow for multiple hosts. The repository uses a host-based directory structure where each hostname contains its own configuration files that are symlinked to the appropriate locations on the system.

## Repository Structure

```
.
├── <hostname>/           # Host-specific configurations (e.g., crazy-diamond, thehand)
│   └── etc/nixos/       # NixOS system configuration
├── global/              # Shared configurations across all hosts
│   ├── etc/nixos/       # Shared NixOS configs (common.nix + neovim modules)
│   │   ├── common.nix   # Shared system configuration (393 lines)
│   │   └── neovim/      # Neovim plugin configuration (4 modules)
│   └── home/<user>/     # User dotfiles (git, tmux, gemini, claude, zed, lazygit, ghostty, etc.)
├── scripts/             # Automation and deployment scripts
├── docs/
│   └── archive/         # Completed planning documents
│       ├── REFACTOR_PLAN_COMMON_NIX.md      # ✅ Completed: common.nix refactoring
│       └── PACKAGES_MIGRATION_PLAN.md       # ✅ Completed: Package integration from dotfiles
├── README.md            # Comprehensive user guide (574 lines)
├── CLAUDE.md            # Claude Code guidance (this file)
├── GEMINI.md            # Google Gemini guidance (233 lines)
└── MIGRATION_PLAN.md    # Future Flake-based architecture plan
```

**Key Architecture Points:**
- Each hostname directory (e.g., `crazy-diamond/`, `thehand/`) contains NixOS configurations specific to that machine
- The `global/` directory contains shared dotfiles and NixOS configs that apply to all hosts
- **Modular NixOS configuration:**
  - `global/etc/nixos/common.nix` - Shared configuration (393 lines): networking, desktop, packages, users, services
  - `global/etc/nixos/neovim/` - Neovim plugin modules (4 files): keymaps, plugins, settings
  - `<hostname>/etc/nixos/configuration.nix` - Host-specific (28-61 lines): hardware, kernel, bootloader
  - Eliminates 517 lines of duplicated code (80%+ reduction)
- Stow manages symlinks with the `--dotfiles` flag (files prefixed with `dot-` become `.` in the target)
- NixOS configuration files are in `etc/nixos/` and symlinked to `/etc/nixos/`
- User dotfiles are in `global/home/<username>/` and symlinked to the user's home directory

## Essential Commands

### Recommended Workflow (Using Automation Scripts)

The repository includes automation scripts in `scripts/` that handle the complete deployment workflow:

```bash
# Primary deployment workflow (recommended)
./scripts/rebuild_nixos.sh           # Deploy global + hostname packages, validate, and switch
./scripts/rebuild_nixos.sh test      # Test mode (reverts on reboot)
./scripts/rebuild_nixos.sh dry-build # Dry run to check for errors

# Other useful scripts
./scripts/list_packages.sh           # List available hosts and packages
./scripts/check_stow.sh              # Check for conflicts before deployment
./scripts/show_links.sh              # Show created symlinks
./scripts/validate_nix.sh            # Validate NixOS configuration syntax
./scripts/unstow.sh <package>        # Remove symlinks for a package
```

**rebuild_nixos.sh features:**
- Automatically deploys both global and host-specific configurations
- Validates NixOS configuration before applying
- Checks for uncommitted git changes (warns if dirty)
- Handles stow conflicts with automatic backup system
- Supports flags: `--skip-stow`, `--skip-git-check`, `--force`

### Manual Setup and Deployment

For manual deployment without scripts:

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

**Configuration Structure:**
- Host-specific config: 61 lines (down from 315 lines after common.nix refactoring)
- Imports: `./hardware-configuration.nix`, `/etc/nixos/common.nix`, and nixos-hardware profiles
- All shared configuration (desktop, packages, users, etc.) imported from `common.nix`

**Hardware:**
- AMD Ryzen 7 7840HS CPU (Zen 4)
- AMD Radeon 780M iGPU (Phoenix architecture)
- Uses latest kernel (`pkgs.linuxPackages_latest`)
- AMD P-State EPP driver enabled via `boot.kernelParams = [ "amd_pstate=active" ]`
- Hardware graphics acceleration enabled

**Hardware Profiles (from nixos-hardware):**
- `<nixos-hardware/common/pc/laptop>`
- `<nixos-hardware/common/pc/ssd>`
- `<nixos-hardware/common/cpu/amd>`
- `<nixos-hardware/common/gpu/amd>`

**Host-Specific Settings:**
- Kernel: Latest (`linuxPackages_latest`)
- Kernel params: `amd_pstate=active`
- Hardware graphics with 32-bit support
- Firmware updates: `services.fwupd.enable = true`
- Bootloader: systemd-boot

### Host: thehand

**Configuration Structure:**
- Host-specific config: 28 lines (down from 280 lines after common.nix refactoring)
- Imports: `./hardware-configuration.nix`, `/etc/nixos/common.nix`, and nixos-hardware profile
- All shared configuration (desktop, packages, users, etc.) imported from `common.nix`

**Hardware:**
- Lenovo ThinkPad T14s
- Standard kernel (no special kernel parameters)

**Hardware Profile (from nixos-hardware):**
- `<nixos-hardware/lenovo/thinkpad/t14s>`

**Host-Specific Settings:**
- Bootloader: systemd-boot
- Hostname: thehand
- (Minimal configuration - most settings inherited from common.nix)

### Common Configuration (global/etc/nixos/common.nix)

All shared configuration is centralized in `global/etc/nixos/common.nix` (393 lines), eliminating 517 lines of duplicated code across hosts. This file contains:

**Networking:**
- NetworkManager enabled
- Firewall configured (ports 80, 443 open for development)
- Reverse path drop logging enabled

**Time & Locale:**
- Time zone: Asia/Taipei
- Locale: en_US.UTF-8 with zh_TW.UTF-8 regional settings
- Input method: fcitx5 with Chewing (Traditional Chinese)

**Desktop Environment:**
- GNOME with GDM display manager
- X11 windowing system with US keyboard layout
- Excluded default GNOME apps: photos, tour, clocks, contacts, maps, music, weather, calendar, cheese, epiphany, geary, totem, simple-scan, games

**Audio:**
- PipeWire (PulseAudio compatibility enabled)
- rtkit enabled for real-time scheduling

**Printing:**
- CUPS enabled with foomatic-db drivers

**Virtualization:**
- Docker enabled
- Container support enabled

**Hardware:**
- Saleae Logic Analyzer support enabled

**Development Services:**
- udev rules for embedded development (openocd for ST-LINK, CANable USB-CAN adapter)

**Fonts:**
- Noto fonts (including CJK Sans/Serif, Emoji)
- Hack Nerd Font, Source Code Pro
- Font Awesome, ttf-tw-moe (Taiwan MOE fonts)

**System Packages (85+ packages):**
- **Development tools:** git, vim, gnupg, lazygit, claude-code, docker-compose, hoppscotch
- **Nix tools:** nil, nixd, nixfmt-rfc-style, nixpkgs-fmt
- **File management:** nnn, tree, file, eza, fzf, stow
- **Archives:** p7zip, unzip, rar, xz, zip
- **Monitoring:** btop, iftop, iotop, lsof, ltrace, strace
- **System tools:** ethtool, lm_sensors, pciutils, sysstat, usbutils, nettools, gparted, mkcert
- **Data processors:** glow, jq, yq-go
- **Network:** wget, ripgrep
- **GUI Applications:** element-desktop, ghostty, libreoffice-fresh, vlc, flameshot, foliate
- **Media:** ffmpeg
- **Hardware:** saleae-logic-2, xorg.xeyes
- **Other:** cowsay, neofetch, nix-output-monitor
- **GNOME:** kimpanel extension, gnome-tweaks

**Programs:**
- Firefox
- AppImage support (with binfmt)
- nix-ld (dynamic linker for non-NixOS binaries)
- **Neovim** (configured with plugin system - see neovim/ directory)
- **Editors:** Zed (unstable), VSCode/VSCodium with 20+ extensions

**Users:**
- User account: bagfen (in networkmanager, wheel, and dialout groups)

**System:**
- Allow unfree packages
- State version: 25.11

### Accessing Unstable Packages

The `unstable` channel is configured in `global/etc/nixos/common.nix`:
```nix
let
  unstable = import <unstable> { config = { allowUnfree = true; }; };
in
```

To use unstable packages:
- In `common.nix`: Prefix with `unstable.` (e.g., `unstable.some-package`)
- In host configs: Add unstable package import at the top, or add packages to common.nix instead

## Important Files

### Documentation
- `README.md` - Comprehensive user guide with workflows and troubleshooting (574 lines)
- `CLAUDE.md` - This file, guidance for Claude Code
- `GEMINI.md` - Guidance for Google Gemini (233 lines)
- `MIGRATION_PLAN.md` - Future Flake-based architecture migration plan
- `docs/archive/REFACTOR_PLAN_COMMON_NIX.md` - ✅ Completed: common.nix refactoring (archived)
- `docs/archive/PACKAGES_MIGRATION_PLAN.md` - ✅ Completed: Package integration from dotfiles (archived)

### NixOS Configuration
- `global/etc/nixos/common.nix` - Shared NixOS configuration across all hosts (393 lines)
  - Contains: Networking, Time/Locale, Desktop (GNOME), Audio (PipeWire), Fonts, System packages, Users, Programs, Services, Virtualization, Hardware
  - Imported by all host configurations to eliminate code duplication
- `global/etc/nixos/neovim/` - Neovim plugin configuration modules (4 files)
  - `keymaps/default.nix` - Vim keybindings
  - `plugins/configs.nix` - Plugin configurations
  - `plugins/packages.nix` - Plugin package lists (categorized: essential, navigation, git, language, lsp, ui, utilities)
  - `settings/options.nix` - Vim options
- `<hostname>/etc/nixos/configuration.nix` - Host-specific NixOS configuration
  - crazy-diamond: 61 lines (hardware, kernel, graphics settings)
  - thehand: 28 lines (hardware, bootloader, hostname only)
- `<hostname>/etc/nixos/hardware-configuration.nix` - Auto-generated hardware config (DO NOT manually edit)

### Global Dotfiles
- `global/home/bagfen/dot-gitconfig` - Git configuration with aliases (user: baffen227@gmail.com)
- `global/home/bagfen/dot-tmux.conf` - tmux configuration (prefix: C-a, 122 lines)
- `global/home/bagfen/dot-claude/settings.json` - Claude Code settings (other files ignored by git)
- `global/home/bagfen/dot-gemini/settings.json` - Gemini CLI settings (other files ignored by git)
- `global/home/bagfen/dot-config/ghostty/config` - Ghostty terminal (Hack Nerd Font, MaterialDarker theme)
- `global/home/bagfen/dot-config/lazygit/config.yml` - lazygit configuration
- `global/home/bagfen/dot-config/zed/settings.json` - Zed editor settings (Catppuccin Macchiato, vim mode)
- `global/home/bagfen/dot-config/zed/keymap.json` - Zed custom keybindings (vim-style with space leader)

### Automation Scripts (scripts/)
- `rebuild_nixos.sh` - Main deployment workflow (stow + validate + rebuild)
- `apply_stow.sh` - Apply stow configuration with conflict checking
- `backup_configs.sh` - Backup conflicting files with timestamps
- `check_stow.sh` - Check for stow conflicts before deployment
- `list_packages.sh` - List available stow packages
- `show_links.sh` - Show created symlinks
- `unstow.sh` - Remove stow symlinks safely
- `validate_nix.sh` - Validate NixOS configuration syntax

## Development Guidelines

### When Modifying NixOS Configuration

1. Always read the current configuration files before making changes
2. **For shared configuration** (packages, desktop, users): Edit `global/etc/nixos/common.nix`
3. **For host-specific configuration** (hardware, kernel, bootloader): Edit `<hostname>/etc/nixos/configuration.nix`
4. Test configuration before switching: `sudo nixos-rebuild dry-build` or `sudo nixos-rebuild test`
5. Do not modify `hardware-configuration.nix` - it's auto-generated
6. System state version (currently 25.11) should not be changed after initial install

### When Adding New Dotfiles

1. All user dotfiles should be placed in `global/home/<username>/` (host-specific user dotfiles are not currently used)
2. Use `dot-` prefix for files that should become `.` files (e.g., `dot-bashrc` → `.bashrc`)
3. Use `dot-config/app/file` for `.config/app/file` structure
4. After adding files, run `./scripts/rebuild_nixos.sh` or manual stow command to create symlinks

### Using Automation Scripts

1. **Recommended:** Use `./scripts/rebuild_nixos.sh` for all deployments
2. The script automatically handles both global and host-specific configurations
3. Conflicts are detected and backed up to `~/.config-backups/<timestamp>/`
4. Script checks for uncommitted git changes and warns if repository is dirty
5. Use `./scripts/check_stow.sh` to preview conflicts before deploying
6. See `README.md` for detailed workflow examples and troubleshooting

### Technical Workflow Details

**rebuild_nixos.sh execution order:**
1. Git dirty check (unless `--skip-git-check`)
2. Deploy global package (unless `--skip-stow`)
3. Deploy hostname package (unless `--skip-stow`)
4. Validate with `nixos-rebuild dry-build`
5. Apply with specified mode (test/switch/boot/dry-build)

**When to use --restow:**
- After deleting files from a package
- After renaming files in a package
- For major structural changes
- When adding new files: optional but safer

**Stow behavior:**
- Existing correct symlinks: No conflict, recognized automatically
- Real files or wrong symlinks: Conflict reported, requires backup/removal
- After `--restow`: Old broken links automatically cleaned up

**Credential handling:**
- Scripts use regex to ignore Claude/Gemini credentials: `--ignore='dot-claude/(?!settings\.json$).+' --ignore='dot-gemini/(?!settings\.json$).+'`
- Only `settings.json` is symlinked, all other files ignored

### Stow Important Notes

- Stow only handles one layer of symlinks; the `/etc/nixos` folder itself is not symlinked, only its contents
- The automation scripts automatically backup conflicting files to `~/.config-backups/<timestamp>/`
- Manual backup: `sudo mv /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup`
- Use `--dotfiles` flag to convert `dot-` prefix to `.`
- Use `-d` to specify the stow directory and `--target` for the destination
- Scripts use special ignore patterns for Claude/Gemini credentials (only settings.json is tracked)

## Testing and Validation Workflow

### Safe Testing Procedure (Recommended)

Always test changes before permanently applying them:

```bash
# 1. Validate syntax without applying changes
./scripts/rebuild_nixos.sh $(hostname) dry-build

# 2. Test temporarily (reverts on reboot)
./scripts/rebuild_nixos.sh $(hostname) test

# 3. If satisfied, permanently apply
./scripts/rebuild_nixos.sh $(hostname) switch
```

### Manual Validation Commands

```bash
# Validate NixOS configuration syntax
./scripts/validate_nix.sh -v
nix-instantiate --parse /etc/nixos/configuration.nix

# Check for stow conflicts before deployment
./scripts/check_stow.sh global
./scripts/check_stow.sh $(hostname)

# Verify created symlinks
./scripts/show_links.sh global
./scripts/show_links.sh $(hostname)
ls -la ~/.gitconfig ~/.tmux.conf  # Verify dotfiles
ls -la /etc/nixos/                # Verify NixOS config
```

### Rollback Procedures

**If NixOS rebuild fails or breaks the system:**

```bash
# Method 1: Rollback to previous generation (immediate)
sudo nixos-rebuild switch --rollback

# Method 2: Boot into previous generation
# At boot, select previous generation from GRUB menu

# Method 3: List and switch to specific generation
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
sudo nix-env --switch-generation <number> --profile /nix/var/nix/profiles/system
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

**If stow creates incorrect symlinks:**

```bash
# Remove all symlinks for a package
./scripts/unstow.sh global
./scripts/unstow.sh $(hostname)

# Restore from backup (if backup was created)
ls -la ~/.config-backups/  # Find latest backup
sudo cp -r ~/.config-backups/<timestamp>/* /
```

## Troubleshooting

### Stow Conflicts

**Error:** `WARNING! stowing <file> would cause conflicts:`

**Cause:** Target file/directory already exists and is not a symlink managed by stow

**Solution:**
```bash
# Option 1: Automatic backup and move (recommended)
./scripts/backup_configs.sh <package> --move
./scripts/apply_stow.sh <package>

# Option 2: Manual backup and remove
./scripts/backup_configs.sh <package>
sudo rm <conflicting-file>
./scripts/apply_stow.sh <package>

# Option 3: Use --force flag (skips conflict check, use with caution)
./scripts/rebuild_nixos.sh $(hostname) switch --force
```

### NixOS Build Failures

**Error:** `error: syntax error, unexpected <token>`

**Cause:** Nix syntax error in configuration.nix

**Solution:**
```bash
# Validate syntax
./scripts/validate_nix.sh -v
nix-instantiate --parse /etc/nixos/configuration.nix

# Edit configuration
vim /etc/nixos/configuration.nix

# Or rollback if already switched
sudo nixos-rebuild switch --rollback
```

**Error:** `error: attribute '<package>' missing`

**Cause:** Package not available in configured channels

**Solution:**
```bash
# Search for package
nix search <package-name>

# Use unstable channel
unstable.<package-name>

# Update channels
sudo nix-channel --update
```

### Permission Issues

**Error:** `Permission denied` when running stow

**Cause:** System files require sudo privileges

**Solution:**
- Scripts automatically handle sudo for system operations
- For manual commands: `sudo stow ...`
- User dotfile editing does NOT require sudo
- Only deployment requires sudo

**Error:** `cannot create symlink: File exists`

**Cause:** Target location has existing file/directory

**Solution:**
```bash
# Check what exists at target
ls -la <target-path>

# If it's a real file, backup first
./scripts/backup_configs.sh <package>

# Then apply stow
./scripts/apply_stow.sh <package>
```

### Git Dirty Warning

**Warning:** `Uncommitted changes detected`

**Cause:** Repository has uncommitted changes

**Best Practice:**
```bash
# Option 1: Commit changes (recommended)
git add .
git commit -m "Description of changes"
./scripts/rebuild_nixos.sh $(hostname) switch

# Option 2: Skip check for testing (not recommended for production)
./scripts/rebuild_nixos.sh $(hostname) test --skip-git-check
```

**Why this matters:** Committing changes ensures system state corresponds to a specific git commit, making it easier to track what configuration was deployed when.

### Symlink Verification Failed

**Issue:** Symlinks point to wrong locations or don't exist

**Solution:**
```bash
# Check current symlinks
./scripts/show_links.sh global
./scripts/show_links.sh $(hostname)

# Remove and recreate
./scripts/unstow.sh <package>
./scripts/apply_stow.sh <package> --restow
```

### Common Mistakes

1. **Modifying hardware-configuration.nix manually**
   - This file is auto-generated by NixOS
   - Changes will be overwritten
   - Hardware changes should go in configuration.nix

2. **Creating symlinks manually inside packages**
   - Don't create symlinks from hostname/ to global/
   - Stow manages all symlinks automatically
   - Each package is deployed separately

3. **Not using --restow after file deletions**
   - Old symlinks will remain as broken links
   - Use `--restow` to clean up automatically

4. **Forgetting to update channels**
   - Packages may be outdated or missing
   - Run `sudo nix-channel --update` regularly

## NixOS Generation Management

### Understanding Generations

Every `nixos-rebuild switch` creates a new system generation. Old generations remain available for rollback.

```bash
# List all system generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Current generation is marked with (current)
```

### Cleanup and Disk Space Management

```bash
# Remove all old generations (keeps current only)
sudo nix-collect-garbage -d

# Remove generations older than 30 days
sudo nix-collect-garbage --delete-older-than 30d

# Remove specific generation
sudo nix-env --delete-generations <number> --profile /nix/var/nix/profiles/system

# After cleanup, rebuild to update bootloader
sudo nixos-rebuild switch
```

### Optimizing Nix Store

```bash
# Find duplicate files and hard-link them to save space
sudo nix-store --optimize

# Check store integrity
sudo nix-store --verify --check-contents

# Repair corrupted paths
sudo nix-store --repair-path <path>
```

### Checking Disk Usage

```bash
# See what's using space in /nix/store
nix-store --gc --print-roots | grep -v '^/proc/'

# Analyze closure size for a package
nix path-info -rSh /run/current-system

# List largest store paths
du -sh /nix/store/* | sort -rh | head -20
```

## Security Considerations

### Sudo Usage

- **System operations** (stow to `/etc`, `nixos-rebuild`): Require sudo
- **User dotfiles** (editing files in `global/`, `<hostname>/`): No sudo needed
- **Scripts**: Automatically handle sudo when required
- **Never run git commands with sudo**: Maintains correct file ownership

### File Permissions

```bash
# Repository files should be owned by user, not root
ls -la ~/nix-setup  # Should show your username, not root

# If accidentally owned by root, fix with:
sudo chown -R $USER:$USER ~/nix-setup

# Symlinks inherit permissions from target files
# /etc/nixos files: owned by root (correct)
# ~/.gitconfig, etc.: owned by user (correct)
```

### Credential Protection

- Claude/Gemini credentials are gitignored (except settings.json)
- Scripts use regex patterns to prevent accidental symlinking of credentials
- Only `dot-claude/settings.json` and `dot-gemini/settings.json` are managed
- All other files in these directories are ignored

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

## Zed Editor Configuration

**Settings (from .config/zed/settings.json):**
- Theme: Catppuccin Macchiato
- Vim mode: enabled with relative line numbers
- Font: Hack Nerd Font Mono (size 16)
- LSP: Configured for Rust (rust-analyzer) and Nix (nixd)
- Agent model: claude-sonnet-4

**Key Bindings (from .config/zed/keymap.json):**
- Insert mode escape: `jk` or `jj`
- Leader key: `space` (vim mode)
- `space + w` - Save file
- `space + q` - Close active pane
- `space + e` - Toggle project panel
- `space + f` - Format document
- Pane navigation: `ctrl+h/j/k/l` (vim-style)
- Pane splits: `ctrl+w + v/s` (vertical/horizontal)

## Quick Reference for Engineers

### Most Common Workflows

```bash
# Daily development cycle
vim <hostname>/etc/nixos/configuration.nix  # Edit config
./scripts/rebuild_nixos.sh dry-build         # Validate
./scripts/rebuild_nixos.sh test              # Test (temporary)
./scripts/rebuild_nixos.sh switch            # Apply (permanent)

# Add new dotfile
vim global/home/bagfen/dot-<filename>
./scripts/rebuild_nixos.sh switch

# Debugging failed build
./scripts/validate_nix.sh -v                 # Check syntax
nix-instantiate --parse /etc/nixos/configuration.nix
sudo nixos-rebuild switch --rollback         # Undo if needed

# Check what will change
./scripts/check_stow.sh global
./scripts/show_links.sh global
nix-store --gc --print-roots | grep -v '^/proc/'

# Cleanup after testing
sudo nix-collect-garbage -d
sudo nix-store --optimize
```

### Critical Files for Engineers

**Read before modifying:**
- `scripts/rebuild_nixos.sh` - Main deployment workflow logic
- `scripts/apply_stow.sh` - Stow deployment with ignore patterns
- `<hostname>/etc/nixos/configuration.nix` - NixOS system config
- `.gitignore` - Credential protection rules

**Never modify:**
- `<hostname>/etc/nixos/hardware-configuration.nix` - Auto-generated

**Safe to modify:**
- `global/home/bagfen/*` - User dotfiles
- `global/etc/nixos/common.nix` - Shared NixOS configuration (networking, desktop, packages, users, services)
- `global/etc/nixos/neovim/*` - Neovim plugin configuration modules
- `<hostname>/etc/nixos/configuration.nix` - Host-specific NixOS configuration (hardware, kernel, bootloader)

### Debugging Tips

1. **Use verbose mode** for stow: `-v` flag shows all operations
2. **Check symlinks**: `ls -la <target>` shows where symlinks point
3. **Git status**: Run `git status` before rebuilding to see what changed
4. **Dry-build first**: Always test with `dry-build` before `switch`
5. **Keep old generations**: Don't garbage collect until new config is stable
6. **Test mode**: Use `test` mode for risky changes (reverts on reboot)

### Performance Optimization

```bash
# Enable parallel building (add to configuration.nix)
nix.settings.max-jobs = 8;
nix.settings.cores = 4;

# Use binary cache
nix.settings.substituters = [ "https://cache.nixos.org" ];

# Optimize store regularly
sudo nix-store --optimize  # Hard-links duplicate files

# Monitor build progress
nixos-rebuild switch --show-trace  # Detailed error traces
```

## Additional Resources

### Documentation Hierarchy

1. **CLAUDE.md** (this file) - Technical engineer's guide with implementation details
2. **README.md** - User-friendly guide (574 lines) with workflows and examples
3. **GEMINI.md** - Project manager's guide with detailed script documentation (233 lines)
4. **MIGRATION_PLAN.md** - Future architecture migration plan (Flake-based)
5. **docs/archive/** - Completed planning documents (archived after implementation)
   - REFACTOR_PLAN_COMMON_NIX.md - ✅ Common.nix refactoring completed
   - PACKAGES_MIGRATION_PLAN.md - ✅ Package integration from dotfiles completed

### When to Use What

- **Quick reference**: CLAUDE.md (this file)
- **Learning the system**: README.md
- **Script details**: GEMINI.md or read `scripts/*.sh` directly
- **Architecture planning**: MIGRATION_PLAN.md

### External Documentation

- NixOS Manual: https://nixos.org/manual/nixos/stable/
- Nix Pills: https://nixos.org/guides/nix-pills/
- nixos-hardware: https://github.com/NixOS/nixos-hardware
- GNU Stow Manual: https://www.gnu.org/software/stow/manual/

## Future Plans

The repository is planning a migration to a Flake-based architecture:
- Target architecture inspired by hlissner/dotfiles
- Modular structure with separate modules for hosts, users, and packages
- Integration with home-manager for declarative dotfile management
- See `MIGRATION_PLAN.md` for detailed migration phases

**Technical implications:**
- Migration will replace Stow with home-manager
- Channels will be replaced with flake.lock for reproducibility
- Current scripts will be deprecated in favor of flake commands
- Rollback strategy during migration: Keep current setup until flake version is stable
