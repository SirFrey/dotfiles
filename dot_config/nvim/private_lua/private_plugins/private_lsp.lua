return {
  -- Lua dev helpers (lazydev replaces deprecated neodev)
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {},
  },

  -- LSP + Mason integration
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      -- Mason installer
      { "mason-org/mason.nvim", opts = {} },
      -- Provides default server configs for vim.lsp.config
      "neovim/nvim-lspconfig",
      "b0o/schemastore.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "pylsp", "pyright", "lua_ls", "rust_analyzer", "tailwindcss", "ts_ls", "jsonls" },
        -- Automatically calls vim.lsp.enable() for all installed servers
        automatic_enable = true,
      })

      require("mason-tool-installer").setup({
        ensure_installed = {
          "prettierd", -- prettier formatter
          "stylua", -- lua formatter
          "isort", -- python formatter
          "black", -- python formatter
          "pylint", -- python linter
          "eslint_d", -- js linter
        },
      })

      -- Shared capabilities for all servers (Neovim 0.11+ native API)
      vim.lsp.config("*", {
        capabilities = {
          textDocument = {
            completion = {
              completionItem = {
                snippetSupport = true,
              },
            },
          },
        },
      })

      -- JSON with schemastore
      vim.lsp.config("jsonls", {
        settings = {
          json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true },
          },
        },
      })

      -- Tailwind CSS
      vim.lsp.config("tailwindcss", {
        root_markers = { ".git" },
      })

      -- Lua (lazydev handles runtime/workspace/vim globals automatically)
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            completion = { callSnippet = "Replace" },
          },
        },
      })
    end,
  },

  -- optional bufferline styling
  {
    "akinsho/bufferline.nvim",
    optional = true,
    opts = function(_, opts)
      if (vim.g.colors_name or ""):find("catppuccin") then
        opts.highlights = require("catppuccin.groups.integrations.bufferline").get()
      end
    end,
  },
}
