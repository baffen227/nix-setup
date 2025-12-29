# Refactoring Plan: Modularizing NixOS Configuration

**Date:** 2025-12-29
**Author:** Gemini (Project Manager)
**Target Audience:** Claude (Technical Engineer)

## Objective
Eliminate code duplication between `crazy-diamond` and `thehand` by extracting shared configuration into a common module. This aligns with the "DRY" principle and leverages our `stow` architecture where multiple source directories merge into `/etc/nixos/`.

## Technical Review (Claude)

**Reviewer:** Claude (Technical Engineer)
**Review Date:** 2025-12-29
**Status:** ✅ Plan Approved with Minor Amendments

### Code Duplication Analysis

After comparing both configuration files:
- **Duplication Level:** ~80% of code is identical between hosts
- **Total Shared Lines:** Approximately 200+ lines of identical configuration
- **Shared Components:** Time/Locale, Desktop Environment, Fonts, Packages, Users, Programs

**Completely Duplicate Sections:**
- Time zone, i18n settings, fcitx5 input method (lines 36-95)
- GNOME desktop environment setup (lines 98-127)
- PipeWire audio configuration (lines 114-127)
- User account configuration (lines 98-105)
- System package list (~60 packages, lines 137-195)
- Font configuration (Noto, Hack Nerd Font, lines 198-228)
- GNOME excluded packages list (lines 232-251)
- Programs: firefox, appimage, nix-ld (lines 107-130)
- State version 25.11

**Host-Specific Differences:**

`crazy-diamond`:
- nixos-hardware modules: laptop, ssd, amd cpu/gpu
- AMD-specific: `boot.kernelParams = [ "amd_pstate=active" ]`
- `boot.kernelPackages = pkgs.linuxPackages_latest`
- `hardware.graphics` configuration
- `services.fwupd.enable = true`

`thehand`:
- nixos-hardware module: lenovo/thinkpad/t14s
- Standard kernel (no special parameters)
- Commented-out fwupd

### Critical Findings

**⚠️ Items Missing from Original Plan:**

1. **`networking.networkmanager.enable`**
   - Present in both hosts (line 68 in crazy-diamond, line 33 in thehand)
   - **Must be moved to common.nix** as it's shared configuration
   - Critical for network connectivity

2. **`let unstable = ...` Block**
   - Both files define unstable package set (lines 7-9)
   - **Must be included in common.nix** header
   - Required for `nixpkgs.config.allowUnfree` context

3. **`security.rtkit.enable`**
   - Present in both hosts (line 115 in crazy-diamond, line 80 in thehand)
   - Required for PipeWire, should be in common.nix

### Feasibility Assessment

**✅ Plan Strengths:**
1. Correctly identifies shared configuration sections
2. Leverages stow mechanism effectively (symlinks coexist in /etc/nixos/)
3. Uses standard NixOS imports mechanism
4. Verification workflow is sound
5. Maintains hardware-specific separation

**✅ Technical Validation:**
- Approach aligns with NixOS best practices
- Compatible with current stow-based architecture
- Future-friendly for Flake migration
- Not over-engineered: simple and direct

**🔧 Required Amendments:**
1. Add `networking.networkmanager.enable` to common.nix
2. Add `let unstable = ...` block to common.nix header
3. Add `security.rtkit.enable` to common.nix
4. Update verification step 4 to specifically check networkmanager

### Recommended Improvements

**Enhanced common.nix Structure:**
```nix
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
  i18n.extraLocaleSettings = { ... };
  i18n.inputMethod = { fcitx5 configuration };

  # === DESKTOP ENVIRONMENT ===
  services.xserver = { enable, xkb config };
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = [ ... ];

  # === AUDIO ===
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = { complete configuration };

  # === PRINTING ===
  services.printing.enable = true;

  # === FONTS ===
  fonts = { packages, fontconfig };

  # === SOFTWARE ===
  nixpkgs.config.allowUnfree = true;
  programs = { firefox, appimage, nix-ld };
  environment.systemPackages = [ full package list ];

  # === USERS ===
  users.users.bagfen = { ... };

  # === STATE VERSION ===
  system.stateVersion = "25.11";
}
```

**Simplified Host Configurations:**

After refactoring, each host should contain only:
- 15-30 lines (down from ~280 lines)
- Hardware-specific imports and settings
- Bootloader configuration
- Hostname
- Hardware optimizations (kernel, graphics, etc.)

### Alternative Approaches Considered

❌ **Absolute Path Imports:** Would break stow structure
❌ **Multi-layer Module Nesting:** Over-complicated for 2 hosts
❌ **Maintain Status Quo:** Violates DRY principle
✅ **Proposed Approach:** Optimal for current architecture

### Conclusion

**Recommendation:** Approve plan with amendments listed above.

The refactoring plan is **technically sound and represents best practice** for the current stow-based architecture. With the three critical additions (networkmanager, unstable block, rtkit), this approach will:
- Reduce code duplication by ~80%
- Improve maintainability significantly
- Align with NixOS conventions
- Facilitate future Flake migration

**Estimated Impact:**
- `common.nix`: ~200 lines
- `crazy-diamond/configuration.nix`: ~25 lines (was 315)
- `thehand/configuration.nix`: ~20 lines (was 280)

## Architecture Change

### Current State
*   `crazy-diamond/etc/nixos/configuration.nix`: Contains ALL settings.
*   `thehand/etc/nixos/configuration.nix`: Contains ALL settings (mostly identical).

### Target State
*   `global/etc/nixos/common.nix`: Contains shared settings (Time, Locale, UI, Packages, Users).
*   `<hostname>/etc/nixos/configuration.nix`: Contains ONLY hardware specifics, bootloader, and hostname.

**Mechanism:**
Since `stow` symlinks files from both `global/etc/nixos/` and `<hostname>/etc/nixos/` into the system's `/etc/nixos/` directory, they will sit side-by-side. Thus, `configuration.nix` can import `./common.nix` using a relative path.

## Execution Steps

### 1. Create Common Module
**File:** `global/etc/nixos/common.nix`
**Action:** Create this file containing the following shared blocks:

**⚠️ IMPORTANT:** File must start with the unstable package import:
```nix
{ config, pkgs, ... }:

let
  unstable = import <unstable> { config = { allowUnfree = true; }; };
in
{
  # Configuration sections below...
}
```

*   **Networking:** ⚠️ ADDED (Critical)
    *   `networking.networkmanager.enable = true`
*   **System Basics:**
    *   `time.timeZone` ("Asia/Taipei")
    *   `i18n.defaultLocale` & `i18n.extraLocaleSettings`
    *   `i18n.inputMethod` (fcitx5)
    *   `services.xserver.xkb` layout
*   **Desktop Environment:**
    *   `services.xserver.enable`
    *   `services.displayManager.gdm`
    *   `services.desktopManager.gnome`
    *   `environment.gnome.excludePackages`
    *   `services.printing.enable`
*   **Audio:** ⚠️ UPDATED
    *   `services.pulseaudio.enable = false`
    *   `security.rtkit.enable = true` (Added - required for PipeWire)
    *   `services.pipewire` (complete configuration)
*   **Fonts:**
    *   `fonts.packages` & `fonts.fontconfig`
*   **Software:**
    *   `nixpkgs.config.allowUnfree = true`
    *   `programs.firefox`, `programs.appimage`, `programs.nix-ld`
    *   `environment.systemPackages` (The entire list of CLI tools: git, vim, fzf, etc.)
*   **Users:**
    *   `users.users.bagfen` configuration
*   **State Version:**
    *   `system.stateVersion = "25.11"`

### 2. Refactor Host Configurations

**File:** `crazy-diamond/etc/nixos/configuration.nix`
**Action:** Remove above sections and add `imports = [ ./common.nix ];`.
**Keep:**
*   Imports: `hardware-configuration.nix` and `nixos-hardware` modules.
*   Import: `./common.nix` (Add this to imports list)
*   Bootloader: `boot.loader.*`
*   Kernel: `boot.kernelParams`, `boot.kernelPackages`
*   Hardware-specifics: `hardware.graphics`, `services.fwupd`
*   Networking: `networking.hostName` (ONLY hostname, not networkmanager)

**File:** `thehand/etc/nixos/configuration.nix`
**Action:** Remove above sections and add `imports = [ ./common.nix ];`.
**Keep:**
*   Imports: `hardware-configuration.nix` and `nixos-hardware` modules.
*   Import: `./common.nix` (Add this to imports list)
*   Bootloader: `boot.loader.*`
*   Networking: `networking.hostName` (ONLY hostname, not networkmanager)

**⚠️ CRITICAL - Do NOT keep in host configs:**
*   ❌ `networking.networkmanager.enable` (now in common.nix)
*   ❌ `let unstable = ...` block (now in common.nix)
*   ❌ Any desktop, audio, font, or package configuration (all in common.nix)

### 3. Verification Protocol

1.  **Ensure Directory Exists:**
    ```bash
    mkdir -p global/etc/nixos
    ```
2.  **Apply Stow:**
    Ensure `scripts/apply_stow.sh` (or manual `stow`) links the new `common.nix`.
    *Check:* `ls -l /etc/nixos/common.nix` should exist after stowing.
3.  **Dry Build:**
    Run `sudo nixos-rebuild dry-build` on the current host (`crazy-diamond`).
4.  **Critical Configuration Review:**
    Verify these essential settings are present in common.nix:
    - ✅ `networking.networkmanager.enable = true`
    - ✅ `security.rtkit.enable = true`
    - ✅ `let unstable = ...` block at the top
    - ✅ PipeWire audio configuration complete
    - ✅ GNOME desktop environment settings
5.  **Host Configuration Check:**
    Verify host configs do NOT contain:
    - ❌ Any desktop/audio/font configuration
    - ❌ `networking.networkmanager.enable`
    - ❌ `let unstable = ...` block
6.  **Functional Test (after dry-build passes):**
    ```bash
    sudo nixos-rebuild test  # Temporary switch for testing
    # Verify network works, desktop loads, audio works
    # If issues found, rollback: sudo nixos-rebuild switch --rollback
    ```

## Task Assignment & Status

**Original Plan:** Gemini (Project Manager) - ✅ COMPLETED
**Technical Review:** Claude (Technical Engineer) - ✅ COMPLETED
**Status:** ✅ APPROVED FOR EXECUTION

### Next Steps

1. **PM Gemini:** Review the technical amendments and approve/reject plan (Done)
2. **Claude:** Implement refactoring:
   - Create `global/etc/nixos/common.nix` with all shared configuration
   - Refactor `crazy-diamond/etc/nixos/configuration.nix` (remove duplicates)
   - Refactor `thehand/etc/nixos/configuration.nix` (remove duplicates)
   - Execute verification protocol
   - Test on crazy-diamond first, then thehand

### Implementation Notes for Claude

**When implementing:**
- Start with crazy-diamond (current host) for safer testing
- Use `nixos-rebuild dry-build` first, then `test` mode
- Keep backup of original configuration.nix files
- Only run `switch` after successful testing
- Document any issues encountered during migration

**Risk Mitigation:**
- Low risk: Changes are additive (imports) and subtractive (moving code)
- Rollback available via `--rollback` flag
- Test mode allows temporary switch before committing
- Original files preserved in git history