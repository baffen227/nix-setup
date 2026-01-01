''
  lua << EOF
    -- nvim-tree setup
    require("nvim-tree").setup()

    -- telescope setup
    require("telescope").setup()

    -- lualine setup
    require("lualine").setup()

    -- treesitter setup
    require("nvim-treesitter.configs").setup({
      highlight = { enable = true },
      indent = { enable = true },
    })

    -- gitsigns setup
    require("gitsigns").setup()

    -- comment setup
    require("Comment").setup()

    -- autopairs setup
    require("nvim-autopairs").setup()

    -- which-key setup
    require("which-key").setup()

    -- TODO: claude-code setup
    -- require("claude-code").setup()

    -- catppuccin setup
    require("catppuccin").setup()
    vim.cmd.colorscheme "catppuccin"

    -- nvim-cmp setup
    local cmp = require("cmp")
    cmp.setup({
      snippet = {
        expand = function(args)
          require("luasnip").lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" },
      }, {
        { name = "buffer" },
      })
    })
  EOF
''