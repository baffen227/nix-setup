{ pkgs }:

with pkgs.vimPlugins; {
  # Essential plugins
  essential = [
    vim-sensible
    vim-sleuth
  ];

  # Navigation and search
  navigation = [
    telescope-nvim
    telescope-fzf-native-nvim
    nvim-web-devicons
    nvim-tree-lua
  ];

  # Git integration
  git = [
    gitsigns-nvim
    vim-fugitive
  ];

  # Language support
  language = [
    nvim-treesitter.withAllGrammars
    vim-nix
  ];

  # LSP and completion
  lsp = [
    nvim-lspconfig
    nvim-cmp
    cmp-nvim-lsp
    cmp-buffer
    cmp-path
    cmp-cmdline
    luasnip
    cmp_luasnip
  ];

  # UI and theming
  ui = [
    lualine-nvim
    catppuccin-nvim
    indent-blankline-nvim
  ];

  # Utilities
  utilities = [
    comment-nvim
    nvim-autopairs
    which-key-nvim
  ];

  # TODO: Future integrations
  # integrations = [
  #   claude-code-nvim
  # ];
}