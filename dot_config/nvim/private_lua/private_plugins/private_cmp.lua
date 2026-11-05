return {
  {
    -- Replaces nvim-cmp: cmp filtered tsc's large completion lists in Lua on
    -- every keystroke (~25ms median, up to 70ms per key in TS files). blink's
    -- fuzzy matcher is a prebuilt Rust library, so typing stays at vi speed.
    "saghen/blink.cmp",
    version = "1.*", -- release tags ship the prebuilt fuzzy-matcher binary
    event = "InsertEnter",
    dependencies = { "L3MON4D3/LuaSnip" },
    opts = {
      -- Same keys as the old cmp setup (preset.insert + custom maps)
      keymap = {
        preset = "none",
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-l>"] = { "show" }, -- fallback for terminals that swallow <C-Space>
        ["<C-e>"] = { "hide", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<C-y>"] = { "select_and_accept", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<C-u>"] = { "scroll_documentation_up", "fallback" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },
      },
      snippets = { preset = "luasnip" },
      sources = {
        default = { "lazydev", "lsp", "snippets", "path", "buffer" },
        providers = {
          -- vim.* / plugin API completion in Lua files (replaces cmp-nvim-lua)
          lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
        },
      },
      completion = {
        -- <CR> accepts the first item without selecting it first, like cmp's
        -- confirm({ select = true }); nothing is inserted until accepted
        list = { selection = { preselect = true, auto_insert = false } },
        documentation = { auto_show = true, auto_show_delay_ms = 150 },
        menu = {
          -- icon + label + kind, like lspkind's "symbol_text" mode
          draw = {
            columns = { { "kind_icon" }, { "label", "label_description", gap = 1 }, { "kind" } },
          },
        },
      },
      -- cmp's cmdline source was installed but never set up, so `:` used the
      -- built-in wildmenu; keep it that way
      cmdline = { enabled = false },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    config = function(_, opts)
      require("blink.cmp").setup(opts)
      -- transparent menu, as with cmp's CmpNormal
      vim.api.nvim_set_hl(0, "BlinkCmpMenu", { bg = "NONE" })
    end,
  },
  {
    "rafamadriz/friendly-snippets",
    event = "InsertEnter",
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp",
    dependencies = { "rafamadriz/friendly-snippets" },
    event = "InsertEnter",
  },
}
