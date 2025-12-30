# Common NixOS configuration shared across all hosts
# This module contains settings that are identical for both crazy-diamond and thehand

{ config, pkgs, ... }:

let
  unstable = import <unstable> { config = { allowUnfree = true; }; };
in
{
  # === NETWORKING ===
  networking.networkmanager.enable = true;

  # === TIME & LOCALE ===
  time.timeZone = "Asia/Taipei";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_TW.UTF-8";
    LC_IDENTIFICATION = "zh_TW.UTF-8";
    LC_MEASUREMENT = "zh_TW.UTF-8";
    LC_MONETARY = "zh_TW.UTF-8";
    LC_NAME = "zh_TW.UTF-8";
    LC_NUMERIC = "zh_TW.UTF-8";
    LC_PAPER = "zh_TW.UTF-8";
    LC_TELEPHONE = "zh_TW.UTF-8";
    LC_TIME = "zh_TW.UTF-8";
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-chewing
      fcitx5-gtk
    ];
  };

  # === DESKTOP ENVIRONMENT ===
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Excluding some GNOME applications from the default install
  # https://nixos.wiki/wiki/GNOME
  environment.gnome.excludePackages = with pkgs; [
    gnome-photos
    gnome-tour
    gnome-clocks
    gnome-contacts
    gnome-maps
    gnome-music
    gnome-weather
    gnome-calendar
    cheese # webcam tool
    epiphany # web browser
    geary # email reader
    totem # video player
    simple-scan # document scanner
    atomix # puzzle game
    hitori # sudoku game
    iagno # go game
    tali # poker game
    yelp
  ];

  # === PRINTING ===
  # Enable CUPS to print documents.
  services.printing.enable = true;

  # === AUDIO ===
  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # === FONTS ===
  # For fine grained Font control (can set a font per language!) see: https://nixos.wiki/wiki/Fonts
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-emoji-blob-bin
      source-code-pro
      font-awesome
      nerd-fonts.hack
    ];
    fontconfig = {
      defaultFonts = {
        emoji = [ "Noto Color Emoji" ];
        monospace = [
          "Hack Nerd Font Mono"
          "Source Code Pro"
          "Noto Sans Mono CJK TC"
          "DejaVu Sans Mono"
        ];
        sansSerif = [
          "Noto Sans CJK TC"
          "DejaVu Sans"
        ];
        serif = [
          "Noto Serif CJK TC"
          "DejaVu Serif"
        ];
      };
    };
  };

  # === SOFTWARE ===
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  programs = {
    # Install firefox.
    firefox.enable = true;

    # Enable appimage-run wrapper script and binfmt registration
    appimage = {
      # Whether to enable appimage-run wrapper script for executing appimages on NixOS.
      enable = true;
      # Whether to enable binfmt registration to run appimages via appimage-run seamlessly.
      binfmt = true;
    };

    # Enable nix-ld
    nix-ld.enable = true;

    # Tell nix-ld which common libraries to provide when encountering an unknown binary
    #nix-ld.libraries = with pkgs; [
    #  stdenv.cc.cc.lib
    #  zlib
    #  openssl
    #  # But usually the ones listed above, plus glibc (which is available by default), are sufficient
    #  # If that server needs more specific libraries, they might need to be added here
    #];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    cowsay # Program which generates ASCII pictures of a cow with a message
    eza # Modern, maintained replacement for ls
    file # Program that shows the type of files
    fzf # Command-line fuzzy finder written in Go
    gawk # GNU implementation of the Awk programming language
    git
    gnused # GNU sed, a batch stream editor
    gnutar # GNU implementation of the `tar' archiver
    gnupg # Modern release of the GNU Privacy Guard, a GPL OpenPGP implementation
    lazygit # Simple terminal UI for git commands
    neofetch # Fast, highly customizable system info script
    nnn #  Small ncurses-based file browser forked from noice
    ripgrep # Utility that combines the usability of The Silver Searcher with the raw speed of grep
    stow # Tool for managing the installation of multiple software packages in the same run-time directory tree
    tree # Command to produce a depth indented directory listing
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    which # Shows the full path of (shell) commands
    zstd # Zstandard real-time compression algorithm

    # it provides the command `nom` works just like `nix` with more details log output
    nix-output-monitor # Processes output of Nix commands to show helpful and pretty information

    # archives
    p7zip # New p7zip fork with additional codecs and improvements (forked from https://sourceforge.net/projects/p7zip/)
    unzip # Extraction utility for archives compressed in .zip format
    rar # Utility for RAR archives
    xz # General-purpose data compression software, successor of LZMA
    zip # Compressor/archiver for creating and modifying zipfiles

    # Markdown, JSON, YAML procesors
    glow # Render markdown on the CLI, with pizzazz!
    jq # A lightweight and flexible command-line JSON processor
    yq-go # Portable command-line YAML processor, https://github.com/mikefarah/yq

    # monitors and tracers
    btop # Monitor of resources, replacement of htop/nmon
    iftop # Display bandwidth usage on a network interface
    iotop # Tool to find out the processes doing the most IO
    lsof # Tool to list open files
    ltrace # Library call tracer
    strace # System call tracer for Linux

    # system tools
    ethtool # Utility for controlling network drivers and hardware
    lm_sensors # Tools for reading hardware sensors, for `sensors` command
    pciutils # Collection of programs for inspecting and manipulating configuration of PCI devices, such as lspci
    sysstat # Collection of performance monitoring tools for Linux (such as sar, iostat and pidstat)
    usbutils # Tools for working with USB devices, such as lsusb

    # Install Input Method Panel GNOME Shell Extensions to provide the input method popup.
    gnomeExtensions.kimpanel
    # Install Gnome Tweaks for remapping CapsLock to Ctrl
    gnome-tweaks

    # fonts
    ttf-tw-moe # Set of KAI and SONG fonts from the Ministry of Education of Taiwan
  ];

  # === USERS ===
  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.bagfen = {
    isNormalUser = true;
    description = "bagfen";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # === STATE VERSION ===
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
