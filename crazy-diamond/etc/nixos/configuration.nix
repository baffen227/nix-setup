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

      # --- Basic Common Laptop Configuration ---
      <nixos-hardware/common/pc/laptop>
      <nixos-hardware/common/pc/ssd>

      # --- CPU Configuration ---
      # For AMD Ryzen Processors.
      <nixos-hardware/common/cpu/amd>
      # Enable AMD P-State driver.
      # This is crucial for Ryzen 7000 series (like your 7840HS) to achieve better power efficiency.
      # <nixos-hardware/common/cpu/amd/pstate> # comment out for that `sudo nixos-rebuild test` failed

      # --- GPU Configuration ---
      # For AMD Radeon 780M (Phoenix architecture iGPU).
      # This enables VAAPI (Video Hardware Decoding) and OpenCL support.
      <nixos-hardware/common/gpu/amd>
    ];

  # --- Additional Recommendations ---

  # --- CPU Power Management ---
  # Enable AMD P-STATE EPP (Energy Performance Preference) driver manually.
  # This replaces the failing pstate module import.
  # "amd_pstate=active" is the recommended mode for modern Ryzen CPUs (Zen 3/4).
  boot.kernelParams = [ "amd_pstate=active" ];

  # 1. Kernel Selection
  # Ryzen 7000 series / Radeon 780M requires a newer kernel for optimal performance and stability.
  # While NixOS 25.11 is new, explicitly using the latest stable kernel is recommended for this hardware.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # 2. Firmware Updates
  # Enable firmware update via fwupd (supports your BIOS version N3VET59W).
  services.fwupd.enable = true;

  # 3. Graphics Acceleration
  # Verify that hardware acceleration is enabled for the Radeon 780M.
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Support 32-bit applications (e.g., Steam).
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "crazy-diamond"; # Define your hostname.
}
