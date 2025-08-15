# Repository Guidelines

## Project Structure & Module Organization
- `init.lua`: Entry point that loads core config.
- `lua/config/`: Core files (`options.lua`, `keymaps.lua`, `lazy.lua`, `vimrc.vim`).
- `lua/plugins/`: One file per feature/plugin (e.g., `lsp.lua`, `cmp.lua`, `telescope.lua`).
- `lazy-lock.json`: Locked plugin versions managed by lazy.nvim.
- `stylua.toml`: Lua formatting rules. Optional project meta: `lazyvim.json`, `.neoconf.json`.

## Build, Test, and Development Commands
- `nvim --headless "+Lazy! sync" +qa`: Install/update plugins from specs.
- `nvim --headless "+checkhealth" +qa`: Run health checks and report issues.
- `:Lazy sync | :Lazy check | :Lazy profile`: Manage and inspect plugins.
- `:so %` or `:luafile %`: Reload current Lua file during development.
- `:LspInfo`: Verify LSP is attached; `:messages` to inspect errors.

## Coding Style & Naming Conventions
- Indentation: 2 spaces; max width 120 (see `stylua.toml`).
- Formatting: run `stylua .` (or `:Format` if `conform.nvim` is set up).
- Lua modules live under `lua/`; use snake_case filenames and descriptive plugin spec names (e.g., `plugins/trouble.lua`).
- Prefer `local` scope; avoid globals; return spec tables from plugin files.

## Testing Guidelines
- No unit tests; validate behavior interactively/headless:
  - Open files with `nvim` and verify keymaps/options.
  - LSP: `:LspInfo`; formatting: `:Format`; lint: `:Lint` (if configured).
  - `:checkhealth` should pass without errors.
- Test from a fresh state when needed: `nvim --headless "+Lazy! sync" +qa` then launch `nvim`.

## Commit & Pull Request Guidelines
- Use Conventional Commits: `feat:`, `fix:`, `chore:`, `docs:`; scope with area (`plugins:`, `config:`, `lsp:`).
- Keep commits focused; describe rationale and notable defaults changed.
- PRs include: summary of changes, manual test steps, affected files/areas, and screenshots/screencasts when UI/UX is impacted.

## Security & Configuration Tips
- Do not commit secrets or machine-specific paths.
- When adding plugins, ensure they are pinned via `lazy-lock.json` and document any non-default behavior in the plugin file.

