# NixOS Dotfiles Repository

Personal NixOS dotfiles and system configurations managed with GNU Stow for multiple hosts.

---

## 🚀 Quick Start (Recommended)

### First Time Setup

```bash
# 1. Clone repository
git clone <repo-url> ~/nix-setup
cd ~/nix-setup

# 2. Setup NixOS channels (one-time)
sudo nix-channel --add https://channels.nixos.org/nixos-25.11 nixos
sudo nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware
sudo nix-channel --add https://channels.nixos.org/nixos-unstable unstable
sudo nix-channel --update

# 3. Backup existing config (if needed)
./scripts/backup_configs.sh $(hostname) / --move

# 4. Deploy everything (one command!)
./scripts/rebuild_nixos.sh $(hostname) switch
```

That's it! Your system is configured with:
- ✅ NixOS system configuration
- ✅ Personal dotfiles (.gitconfig, .tmux.conf, editor configs, etc.)
- ✅ Everything deployed and activated

---

## 📝 Daily Usage

### Update Configuration Files

```bash
cd ~/nix-setup

# Edit any configuration file
vim global/home/bagfen/dot-gitconfig              # User dotfiles (shared)
vim crazy-diamond/etc/nixos/configuration.nix     # NixOS config (host-specific)

# Apply changes
./scripts/rebuild_nixos.sh $(hostname) switch
```

**That's all you need!** The script automatically:
- Deploys global dotfiles
- Deploys host-specific config
- Validates NixOS configuration
- Rebuilds the system

### Add New Files

```bash
# Add new dotfile
echo "alias ll='ls -la'" > global/home/bagfen/dot-bash_aliases

# Deploy changes
./scripts/rebuild_nixos.sh $(hostname) switch
```

### Delete or Rename Files

```bash
# Delete or rename files
rm global/home/bagfen/dot-old-config
mv global/home/bagfen/old global/home/bagfen/new

# Deploy with --restow to clean up old symlinks
./scripts/apply_stow.sh global --restow
./scripts/rebuild_nixos.sh $(hostname) switch
```

### Update System Packages

```bash
# Update channels and rebuild
sudo nix-channel --update
./scripts/rebuild_nixos.sh $(hostname) switch

# Clean up old generations
sudo nix-collect-garbage -d
```

### Remove All Configuration

```bash
# Remove all stow-managed symlinks
./scripts/unstow.sh $(hostname)  # Remove host config
./scripts/unstow.sh global       # Remove dotfiles
```

---

## 🔧 Helper Scripts (Recommended Tools)

All scripts can be run from any directory.

### Main Deployment Script

#### `rebuild_nixos.sh` - Complete Deployment Workflow

**Use this for most operations!** Handles everything automatically.

```bash
./scripts/rebuild_nixos.sh [hostname] [mode] [flags]

# Common usage:
./scripts/rebuild_nixos.sh $(hostname) test      # Test changes (temporary)
./scripts/rebuild_nixos.sh $(hostname) switch    # Apply permanently
./scripts/rebuild_nixos.sh $(hostname) switch --force  # Skip prompts
```

**What it does:**
1. ✅ Deploys global dotfiles (.gitconfig, .tmux.conf, etc.)
2. ✅ Deploys host-specific NixOS configuration
3. ✅ Validates configuration syntax
4. ✅ Rebuilds NixOS system

**Modes:**
- `test` - Temporary (reverts on reboot) - good for testing
- `switch` - Permanent - use this normally
- `boot` - Apply on next boot
- `dry-build` - Test syntax only

**Flags:**
- `--skip-stow` - Skip stow deployment (only rebuild NixOS)
- `--skip-git-check` - Skip uncommitted changes warning
- `--force` - Skip all confirmation prompts

### Individual Package Scripts

Use these when you need more control:

#### `apply_stow.sh` - Deploy Specific Package

```bash
./scripts/apply_stow.sh <package> [--restow]

# Examples:
./scripts/apply_stow.sh global                # Deploy dotfiles only
./scripts/apply_stow.sh $(hostname)           # Deploy host config only
./scripts/apply_stow.sh global --restow       # Redeploy (cleans old links)
```

**When to use `--restow`:**
- After deleting files
- After renaming files
- When in doubt (it's safer)

#### `unstow.sh` - Remove Package Symlinks

```bash
./scripts/unstow.sh <package>

# Remove in reverse order:
./scripts/unstow.sh $(hostname)  # Host first
./scripts/unstow.sh global       # Global last
```

### Utility Scripts

#### `list_packages.sh` - Show Available Configurations

```bash
./scripts/list_packages.sh
```

Shows all available hosts and packages.

#### `check_stow.sh` - Check for Conflicts

```bash
./scripts/check_stow.sh <package>

# Example:
./scripts/check_stow.sh $(hostname)
```

Check for conflicts before applying stow.

#### `show_links.sh` - Show Created Symlinks

```bash
./scripts/show_links.sh <package>

# Example:
./scripts/show_links.sh global
```

Shows all symlinks created by a package.

#### `backup_configs.sh` - Backup Conflicting Files

```bash
./scripts/backup_configs.sh <package> [--move]

# Examples:
./scripts/backup_configs.sh $(hostname)           # Backup (safe)
./scripts/backup_configs.sh $(hostname) --move    # Backup & remove originals
```

Backups stored in: `~/.config-backups/YYYYMMDD_HHMMSS_<package>/`

#### `validate_nix.sh` - Validate NixOS Config

```bash
./scripts/validate_nix.sh [-v]

# Example:
./scripts/validate_nix.sh -v  # Verbose output
```

Validates NixOS configuration without applying changes.

---

## 📚 Understanding the Structure

### Package Types

**`global/`** - Shared dotfiles across all hosts
- User dotfiles: .gitconfig, .tmux.conf
- Editor configs: .config/zed, .config/ghostty
- Tool configs: .config/lazygit

**`<hostname>/`** - Host-specific configurations
- NixOS system config: etc/nixos/configuration.nix
- Hardware config: etc/nixos/hardware-configuration.nix

### Repository Structure

```
.
├── scripts/              # Helper scripts
├── docs/
│   └── archive/         # Completed planning documents
├── global/              # Shared dotfiles
│   ├── etc/nixos/      # Shared NixOS configuration
│   │   ├── common.nix  # System configuration (393 lines)
│   │   └── neovim/     # Neovim plugin modules (4 files)
│   └── home/bagfen/    # User dotfiles
│       ├── dot-gitconfig
│       ├── dot-tmux.conf
│       └── dot-config/
│           ├── zed/
│           ├── ghostty/
│           └── lazygit/
├── crazy-diamond/       # Host: Desktop
│   └── etc/nixos/      # NixOS system config
└── thehand/            # Host: Laptop
    └── etc/nixos/      # NixOS system config
```

**Key Principles:**
- Stow uses `--dotfiles` flag: `dot-` prefix becomes `.`
- All user dotfiles belong in `global/`
- `<hostname>/` contains only NixOS system configuration
- `/etc/nixos` folder itself is NOT symlinked - only its contents

---

## 🎯 Common Workflows

### Scenario: Modify Existing File

```bash
# Edit file directly
vim global/home/bagfen/dot-gitconfig

# Changes take effect immediately (symlinks point to new content)
# No need to redeploy!
```

### Scenario: Add New Dotfile

```bash
# Add file
echo "alias ll='ls -la'" > global/home/bagfen/dot-bash_aliases

# Deploy
./scripts/rebuild_nixos.sh $(hostname) switch
```

### Scenario: Update NixOS System Config

```bash
# Edit config
vim crazy-diamond/etc/nixos/configuration.nix

# Test first (temporary, reverts on reboot)
./scripts/rebuild_nixos.sh crazy-diamond test

# If OK, apply permanently
./scripts/rebuild_nixos.sh crazy-diamond switch
```

### Scenario: System Maintenance

```bash
# Update all packages
sudo nix-channel --update
./scripts/rebuild_nixos.sh $(hostname) switch

# Clean up old generations
sudo nix-collect-garbage -d

# Search for packages
nix search <package-name>
```

### Scenario: Remove Everything

```bash
cd ~/nix-setup

# Remove all stow-managed symlinks
./scripts/unstow.sh $(hostname)  # Host config first
./scripts/unstow.sh global       # Global dotfiles last

# Verify
ls -la ~/.gitconfig  # Should not be a symlink
```

---

## ⚙️ Advanced: Manual Operations

### Manual Stow Commands

If you prefer not using helper scripts:

#### Deploy

```bash
cd ~/nix-setup

# Deploy global (shared dotfiles)
sudo stow -d . --dotfiles --target / global

# Deploy host-specific (NixOS config)
sudo stow -d . --dotfiles --target / $(hostname)

# Rebuild NixOS
sudo nixos-rebuild switch
```

#### Remove

```bash
cd ~/nix-setup

# Remove in reverse order
sudo stow -D -d . --dotfiles --target / $(hostname)
sudo stow -D -d . --dotfiles --target / global
```

#### Restow (Redeploy)

```bash
# Clean up old links and reapply
sudo stow -R -d . --dotfiles --target / global
```

### Manual NixOS Commands

```bash
# Test configuration (temporary)
sudo nixos-rebuild test

# Validate syntax only
sudo nixos-rebuild dry-build

# Apply permanently
sudo nixos-rebuild switch

# Rollback to previous generation
sudo nixos-rebuild switch --rollback
```

---

## 💻 NixOS Configuration Details

### Current Hosts

#### crazy-diamond (Desktop)
- **Hardware:** AMD Ryzen 7 7840HS, AMD Radeon 780M iGPU
- **Kernel:** Latest (`pkgs.linuxPackages_latest`)
- **Special:** AMD P-State EPP driver enabled
- **Desktop:** GNOME with GDM
- **Input:** fcitx5 with Chewing (Traditional Chinese)

#### thehand (Laptop)
- **Hardware:** Lenovo ThinkPad T14s
- **Bootloader:** systemd-boot
- **Desktop:** GNOME with GDM
- **Input:** fcitx5 with Chewing (Traditional Chinese)

### Using Unstable Packages

The configuration includes an `unstable` package set:

```nix
let
  unstable = import <unstable> { config = { allowUnfree = true; }; };
in
{
  environment.systemPackages = with pkgs; [
    # Stable packages
    git
    vim

    # Unstable packages
    unstable.some-package
  ];
}
```

---

## ⚠️ Important Notes

### Automatic Global Deployment

- `rebuild_nixos.sh` **automatically** deploys both `global` and `<hostname>` packages
- Global is deployed **first** (shared dotfiles)
- Hostname is deployed **second** (NixOS system config)
- No need to manually deploy `global` separately

### DO NOT Manually Create Symlinks

- ❌ DO NOT create symlinks inside `<hostname>/` pointing to `global/`
- ✅ Stow manages all symlinks automatically
- Each package is deployed separately

### DO NOT Modify

- `<hostname>/etc/nixos/hardware-configuration.nix` - Auto-generated by NixOS
- System state version (25.11) - Should not change after initial install

### Stow Behavior

- **Existing correct symlinks:** No conflict, stow recognizes them
- **Real files or wrong symlinks:** Conflict reported, requires backup/removal
- **After --restow:** Old broken links are automatically cleaned up

### Git Best Practices

- Commit changes before rebuilding (rebuild_nixos.sh will warn)
- Use descriptive commit messages
- Use `--skip-git-check` only when testing uncommitted changes

---

## 🔍 Troubleshooting

### Stow Conflicts

**Error:** "existing target is..."

**Solution:**
```bash
# Option 1: Automatic (recommended)
./scripts/backup_configs.sh <package> --move
./scripts/apply_stow.sh <package>

# Option 2: Manual
./scripts/backup_configs.sh <package>
sudo rm <conflicting-file>
./scripts/apply_stow.sh <package>
```

### NixOS Build Failures

**Error:** Configuration syntax errors

**Solution:**
```bash
# Validate first
./scripts/validate_nix.sh -v

# Check syntax manually
nix-instantiate --parse /etc/nixos/configuration.nix

# Rollback if needed
sudo nixos-rebuild switch --rollback
```

### Permission Issues

**Error:** "Permission denied"

**Cause:** System operations require sudo

**Solution:**
- Helper scripts handle sudo automatically
- For manual commands, use `sudo stow ...`
- User dotfile editing does NOT need sudo

### Broken Symlinks

**Check for broken symlinks:**
```bash
find ~ -type l ! -exec test -e {} \; -print 2>/dev/null
```

**Fix:**
```bash
# Redeploy packages
./scripts/apply_stow.sh global --restow
./scripts/apply_stow.sh $(hostname) --restow
```

---

## 📖 Quick Reference

### Key Configuration Files

- `global/home/bagfen/dot-gitconfig` - Git configuration with aliases
- `global/home/bagfen/dot-tmux.conf` - tmux configuration (prefix: C-a)
- `global/home/bagfen/dot-config/ghostty/config` - Ghostty terminal
- `global/home/bagfen/dot-config/zed/settings.json` - Zed editor
- `<hostname>/etc/nixos/configuration.nix` - NixOS system config

### Git Aliases (from .gitconfig)

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

### tmux Key Bindings (from .tmux.conf)

- Prefix: `C-a` (not default C-b)
- `prefix + r` - Reload config
- `prefix + |` - Split horizontally
- `prefix + -` - Split vertically
- `prefix + h/j/k/l` - Navigate panes (vim-style)
- `prefix + H/J/K/L` - Resize panes

---

## 🤝 Development

### For Developers (Claude)

See `CLAUDE.md` for detailed development guidelines and team roles.

### For Project Management (Gemini)

See `GEMINI.md` for project management guidelines and planning documentation.

---

## 📚 References

1. [mbledkowski/dotfiles](https://github.com/mbledkowski/dotfiles)
2. [~bwolf/dotfiles](https://sr.ht/~bwolf/dotfiles)
3. [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html)
4. [NixOS Manual](https://nixos.org/manual/nixos/stable/)

---

## 📄 License

Personal configuration repository. Use at your own risk.
