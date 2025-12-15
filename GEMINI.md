# GEMINI.md

## Directory Overview

This directory contains personal NixOS dotfiles. It is structured to manage configurations for multiple hosts using `stow`. The main goal is to version control the entire system configuration, from the operating system to application settings.

The configuration is split into two main parts:
- `global`: Contains configurations that are shared across all hosts.
- `crazy-diamond`: Contains host-specific configurations.

This setup allows for a reproducible and version-controlled system environment.

## Key Files

-   **`README.txt`**: The main entry point for understanding the repository. It contains instructions on how to set up, apply, and update the NixOS configuration using `stow`.

-   **`crazy-diamond/etc/nixos/configuration.nix`**: The main NixOS configuration file for the host `crazy-diamond`. It defines the system's hardware, services, packages, and user settings.

-   **`global/home/bagfen/dot-gitconfig`**: The global git configuration, defining user information, aliases, and editor settings.

-   **`global/home/bagfen/dot-tmux.conf`**: The configuration for the `tmux` terminal multiplexer, including keybindings and visual styling.

-   **`crazy-diamond/home/bagfen/dot-config/ghostty/config`**: Configuration for the Ghostty terminal emulator.

-   **`crazy-diamond/home/bagfen/dot-config/lazygit/config.yml`**: Configuration for `lazygit`, a terminal UI for git.

-   **`crazy-diamond/home/bagfen/dot-config/zed/settings.json`**: Configuration for the Zed code editor.

## Usage

The primary way to interact with this repository is through `stow` and `nixos-rebuild`.

### Applying Configuration

To apply the configuration for a specific host, you would use the `stow` command. For example, for the host `crazy-diamond`:

```bash
sudo stow -d ~/nix-setup --dotfiles --target / crazy-diamond
```

### Updating the System

To update the system with the latest configuration:

```bash
sudo nix-channel --update && sudo nixos-rebuild switch --upgrade && sudo nix-collect-garbage -d
```

### Testing Configuration

To test the configuration without applying it:

```bash
sudo nixos-rebuild test
```
