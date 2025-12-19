# 遷移計劃：將 dotfiles/ 配置整合到純 NixOS configuration.nix + home-manager

## 用戶選擇

- **簡化目標**：所有配置都在單一 configuration.nix 文件中
- **home-manager**：可以使用
- **遷移範圍**：全部遷移

---

## 實作方案

使用 **home-manager 作為 NixOS module**，將所有系統配置和用戶 dotfiles 整合到單一 configuration.nix。

### 最終結構

```
/home/bagfen/nix-setup/
├── thehand/
│   └── etc/nixos/
│       ├── configuration.nix      # 唯一需要維護的文件（約 600-800 行）
│       └── hardware-configuration.nix  # 自動生成，不動
├── crazy-diamond/
│   └── etc/nixos/
│       ├── configuration.nix      # 同上
│       └── hardware-configuration.nix
├── CLAUDE.md
├── GEMINI.md
└── README.md

# 刪除的內容：
# - global/ 目錄（所有 dotfiles 移入 configuration.nix）
# - <hostname>/home/ 目錄（不再需要 Stow 管理的 dotfiles）
```

---

## 詳細實作步驟

### 步驟 1：添加 home-manager 到 configuration.nix

```nix
{ config, pkgs, ... }:

let
  unstable = import <unstable> { config = { allowUnfree = true; }; };
  home-manager = builtins.fetchTarball
    "https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz";
in
{
  imports = [
    ./hardware-configuration.nix
    (import "${home-manager}/nixos")
  ];

  # ... 系統配置 ...

  home-manager.users.bagfen = { pkgs, ... }: {
    # 用戶配置在這裡
  };
}
```

### 步驟 2：遷移 Git 配置

從 `dotfiles/global/home/bagfen/dot-gitconfig` 轉換為：

```nix
home-manager.users.bagfen = { pkgs, ... }: {
  programs.git = {
    enable = true;
    userName = "Harry Chen";
    userEmail = "baffen227@gmail.com";
    extraConfig = {
      core = {
        editor = "nvim";
        autocrlf = "input";
        safecrlf = true;
        quotepath = false;
      };
      push = {
        default = "simple";
        autoSetupRemote = true;
      };
      pull.rebase = false;
      init.defaultBranch = "main";
      diff = {
        tool = "vimdiff";
        colorMoved = "default";
      };
      merge = {
        tool = "vimdiff";
        conflictstyle = "diff3";
      };
      color = {
        ui = "auto";
        branch = "auto";
        diff = "auto";
        status = "auto";
      };
      "color \"diff\"" = {
        meta = "yellow bold";
        frag = "magenta bold";
        old = "red bold";
        new = "green bold";
      };
    };
    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      df = "diff";
      lg = "log --oneline --graph --decorate";
      last = "log -1 HEAD";
      unstage = "reset HEAD --";
      visual = "!gitk";
    };
  };
};
```

### 步驟 3：遷移 tmux 配置

從 `dotfiles/global/home/bagfen/dot-tmux.conf` 轉換為：

```nix
programs.tmux = {
  enable = true;
  prefix = "C-a";
  escapeTime = 1;
  baseIndex = 1;
  mouse = false;
  terminal = "screen-256color";
  extraConfig = ''
    # 完整的 tmux 配置內容（約 80 行）
    # ... 直接嵌入現有的 .tmux.conf 內容 ...
  '';
};
```

### 步驟 4：遷移其他 dotfiles

使用 `xdg.configFile` 管理不支援 home-manager 模組的應用：

```nix
# Zed Editor
xdg.configFile."zed/settings.json".text = ''
  {
    "agent": { ... },
    "theme": { ... },
    ...
  }
'';

xdg.configFile."zed/keymap.json".text = ''
  [ ... ]
'';

# Ghostty
xdg.configFile."ghostty/config".text = ''
  cursor-style = block
  theme = MaterialDarker
  font-family = Hack Nerd Font Mono
  font-size = 13
  ...
'';

# Lazygit
programs.lazygit = {
  enable = true;
  settings = {
    git = {
      fetchAll = false;
      log.order = "default";
    };
    gui.theme = {
      activeBorderColor = [ "blue" "bold" ];
      selectedLineBgColor = [ "white" ];
    };
  };
};
```

### 步驟 5：整合 Neovim 配置

從 `dotfiles/global/etc/nixos/packages/editors/neovim.nix` 及其子模組整合：

```nix
programs.neovim = {
  enable = true;
  defaultEditor = true;
  viAlias = true;
  vimAlias = true;
  configure = {
    customRC = ''
      " Settings (from options.nix)
      syntax enable
      set number hlsearch tabstop=4 shiftwidth=4 expandtab
      ...

      " Keymaps (from keymaps/default.nix)
      let mapleader = " "
      nnoremap <leader>h :nohlsearch<CR>
      ...

      " Plugin configs (from plugins/configs.nix)
      lua << EOF
        require("nvim-tree").setup()
        require("telescope").setup()
        ...
      EOF
    '';
    packages.myVimPackage = {
      start = with pkgs.vimPlugins; [
        vim-sensible vim-sleuth
        telescope-nvim telescope-fzf-native-nvim nvim-web-devicons nvim-tree-lua
        gitsigns-nvim vim-fugitive
        nvim-treesitter.withAllGrammars vim-nix
        nvim-lspconfig nvim-cmp cmp-nvim-lsp cmp-buffer cmp-path cmp-cmdline luasnip cmp_luasnip
        lualine-nvim catppuccin-nvim indent-blankline-nvim
        comment-nvim nvim-autopairs which-key-nvim
      ];
    };
  };
};
```

### 步驟 6：整合系統套件

從 dotfiles/ 的各個 packages/*.nix 合併：

```nix
environment.systemPackages = with pkgs; [
  # 從 common.nix
  cowsay eza file fzf gawk git gnused gnutar gnupg lazygit neofetch nnn
  ripgrep stow tree wget which zstd nix-output-monitor
  p7zip unzip rar xz zip
  glow jq yq-go
  btop iftop iotop lsof ltrace strace
  ethtool lm_sensors pciutils sysstat usbutils

  # 從 dev.nix
  unstable.claude-code docker-compose hoppscotch
  nil nixd nixfmt-rfc-style nixpkgs-fmt
  saleae-logic-2

  # 從 tools.nix
  element-desktop ghostty ffmpeg flameshot foliate libreoffice-fresh vlc
  nettools gparted mkcert xorg.xeyes

  # 從 gnome.nix
  gnomeExtensions.kimpanel gnome-tweaks

  # 從 fonts.nix
  ttf-tw-moe
];
```

### 步驟 7：更新 state version

將 `system.stateVersion` 保持為 `"25.11"`（目前 nix-setup 使用的版本）。

---

## 主機差異處理

### thehand (ThinkPad T14s)

```nix
imports = [
  <nixos-hardware/lenovo/thinkpad/t14s>
  ./hardware-configuration.nix
  (import "${home-manager}/nixos")
];
```

### crazy-diamond (ThinkPad P16v)

```nix
imports = [
  <nixos-hardware/common/pc/laptop>
  <nixos-hardware/common/pc/ssd>
  <nixos-hardware/common/cpu/amd>
  <nixos-hardware/common/gpu/amd>
  ./hardware-configuration.nix
  (import "${home-manager}/nixos")
];

boot.kernelParams = [ "amd_pstate=active" ];
boot.kernelPackages = pkgs.linuxPackages_latest;
services.fwupd.enable = true;
```

---

## 清理工作

完成遷移後：

1. 刪除 `global/` 目錄
2. 刪除 `<hostname>/home/` 目錄
3. 刪除不再需要的 Stow 相關文件
4. 更新 CLAUDE.md 和 GEMINI.md 說明新的配置方式
5. （可選）保留 dotfiles/ 作為參考或歸檔

---

## 預期結果

- **單一配置文件**：每台主機只需維護一個 configuration.nix（約 600-800 行）
- **不需要 Stow**：所有 dotfiles 由 home-manager 管理
- **聲明式管理**：Git、tmux、lazygit 等使用 home-manager 模組
- **純 NixOS**：完全使用 Nix 生態系統

---

## 要修改的文件

- `thehand/etc/nixos/configuration.nix` - 完全重寫（~600-800 行）
- `crazy-diamond/etc/nixos/configuration.nix` - 完全重寫（~600-800 行）
- `CLAUDE.md` - 更新說明文檔
- `GEMINI.md` - 更新說明文檔

## 要刪除的目錄

- `global/` - dotfiles 移入 configuration.nix 後不再需要
- `thehand/home/` - 不再需要 Stow 管理的 dotfiles
- `crazy-diamond/home/` - 不再需要 Stow 管理的 dotfiles
