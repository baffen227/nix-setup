# Dotfiles Repository

Personal NixOS dotfiles managed with GNU Stow for multiple hosts.
 
## Quick Start

### NixOS Configuration Setup

#### Initial Setup

```bash
# Backup existing configuration files
# Keep /etc/nixos folder as stow only handles one layer of symlinks
sudo mv /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup
sudo mv /etc/nixos/hardware-configuration.nix /etc/nixos/hardware-configuration.nix.backup

# Add required channels
sudo nix-channel --add https://channels.nixos.org/nixos-25.11 nixos
sudo nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware 
sudo nix-channel --add https://channels.nixos.org/nixos-unstable unstable 
sudo nix-channel --update
```

#### Apply Configuration

```bash
# Apply configuration for current host
cd ~/nix-setup
sudo stow -d ~/nix-setup --dotfiles --target / $(hostname)

# Or specify host manually:
sudo stow -d ~/nix-setup --dotfiles --target / crazy-diamond
```

#### Update System

```bash
# Update channels and rebuild system
sudo nix-channel --update && sudo nixos-rebuild switch --upgrade && sudo nix-collect-garbage -d
```

#### Remove Configuration

```bash
# Remove symlinks
sudo stow -D -d ~/nix-setup --dotfiles --target / <hostname>
```

## Verification Commands

### Configuration Testing
```bash
# Test NixOS configuration (without switching)
sudo nixos-rebuild test

# Build configuration (without switching)
sudo nixos-rebuild build

# Dry-run configuration test
sudo nixos-rebuild dry-build
```

# References
1. https://github.com/mbledkowski/dotfiles
2. https://sr.ht/~bwolf/dotfiles
