return {
  "mfussenegger/nvim-lint",
  event = {
    "BufReadPost",
    "BufNewFile",
  },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      svelte = { "eslint_d" },
    }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function()
        -- next tick: spawning eslint_d inside BufEnter delays the first paint
        vim.schedule(function()
          lint.try_lint()
        end)
      end,
    })

    -- manual lint: show it running and report the result, since when the
    -- diagnostics don't change nothing on screen moves
    vim.keymap.set("n", "<leader>l", function()
      local bufnr = vim.api.nvim_get_current_buf()
      local names = lint.linters_by_ft[vim.bo[bufnr].filetype] or {}
      if #names == 0 then
        return vim.notify("No linter for " .. vim.bo[bufnr].filetype, vim.log.levels.WARN)
      end
      lint.try_lint()
      require("lsp_feedback").until_done("Linting", table.concat(names, ", "), function()
        return #lint.get_running(bufnr) == 0
      end, function()
        local n = 0
        for _, ns in pairs(lint.get_namespace and vim.tbl_map(lint.get_namespace, names) or {}) do
          n = n + #vim.diagnostic.get(bufnr, { namespace = ns })
        end
        vim.notify(("Lint (%s): %d problem%s"):format(table.concat(names, ", "), n, n == 1 and "" or "s"))
      end)
    end, { desc = "Trigger linting for current file" })
  end,
}
