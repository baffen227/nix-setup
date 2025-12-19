# Nix Flakes 遷移評估與計畫

**日期:** 2025-12-19
**狀態:** 規劃中 (Proposed)

## 1. 評估結論：非常可行且強烈推薦 (Highly Feasible & Recommended)

針對目前的 `nix-setup` 架構（Host 分離、模組化），這是最適合遷移至 Nix Flakes 的型態。遷移後，系統將獲得更高的可重現性，且依賴管理會更簡單。

### 為什麼要遷移？ (Benefits)

1.  **鎖定依賴 (Lockfile)**：目前依賴 `nix-channel` (stateful)。如果 `unstable` 頻道更新導致套件損壞，`nixos-rebuild` 可能會失敗。Flake 使用 `flake.lock` 檔案，確保每次重建都使用完全相同的版本，直到主動執行 `nix flake update`。
2.  **消除 `<...>` 語法**：目前的 `configuration.nix` 使用 `import <unstable>` 和 `<nixos-hardware/...>`，這依賴於 root 用戶的頻道狀態。Flake 將這些定義為明確的 "Inputs"，無需再手動管理頻道。
3.  **統一管理**：可以在一個 `flake.nix` 檔案中定義所有主機 (`crazy-diamond`, `thehand`) 的入口點。

---

## 2. 遷移計畫 (Migration Plan)

建議分兩階段進行，以降低風險：

-   **階段一：系統配置 Flake 化** (保留 `stow` 管理 dotfiles) -> **目前建議執行此階段**
-   **階段二 (可選/未來)：引入 Home Manager** (取代 `stow`)

### 階段一實作步驟

#### 步驟 1: 新增 `flake.nix`

在 `~/nix-setup/` 根目錄建立 `flake.nix`：

```nix
{
  description = "NixOS Configuration Flake";

  inputs = {
    # 穩定版 (對應目前的 nixos-25.11)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    # Unstable 版 (對應目前的 import <unstable>)
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # 硬體配置 (對應 <nixos-hardware>)
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixos-hardware, ... }@inputs:
    let
      system = "x86_64-linux";
      
      # 設定 overlay 以便在所有模組中都能方便存取 unstable packages
      overlay-unstable = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };
    in
    {
      nixosConfigurations = {
        # Host: crazy-diamond
        "crazy-diamond" = nixpkgs.lib.nixosSystem {
          inherit system;
          
          # 將所有 inputs 傳入模組，讓 configuration.nix 可以使用
          specialArgs = { inherit inputs; };
          
          modules = [
            # 載入 overlays
            ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-unstable ]; })
            
            # 引入硬體模組 (取代原本的 <nixos-hardware/...>)
            nixos-hardware.nixosModules.common-pc-laptop
            nixos-hardware.nixosModules.common-pc-ssd
            nixos-hardware.nixosModules.common-cpu-amd
            nixos-hardware.nixosModules.common-gpu-amd

            # 主設定檔
            ./crazy-diamond/etc/nixos/configuration.nix
          ];
        };
      };
    };
}
```

#### 步驟 2: 修改 `configuration.nix`

修改 `crazy-diamond/etc/nixos/configuration.nix` 以移除對頻道的依賴：

```nix
# 修改前:
# { config, pkgs, ... }:
# let
#   unstable = import <unstable> { config = { allowUnfree = true; }; };
# in
# {
#   imports = [ <nixos-hardware/...> ... ];
#   ...
#   environment.systemPackages = [ unstable.some-package ];
# }

# 修改後 (Flake 版):
{ config, pkgs, ... }: # pkgs 現在已經包含透過 overlay 注入的 unstable

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      
      # 注意：<nixos-hardware/...> 的 import 都要移除
      # 因為它們已經在 flake.nix 的 modules 中被引入了
    ];

  # ... 其他設定保持不變 ...

  # 使用 unstable 套件的方式 (因為我們在 overlay 定義了 unstable)
  # environment.systemPackages = [ pkgs.unstable.some-package ]; 
}
```

#### 步驟 3: 應用變更

使用新的 flake 指令來重建系統：

```bash
# 測試建置
nix build .#nixosConfigurations.crazy-diamond.config.system.build.toplevel

# 應用變更
sudo nixos-rebuild switch --flake .#crazy-diamond
```
