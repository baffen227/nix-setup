# Flake 重構計畫：仿 HLISSNER 模組化架構

## 核心目標
將 `nix-setup` 從「Stow + 標準 NixOS 配置」遷移至「基於 Flake 的高度模組化框架」。此架構參考自 `/home/bagfen/doomemacs_related_repos/dotfiles` (hlissner/dotfiles)。

## 新預期結構 (Target Architecture)
```
/home/bagfen/nix-setup/
├── flake.nix             # 新的入口點
├── lib/                  # 從參考專案複製的核心庫
├── bin/                  # 管理腳本
├── hosts/                # 主機定義 (crazy-diamond, thehand)
├── modules/              # 功能模組 (desktop, editors, shell, system)
└── config/               # 靜態配置文件 (原 dotfiles 內容)
```

## 執行階段 (Phases)

### Phase 1: 基礎建設 (Infrastructure)
1. **複製核心庫**：從 `/home/bagfen/doomemacs_related_repos/dotfiles/lib` 複製到本專案。
2. **建立 Flake 入口**：建立 `flake.nix` 並設定 inputs。
3. **初始化模組加載器**：建立 `modules/default.nix`。

### Phase 2: 模組遷移 (Module Migration)
將原本分散在 `dotfiles/` 與 `global/` 的配置封裝為模組：
1. **Shell 模組**：`modules/shell/git.nix`, `modules/shell/tmux.nix`, `modules/shell/zsh.nix`。
2. **Editors 模組**：`modules/editors/neovim.nix`, `modules/editors/zed.nix`。
3. **Desktop 模組**：`modules/desktop/gnome.nix`, `modules/desktop/fonts.nix`。
4. **System 模組**：`modules/system/utils.nix` (包含常用 CLI 工具)。

### Phase 3: 主機遷移 (Host Migration)
1. **Crazy-Diamond**：建立 `hosts/crazy-diamond/default.nix`，使用 `modules = { ... }` 語法啟用對應功能。
2. **Thehand**：建立 `hosts/thehand/default.nix`。
3. **硬體配置**：保留並整合 `hardware-configuration.nix`。

### Phase 4: 驗證與清理
1. 使用 `nixos-rebuild dry-build --flake .#<hostname>` 驗證。
2. 驗證通過後，正式移除舊有的 Stow 結構與 `global/` 目錄。

## 關鍵技術優勢
- **高度抽象**：主機配置文件將縮減至 100 行以內，僅需聲明「要開啟哪些功能」。
- **自動化**：透過自定義 `lib` 自動偵測並加載 `hosts/` 下的所有主機。
- **純 Nix 管理**：完全擺脫對外部工具 (Stow) 的依賴，達成 100% 聲明式管理。

---
**備註**：此計畫由 Gemini (PM) 制定，待執行時將由 Claude (Technical Engineer) 負責具體實作。
**日期**：2025-12-24
