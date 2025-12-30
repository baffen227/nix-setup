# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      # --- Common configuration shared across all hosts ---
      /etc/nixos/common.nix

      # --- Hardware Configuration ---
      <nixos-hardware/lenovo/thinkpad/t14s>
    ];

  # Firmware Updates (TBD)
  # Enable firmware update via fwupd (supports your BIOS version N3VET59W).
  # services.fwupd.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "thehand"; # Define your hostname.
}
