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
    -- Own idle task after VeryLazy (lua/idle.lua): loading mason and mapping
    -- packages to servers is ~50ms, and as part of the VeryLazy batch it
    -- stacked with every other plugin into one freeze right after first paint.
    event = "User LspDeferred",
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
          require("idle").run(function()
            vim.api.nvim_exec_autocmds("User", { pattern = "LspDeferred" })
          end)
        end,
      })
    end,
    config = function()
      -- Defer vim.lsp.start so root_dir resolution and client spawn run on the
      -- next event loop tick instead of blocking the main thread when a JS/TS
      -- file is opened. Each affected server (ts_ls, tailwindcss, eslint) does
      -- a sync filesystem walk for root markers; deferring lets the buffer
      -- render first.
      local original_lsp_start = vim.lsp.start
      vim.lsp.start = function(config, opts)
        vim.schedule(function()
          original_lsp_start(config, opts)
        end)
      end

      -- All vim.lsp.config() overrides must come before mason-lspconfig.setup():
      -- its automatic_enable calls vim.lsp.enable(), which resolves configs and
      -- attaches to the already-open buffer immediately.

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

      -- JSON with schemastore. The catalog costs ~20ms to load, so it's built
      -- only when jsonls actually starts. Mutate in place: the client holds a
      -- reference to this settings table, so reassigning it would be ignored.
      vim.lsp.config("jsonls", {
        before_init = function(_, config)
          config.settings.json.schemas = require("schemastore").json.schemas()
        end,
        settings = {
          json = {
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

      -- TypeScript 7 native LSP. lspconfig's tsc root_dir runs `<bin> --version`
      -- synchronously for up to four candidate binaries to find one with --lsp
      -- support, freezing the UI ~200ms every time a TS project is opened. Same
      -- candidates and priority order, probed in parallel off the main thread.
      local tsc_bin = {} ---@type table<string, string|false>
      local tsc_waiting = {} ---@type table<string, fun(root: string)[]>
      local function probe_tsc(root)
        local cands = {}
        for _, name in ipairs({ "tsc", "tsgo" }) do
          for _, bin in ipairs({ vim.fs.joinpath(root, "node_modules/.bin", name), name }) do
            if vim.fn.executable(bin) == 1 then
              table.insert(cands, bin)
            end
          end
        end
        local function finish(bin)
          tsc_bin[root] = bin or false
          if not bin then
            vim.notify("tsc: no binary supporting `--lsp` found (requires TypeScript 7.0+)", vim.log.levels.WARN)
          end
          for _, on_dir in ipairs(tsc_waiting[root]) do
            if bin then
              on_dir(root)
            end
          end
          tsc_waiting[root] = nil
        end
        local ok, pending = {}, #cands
        if pending == 0 then
          return finish(nil)
        end
        for i, bin in ipairs(cands) do
          vim.system({ bin, "--version" }, { text = true }, function(out)
            local v = out.code == 0 and vim.version.parse(out.stdout or "") or nil
            ok[i] = v ~= nil and v.major >= 7
            pending = pending - 1
            if pending == 0 then
              vim.schedule(function()
                for j, b in ipairs(cands) do
                  if ok[j] then
                    return finish(b)
                  end
                end
                finish(nil)
              end)
            end
          end)
        end
      end

      vim.lsp.config("tsc", {
        cmd = function(dispatchers, config)
          return vim.lsp.rpc.start({ tsc_bin[config.root_dir] or "tsc", "--lsp", "--stdio" }, dispatchers)
        end,
        root_dir = function(bufnr, on_dir)
          -- root detection copied from lspconfig's tsc.lua (deno projects are skipped)
          local root_markers = { { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" }, { ".git" } }
          local deno_root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc" })
          local deno_lock_root = vim.fs.root(bufnr, { "deno.lock" })
          local project_root = vim.fs.root(bufnr, root_markers)
          if deno_lock_root and (not project_root or #deno_lock_root > #project_root) then
            return
          end
          if deno_root and (not project_root or #deno_root >= #project_root) then
            return
          end
          local root = project_root or vim.fn.getcwd()
          if tsc_bin[root] ~= nil then
            if tsc_bin[root] then
              on_dir(root)
            end
            return
          end
          if tsc_waiting[root] then
            table.insert(tsc_waiting[root], on_dir)
            return
          end
          tsc_waiting[root] = { on_dir }
          probe_tsc(root)
        end,
      })

      require("mason-lspconfig").setup({
        ensure_installed = {
          "astro",
          "bashls",
          "cssls",
          "gh_actions_ls",
          "jsonls",
          "lua_ls",
          "pylsp",
          "pyright",
          "rust_analyzer",
          "tailwindcss",
          "yamlls",
        },
      })

      require("mason-tool-installer").setup({
        ensure_installed = {
          "prettier", -- prettier formatter (binary)
          "prettierd", -- prettier formatter (daemon)
          "stylua", -- lua formatter
          "isort", -- python formatter
          "black", -- python formatter
          "pylint", -- python linter
          "eslint_d", -- js linter
        },
        -- default 0 runs the registry/install check inside the startup window
        start_delay = 3000,
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
