return {
  {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    ft = { "html", "xml", "javascript", "javascriptreact", "typescriptreact", "svelte", "vue" },
    config = function()
      require("nvim-ts-autotag").setup({
        opts = {
          -- Defaults
          enable_close = true, -- Auto close tags
          enable_rename = true, -- Auto rename pairs of tags
          enable_close_on_slash = false, -- Auto close on trailing </
        },
        -- Also override individual filetype configs, these take priority.
        -- Empty by default, useful if one of the "opts" global settings
        -- doesn't work well in a specific filetype
        per_filetype = {
          ["html"] = {
            enable_close = false,
          },
        },
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      -- main branch API: setup() only takes install_dir, not ensure_installed
      require("nvim-treesitter").setup()

      -- Install parsers (no-op if already installed)
      require("nvim-treesitter").install({
        "c", "lua", "vim", "vimdoc", "query",
        "elixir", "heex", "javascript", "typescript",
        "html", "css", "rust", "astro", "tsx",
        "tmux", "ssh_config",
      })

      -- Highlighting is NOT automatic in nvim-treesitter main branch.
      -- Must explicitly start treesitter for each buffer. Deferred via
      -- vim.schedule so the initial parse runs on the next event loop tick
      -- rather than blocking the buffer render on FileType.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true }),
        callback = function(ev)
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(ev.buf) then
              pcall(vim.treesitter.start, ev.buf)
            end
          end)
        end,
      })
    end,
  },
  {
    "catgoose/nvim-colorizer.lua",
    ft = { "css", "scss", "html", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte", "lua" },
    opts = {},
  },
}
