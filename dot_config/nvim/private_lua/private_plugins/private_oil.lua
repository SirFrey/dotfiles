return {
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
}
