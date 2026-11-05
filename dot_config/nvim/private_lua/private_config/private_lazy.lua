local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- import/override with your plugins
    { import = "plugins" },
  },
  defaults = {
    -- Lazy-load custom plugins by default to reduce startup time
    lazy = true,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- unused built-ins; oil replaces netrw, and gx is native (vim.ui.open) since 0.10
      disabled_plugins = { "gzip", "tarPlugin", "zipPlugin", "tohtml", "tutor", "netrwPlugin" },
    },
  },
})

-- `event = "User IdleLoad"`: plugins that don't need to be ready the instant
-- the UI appears load on the first pause after VeryLazy (see lua/idle.lua),
-- instead of in the same freeze as everything else right after first paint.
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    require("idle").run(function()
      vim.api.nvim_exec_autocmds("User", { pattern = "IdleLoad" })
    end)
    -- Insert-mode plugins keep `event = "InsertEnter"` as a fallback, but load
    -- here on a pause, one per tick: loading all of them on the first
    -- keystroke in insert mode froze typing for ~70ms.
    for _, name in ipairs({ "LuaSnip", "friendly-snippets", "blink.cmp", "neocodeium" }) do
      require("idle").run(function()
        require("lazy").load({ plugins = { name } })
      end)
    end
  end,
})
