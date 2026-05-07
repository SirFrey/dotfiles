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
    event = "VeryLazy",
    config = function()
      -- Defer vim.lsp.start so root_dir resolution and client spawn run on the
      -- next event loop tick instead of blocking the main thread when a JS/TS
      -- file is opened. Each affected server (tsgo, tailwindcss, eslint) does
      -- a sync filesystem walk for root markers; deferring lets the buffer
      -- render first.
      local original_lsp_start = vim.lsp.start
      vim.lsp.start = function(config, opts)
        vim.schedule(function()
          original_lsp_start(config, opts)
        end)
      end

      -- Toggle: set vim.g.use_ts_ls = true before loading to use ts_ls instead of tsgo
      local use_tsgo = not vim.g.use_ts_ls

      require("mason-lspconfig").setup({
        ensure_installed = { "pylsp", "pyright", "lua_ls", "rust_analyzer", "tailwindcss", "ts_ls", "jsonls" },
        automatic_enable = {
          exclude = use_tsgo and { "ts_ls" } or {},
        },
      })

      -- tsgo: TypeScript 7 native LSP (installed via pnpm add -g @typescript/native-preview)
      if use_tsgo then
        vim.lsp.enable("tsgo")
      end

      -- Quick swap commands: :UseTsgo / :UseTsLs
      vim.api.nvim_create_user_command("UseTsgo", function()
        vim.lsp.stop_client(vim.lsp.get_clients({ name = "ts_ls" }))
        vim.lsp.enable("tsgo")
        vim.notify("Switched to tsgo")
      end, {})
      vim.api.nvim_create_user_command("UseTsLs", function()
        vim.lsp.stop_client(vim.lsp.get_clients({ name = "tsgo" }))
        vim.lsp.enable("ts_ls")
        vim.notify("Switched to ts_ls")
      end, {})

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

      -- Tailwind CSS — only attach in projects that actually have a tailwind config.
      -- Previously used { ".git" } which made tailwindcss attach to every JS/TS
      -- buffer in any git repo, doubling LSP traffic on BufEnter.
      vim.lsp.config("tailwindcss", {
        root_markers = {
          "tailwind.config.js",
          "tailwind.config.cjs",
          "tailwind.config.mjs",
          "tailwind.config.ts",
          "postcss.config.js",
          "postcss.config.cjs",
          "postcss.config.mjs",
          "postcss.config.ts",
        },
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
