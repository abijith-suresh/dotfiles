# App inventory. install.sh is a dumb iterator over these records; scripts
# under install/ exist only for installs with real logic. Add an app by
# inserting one register call into its phase block.
# Verify snippets intentionally defer expansion: they run inside the
# end-state verification shell, not here.
# shellcheck disable=SC2016
#
#   register <name> phase=... mode=... source=... [fields...]
#
# Fields:
#   phase=   foundation | cli | languages | agents | post-stow
#            Records run in PHASE_ORDER (foundation, cli, languages, agents,
#            post-stow); within a phase, listed order. post-stow runs after
#            Stow deployment.
#   mode=    required (failure aborts the install) | tolerant (failure is
#            recorded and reported in the summary)
#   source=  pkg (package-manager install only) | script (run a script)
#   pkg=     package name for source=pkg, optionally per package manager:
#            "apt:fd-find|*:fd". A bare token applies everywhere.
#   fixlink= distro-binary:target — symlink into ~/.local/bin when the
#            distro ships the binary under another name (batcat, fdfind).
#   script=  path under install/ for source=script. Default derives from
#            the phase: apps/cli/<name>.sh, apps/agents/<name>.sh, or
#            languages/<name>.sh.
#   bin=     executable used by the default end-state verification
#            (defaults to <name>; only needed when it differs)
#   verify=  shell snippet proving the installed state; overrides the
#            default "command -v <bin>"; 'none' skips verification
#   needs=   comma-separated app names that must run earlier in the manifest
#   docs=    official documentation for the install method (repo rule:
#            external installer changes reference their official docs)
# shellcheck disable=SC2034 # shared state: consumed by install/lib.sh
declare -ga PHASE_ORDER=(foundation cli languages agents post-stow)
declare -ga APP_ORDER=()
# shellcheck disable=SC2034 # shared state: consumed by install/lib.sh
declare -gA APP_PHASE APP_MODE APP_SOURCE APP_PKG APP_FIXLINK APP_SCRIPT
# shellcheck disable=SC2034 # shared state: consumed by install/lib.sh
declare -gA APP_BIN APP_VERIFY APP_NEEDS APP_DOCS

register() {
  local name="${1:?register: app name required}"
  shift

  if [ -n "${APP_PHASE[$name]+x}" ]; then
    die "register: duplicate app: $name"
  fi

  local kv key value
  APP_ORDER+=("$name")
  for kv in "$@"; do
    case "$kv" in
      *=*) ;;
      *)
        die "register $name: field without value: $kv"
        ;;
    esac
    key="${kv%%=*}"
    value="${kv#*=}"
    case "$key" in
      phase) APP_PHASE[$name]="$value" ;;
      mode) APP_MODE[$name]="$value" ;;
      source) APP_SOURCE[$name]="$value" ;;
      pkg) APP_PKG[$name]="$value" ;;
      fixlink) APP_FIXLINK[$name]="$value" ;;
      script) APP_SCRIPT[$name]="$value" ;;
      bin) APP_BIN[$name]="$value" ;;
      verify) APP_VERIFY[$name]="$value" ;;
      needs) APP_NEEDS[$name]="$value" ;;
      docs) APP_DOCS[$name]="$value" ;;
      *) die "register $name: unknown field: $key" ;;
    esac
  done

  case "${APP_SOURCE[$name]:-pkg}" in
    pkg | script) ;;
    *) die "register $name: unknown source: ${APP_SOURCE[$name]}" ;;
  esac
  case "${APP_MODE[$name]:-tolerant}" in
    required | tolerant) ;;
    *) die "register $name: unknown mode: ${APP_MODE[$name]}" ;;
  esac
  case "${APP_PHASE[$name]:-}" in
    foundation | cli | agents | languages | post-stow) ;;
    *) die "register $name: unknown phase: ${APP_PHASE[$name]:-}" ;;
  esac
}

# --- Foundation ---------------------------------------------------------------
register mise phase=foundation mode=required source=script \
  docs=https://mise.jdx.dev/installing-mise.html
register zsh phase=foundation mode=required source=script \
  docs=https://www.zsh.org/
register git phase=foundation mode=required source=pkg

# --- CLI and TUI apps ----------------------------------------------------------
register bat phase=cli source=pkg pkg=bat fixlink=batcat:bat
register btop phase=cli source=pkg pkg=btop
register eza phase=cli source=pkg pkg=eza
register fastfetch phase=cli source=pkg pkg=fastfetch
register fd phase=cli source=pkg pkg='apt:fd-find|*:fd' fixlink=fdfind:fd
register fzf phase=cli source=pkg pkg=fzf
register gh phase=cli source=script \
  docs=https://github.com/cli/cli/blob/trunk/docs/install_linux.md
register lazydocker phase=cli source=script \
  docs=https://github.com/jesseduffield/lazydocker
register lazygit phase=cli source=script \
  docs=https://github.com/jesseduffield/lazygit
register neovim phase=cli source=script bin=nvim \
  docs=https://github.com/neovim/neovim/blob/master/INSTALL.md
register railway phase=cli source=script \
  docs=https://docs.railway.com/cli
register ripgrep phase=cli source=pkg pkg=ripgrep bin=rg
register shellcheck phase=cli source=pkg pkg=shellcheck
register shfmt phase=cli source=pkg pkg=shfmt
register starship phase=cli source=script \
  docs=https://starship.rs/guide/
register t3-code phase=cli source=script bin=t3 \
  docs=https://github.com/pingdotgg/t3code/blob/main/docs/user/install.md
register tmux phase=cli source=script \
  docs=https://github.com/tmux-plugins/tpm
register vim phase=cli source=script \
  docs=https://github.com/catppuccin/vim
register zellij phase=cli source=script \
  docs=https://zellij.dev/documentation/installation.html
register zsh-plugins phase=cli source=script \
  docs=https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md \
  verify='test -f "$HOME/.local/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" && test -f "$HOME/.local/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"'
register zoxide phase=cli source=script \
  docs=https://github.com/ajeetdsouza/zoxide

# --- Languages (through mise; verify resolves the tool without reinstalling) ---
register node phase=languages source=script \
  docs=https://mise.jdx.dev/lang/javascript.html \
  verify='mise where node@lts'
register bun phase=languages source=script \
  docs=https://mise.jdx.dev/lang/javascript.html \
  verify='mise where bun@latest'
register java phase=languages source=script \
  docs=https://mise.jdx.dev/lang/java.html \
  verify='mise where java@latest'
register python phase=languages source=script \
  docs=https://mise.jdx.dev/lang/python.html \
  verify='mise where python@latest'
register go phase=languages source=script \
  docs=https://mise.jdx.dev/lang/go.html \
  verify='mise where go@latest'

# --- Agent CLIs (install-only; each keeps its native state directory) ----------
register antigravity phase=agents source=script bin=agy \
  docs=https://www.antigravity.google/docs/cli/install
register claude phase=agents source=script \
  docs=https://claude.ai/install.sh
register codex phase=agents source=script \
  docs=https://chatgpt.com/codex/install.sh
register copilot phase=agents source=script \
  docs=https://gh.io/copilot-install
register cursor phase=agents source=script bin=cursor-agent \
  docs=https://cursor.com/docs/cli/installation
register grok phase=agents source=script \
  docs=https://x.ai/cli
register opencode phase=agents source=script \
  docs=https://opencode.ai/v2/docs
register pi phase=agents source=script needs=node \
  docs=https://pi.dev/docs/latest/quickstart

# --- Post-stow ------------------------------------------------------------------
register tangent phase=post-stow source=script verify=none \
  docs=https://pi.dev/docs/latest/packages
