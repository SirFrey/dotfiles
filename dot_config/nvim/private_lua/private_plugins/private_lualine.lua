return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  event = 'VeryLazy',
  config = function()
    -- chezmoi indicator, backed by the shared lookup module. Two components so
    -- the color reflects sync state: blue = managed-clean, peach = modified.
    local cm = require('chezmoi_managed')

    local function clean()
      local f = vim.fn.expand('%:p')
      return (cm.is_managed(f) and not cm.is_dirty(f)) and ' chezmoi' or ''
    end

    local function dirty()
      return cm.is_dirty(vim.fn.expand('%:p')) and ' chezmoi*' or ''
    end

    require("lualine").setup({
      options = {
        section_separators = '',
        component_separators = ''
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'diagnostics' },
        lualine_c = {
          'filename',
          { clean, color = { fg = '#8aadf4', gui = 'bold' } },
          { dirty, color = { fg = '#f5a97f', gui = 'bold' } },
        },
        lualine_x = { 'encoding' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' }
      },
      inactive_sections = {
        lualine_a = {},
        lualine_c = { 'filename' },
        lualine_x = {},
        lualine_y = {},
        lualine_z = {}
      }
    })
  end
}
