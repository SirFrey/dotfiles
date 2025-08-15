return {
  "mbbill/undotree",
  cmd = { 'UndotreeToggle', 'UndotreeShow', 'UndotreeHide' },
  config = function()
    vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
  end
}
