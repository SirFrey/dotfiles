return {
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    lazy = false,
    keys = {
      { "-", "<CMD>Oil<CR>", desc = "Open parent directory" },
    },
    opts = {
      columns = { "icon", "chezmoi" },
      view_options = {
        show_hidden = true,
      },
      -- two sign columns for oil-git-status (index + working tree)
      win_options = {
        signcolumn = "yes:2",
      },
      -- Renames use `git mv` and deletes stage the removal, so git sees a rename
      -- instead of delete + untracked. Oil falls back to a plain fs op for
      -- untracked files and paths outside a repo. New files are not auto-added.
      git = {
        add = function()
          return false
        end,
        mv = function()
          return true
        end,
        rm = function()
          return true
        end,
      },
      keymaps = {
        ["<C-l>"] = false,
        -- refresh chezmoi status first, then reload the listing so markers update
        ["gr"] = {
          desc = "Refresh listing + chezmoi status",
          callback = function()
            require("chezmoi_managed").refresh(function()
              require("oil.actions").refresh.callback()
            end)
          end,
        },
        ["<C-h>"] = false,
        ["<C-a>"] = { "actions.select", opts = { horizontal = true } },
        ["gd"] = {
          desc = "Toggle size / mtime / permissions",
          callback = function()
            vim.g.oil_detail = not vim.g.oil_detail
            local cols = { "icon", "chezmoi" }
            if vim.g.oil_detail then
              vim.list_extend(cols, { "permissions", "size", "mtime" })
            end
            require("oil").set_columns(cols)
          end,
        },
        ["gy"] = {
          desc = "Copy full path to system clipboard",
          callback = function()
            local oil = require("oil")
            local entry, dir = oil.get_cursor_entry(), oil.get_current_dir()
            if not entry or not dir then
              return
            end
            local path = dir .. entry.name
            vim.fn.setreg("+", path) -- no clipboard=unnamedplus here, so target + explicitly
            vim.notify("Copied " .. path)
          end,
        },
      },
      -- reload when files change outside nvim (Claude Code, git checkout, formatters)
      watch_for_changes = true,
      lsp_file_methods = {
        -- save buffers the LSP rewrote on rename (import paths), unless you had unsaved edits in them
        autosave_changes = "unmodified",
      },
    },
    -- Optional dependencies
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function(_, opts)
      vim.api.nvim_set_hl(0, "OilChezmoi", { fg = "#8aadf4", bold = true, default = true })
      vim.api.nvim_set_hl(0, "OilChezmoiDirty", { fg = "#f5a97f", bold = true, default = true })

      local FIELD_NAME = 2 -- oil.constants.FIELD_NAME
      require("oil.columns").register("chezmoi", {
        render = function(entry, _, bufnr)
          local dir = require("oil").get_current_dir(bufnr)
          if not dir then
            return ""
          end
          local cm = require("chezmoi_managed")
          local path = dir .. entry[FIELD_NAME]
          if cm.is_dirty(path) then
            return { "●", "OilChezmoiDirty" } -- managed but out of sync
          end
          if cm.is_managed(path) then
            return { "●", "OilChezmoi" } -- managed, clean
          end
          return "" -- unmanaged -> oil renders a dim "-"
        end,
        parse = function(line)
          return line:match("^(%S+)%s+(.*)$")
        end,
      })

      require("oil").setup(opts)
    end,
  },
  {
    -- `git status --short` codes in the sign column: left = index, right = working tree
    "refractalize/oil-git-status.nvim",
    dependencies = { "stevearc/oil.nvim" },
    ft = "oil",
    opts = {
      show_ignored = true, -- gitignored entries show "!!"
    },
  },
}
