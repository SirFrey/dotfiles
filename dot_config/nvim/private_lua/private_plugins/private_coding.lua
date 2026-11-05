return {
  {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter", -- attaches on InsertEnter itself; an ft trigger would re-fire FileType before first paint
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
      -- On Windows, tree-sitter CLI defaults to cl.exe (often absent) and MinGW's
      -- ld.exe chokes on the \\?\ path prefix that tree-sitter-cli generates.
      -- Use zig cc via a temp shim (no-op on Linux where cc just works).
      if vim.fn.has("win32") == 1 and vim.env.CC == nil then
        local zigcc = vim.fn.tempname() .. ".cmd"
        vim.fn.writefile({ "@zig cc %* -target x86_64-windows-gnu" }, zigcc)
        vim.env.CC = zigcc
      end

      -- main branch API: setup() only takes install_dir, not ensure_installed
      require("nvim-treesitter").setup()

      -- Install parsers (no-op if already installed). Runs on the first pause
      -- (lua/idle.lua): loading the installer module alone costs a few ms.
      require("idle").run(function()
        require("nvim-treesitter").install({
          "c", "lua", "vim", "vimdoc", "query",
          "elixir", "heex", "javascript", "typescript",
          "html", "css", "rust", "astro", "tsx",
          "ssh_config",
        })
      end)

      -- Highlighting is NOT automatic in nvim-treesitter main branch.
      -- Must explicitly start treesitter for each buffer.
      -- The first buffer of a language pays for compiling its queries, which is
      -- slow for big grammars (~200ms for TypeScript: injections + highlights;
      -- parsing itself is ~13ms). That first start waits until no key has
      -- been pressed for 'updatetime', so the freeze lands while you're idle;
      -- regex syntax highlights the buffer meanwhile. Once a language is
      -- compiled, later buffers start on the next tick as before.
      -- (lua/idle.lua; CursorHold can't be used: it never fires before the first keypress.)
      local compiled = {} ---@type table<string, true>
      -- Injections (sql/css/html/graphql inside template strings) are ~half the
      -- TS/JS compile cost (~280ms -> ~120ms). Only sql`` is used in our repos
      -- and the sql parser isn't installed, so they highlighted nothing.
      -- Delete an entry here to bring injections back for that language.
      local no_injections = { typescript = true, tsx = true, javascript = true }
      local function start(buf)
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end
        local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
        if lang and no_injections[lang] then
          no_injections[lang] = nil
          pcall(vim.treesitter.query.set, lang, "injections", "")
        end
        if pcall(vim.treesitter.start, buf) then
          compiled[vim.bo[buf].filetype] = true
        end
      end
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true }),
        callback = function(ev)
          if compiled[ev.match] then
            vim.schedule(function()
              start(ev.buf)
            end)
          else
            require("idle").run(function()
              start(ev.buf)
            end, vim.o.updatetime)
          end
        end,
      })
    end,
  },
  {
    "catgoose/nvim-colorizer.lua",
    -- Loaded on the first pause after FileType (lua/idle.lua) instead of via
    -- `ft`: lazy's ft trigger re-fires FileType (re-sourcing syntax files,
    -- ~30ms on a TS file) and the colorizer setup itself would block first paint.
    init = function()
      local fts = { "css", "scss", "html", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte", "lua" }
      local group = vim.api.nvim_create_augroup("ColorizerDeferredLoad", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = fts,
        callback = function(ev)
          require("idle").run(function()
            if not vim.api.nvim_buf_is_valid(ev.buf) then
              return
            end
            require("lazy").load({ plugins = { "nvim-colorizer.lua" } })
            local colorizer = require("colorizer")
            if not colorizer.is_buffer_attached(ev.buf) then
              colorizer.attach_to_buffer(ev.buf)
            end
          end)
        end,
      })
    end,
    opts = {},
  },
}
