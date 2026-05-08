#!/usr/bin/env bash
# Check external dependencies for this Neovim config.
# Usage: ./scripts/check-deps.sh
# Exit code: number of missing REQUIRED deps (0 = all good).

set -u

missing_required=0
missing_recommended=0
missing_optional=0

if [[ -t 1 ]]; then
  G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; D=$'\033[90m'; B=$'\033[1m'; N=$'\033[0m'
else
  G=""; R=""; Y=""; D=""; B=""; N=""
fi

check() {
  local tier=$1 name=$2 hint=$3 note=${4:-}
  if command -v "$name" >/dev/null 2>&1; then
    printf "  ${G}OK${N}      %-22s\n" "$name"
    return
  fi
  case "$tier" in
    required)
      printf "  ${R}MISSING${N} %-22s -> %s\n" "$name" "$hint"
      missing_required=$((missing_required + 1))
      ;;
    recommended)
      printf "  ${Y}MISSING${N} %-22s -> %s\n" "$name" "$hint"
      missing_recommended=$((missing_recommended + 1))
      ;;
    optional)
      if [[ -n "$note" ]]; then
        printf "  ${D}MISSING${N} %-22s -> %s  (%s)\n" "$name" "$hint" "$note"
      else
        printf "  ${D}MISSING${N} %-22s -> %s\n" "$name" "$hint"
      fi
      missing_optional=$((missing_optional + 1))
      ;;
  esac
}

# Treat any of cc/gcc/clang as a usable C compiler (treesitter / fzf-native build).
check_c_compiler() {
  for c in cc gcc clang; do
    if command -v "$c" >/dev/null 2>&1; then
      printf "  ${G}OK${N}      %-22s (%s)\n" "C compiler" "$c"
      return
    fi
  done
  printf "  ${R}MISSING${N} %-22s -> %s\n" "C compiler" "apt install build-essential  /  brew install gcc"
  missing_required=$((missing_required + 1))
}

echo "${B}Neovim config — external dependency check${N}"
echo

echo "${B}Required${N}"
check required git    "apt install git"
check required rg     "apt install ripgrep                    (telescope find/grep)"
check required make   "apt install build-essential            (plugin build steps)"
check_c_compiler
check required node   "use mise/fnm  /  apt install nodejs    (Mason JS tooling)"
check required tmux   "apt install tmux                       (claudecode + tmux nav)"

echo
echo "${B}Recommended${N}"
check_fd() {
  if command -v fd >/dev/null 2>&1; then
    printf "  ${G}OK${N}      %-22s\n" "fd"
  elif command -v fdfind >/dev/null 2>&1; then
    printf "  ${G}OK${N}      %-22s (fdfind — symlink as fd for telescope)\n" "fd"
  else
    printf "  ${Y}MISSING${N} %-22s -> %s\n" "fd" "apt install fd-find  /  brew install fd"
    missing_recommended=$((missing_recommended + 1))
  fi
}
check_fd
check recommended fzf     "apt install fzf                    (future picker swap)"
check recommended lazygit "github.com/jesseduffield/lazygit"

echo
echo "${B}Optional (config has fallbacks)${N}"
check optional tsgo             "pnpm add -g @typescript/native-preview" "falls back to ts_ls"
check optional tmux-sessionizer "custom user script"                     "<C-f> keybind"

echo
echo "${B}Mason auto-installs (no manual action needed)${N}"
echo "  LSPs:  astro, bashls, cssls, gh_actions_ls, jsonls, lua_ls, pylsp,"
echo "         pyright, rust_analyzer, tailwindcss, ts_ls, yamlls"
echo "  Tools: prettier, prettierd, stylua, isort, black, pylint, eslint_d"
echo "  Run :Mason inside Neovim to inspect installation status."

echo
echo "${B}Summary${N}"
printf "  required missing:    %d\n" "$missing_required"
printf "  recommended missing: %d\n" "$missing_recommended"
printf "  optional missing:    %d\n" "$missing_optional"

exit "$missing_required"
