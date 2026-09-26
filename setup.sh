#!/usr/bin/env bash
# Setup script for gonzales-skills-hardness.
#
# Installs the skills in skills/ (as user-scope symlinks) for Claude Code,
# Codex, and/or Kiro, and optionally installs the curated plugins for
# Claude Code and Codex. Kiro has no plugin system, so it only gets skills.
#
# Usage:
#   ./setup.sh                          interactive menu
#   ./setup.sh --all                    all three tools, skills only
#   ./setup.sh --claude --codex         pick tools via flags
#   ./setup.sh --all --with-plugins     also install plugins, no prompt
#   ./setup.sh --all --no-plugins       skip the plugins prompt entirely
#   ./setup.sh --all --dry-run          print what would happen, change nothing
#
# Re-running is safe: skill symlinks that already point here are left alone,
# anything else at the destination is moved aside with a .bak-<timestamp>
# suffix instead of being overwritten, and every install command used here
# is idempotent (verified: running it twice produces the same result, no
# duplicate marketplaces, no error on an already-installed plugin).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"

# Written for OpenCode specifically (mentions oh-my-opencode-slim), so it
# would misinform Claude Code / Codex / Kiro if exposed there. See
# README.md.
EXCLUDE_SKILLS=("reflect")

DO_CLAUDE=false
DO_CODEX=false
DO_KIRO=false
PLUGINS_MODE="ask"   # ask | yes | no
DRY_RUN=false
ANY_FLAG=false

usage() { sed -n '2,20p' "$0" | sed 's/^# //; s/^#//'; }

for arg in "$@"; do
  case "$arg" in
    --all) DO_CLAUDE=true; DO_CODEX=true; DO_KIRO=true; ANY_FLAG=true ;;
    --claude) DO_CLAUDE=true; ANY_FLAG=true ;;
    --codex) DO_CODEX=true; ANY_FLAG=true ;;
    --kiro) DO_KIRO=true; ANY_FLAG=true ;;
    --with-plugins) PLUGINS_MODE="yes" ;;
    --no-plugins) PLUGINS_MODE="no" ;;
    --dry-run) DRY_RUN=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Argumento desconhecido: $arg" >&2; usage; exit 1 ;;
  esac
done

run() {
  if $DRY_RUN; then
    printf '  [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

# --- interactive menu, only if no --claude/--codex/--kiro/--all flag was passed ---
if ! $ANY_FLAG; then
  echo "gonzales-skills-hardness — setup"
  echo
  echo "Quais ferramentas configurar?"
  echo "  1) Claude Code"
  echo "  2) Codex"
  echo "  3) Kiro"
  echo "  4) Todas"
  read -rp "Escolha (ex: '1 3', ou '4' para todas): " -a CHOICES
  for c in "${CHOICES[@]:-}"; do
    case "$c" in
      1) DO_CLAUDE=true ;;
      2) DO_CODEX=true ;;
      3) DO_KIRO=true ;;
      4) DO_CLAUDE=true; DO_CODEX=true; DO_KIRO=true ;;
    esac
  done
fi

if ! $DO_CLAUDE && ! $DO_CODEX && ! $DO_KIRO; then
  echo "Nada selecionado, saindo." >&2
  exit 1
fi

echo
echo "Selecionado: $($DO_CLAUDE && echo -n 'Claude Code ') $($DO_CODEX && echo -n 'Codex ') $($DO_KIRO && echo -n 'Kiro ')"
$DRY_RUN && echo "(modo dry-run: nada será alterado de fato)"
echo

# --- skills: one absolute-path symlink per tool's user-scope skill directory ---
link_skill() {
  local dest_root="$1" name="$2"
  local dest="$dest_root/$name"
  local src="$SKILLS_DIR/$name"

  run mkdir -p "$dest_root"
  if $DRY_RUN; then
    printf '  [dry-run] link %s -> %s\n' "$dest" "$src"
    return
  fi

  if [ -L "$dest" ]; then
    if [ "$(readlink "$dest")" = "$src" ]; then
      echo "  = $name (já linkado)"
      return
    fi
    mv "$dest" "$dest.bak-$(date +%s)"
    echo "  ! $name: link antigo apontava para outro lugar, movido para backup"
  elif [ -e "$dest" ]; then
    mv "$dest" "$dest.bak-$(date +%s)"
    echo "  ! $name: já existia algo (não era link), movido para backup"
  fi

  ln -s "$src" "$dest"
  echo "  + $name -> $src"
}

install_skills_for() {
  local label="$1" dest_root="$2"
  echo "== Skills: $label ($dest_root) =="
  for skill_path in "$SKILLS_DIR"/*/; do
    local name
    name="$(basename "$skill_path")"
    [[ " ${EXCLUDE_SKILLS[*]} " == *" $name "* ]] && continue
    link_skill "$dest_root" "$name"
  done
  echo
}

$DO_CLAUDE && install_skills_for "Claude Code" "$HOME/.claude/skills"
$DO_CODEX  && install_skills_for "Codex"       "$HOME/.agents/skills"
$DO_KIRO   && install_skills_for "Kiro"        "$HOME/.kiro/skills"

if $DO_KIRO; then
  echo "Kiro: ~/.kiro/skills é o caminho confirmado que o Kiro lê (open Agent Skills spec)."
  echo
fi

# --- plugins: only relevant for Claude Code and Codex ---
if $DO_CLAUDE || $DO_CODEX; then
  if [ "$PLUGINS_MODE" = "ask" ] && ! $DRY_RUN; then
    read -rp "Instalar também os plugins curados (Claude Code / Codex)? [y/N]: " ANSWER
    [[ "$ANSWER" =~ ^[Yy]$ ]] && PLUGINS_MODE="yes" || PLUGINS_MODE="no"
  fi

  if [ "$PLUGINS_MODE" = "yes" ]; then
    if $DO_CLAUDE; then
      echo "== Plugins: Claude Code (marketplace claude-plugins-official, scope user) =="
      run claude plugin marketplace add anthropics/claude-plugins-official --scope user
      for p in code-review context7 frontend-design playwright ralph-loop stripe superdesign superpowers terraform; do
        run claude plugin install "$p@claude-plugins-official" --scope user -y \
          || echo "  ! falhou: $p (confira manualmente)"
      done
      echo
    fi

    if $DO_CODEX; then
      echo "== Plugins: Codex =="
      # Já vêm na marketplace curada da própria OpenAI, sem precisar de marketplace add.
      run codex plugin add superpowers@openai-api-curated || echo "  ! falhou: superpowers"
      run codex plugin add stripe@openai-api-curated || echo "  ! falhou: stripe"

      run codex plugin marketplace add anthropics/claude-plugins-official
      for p in code-review context7 frontend-design playwright ralph-loop terraform; do
        run codex plugin add "$p@claude-plugins-official" \
          || echo "  ! falhou: $p (confira manualmente)"
      done

      # Repo próprio, nome da marketplace vem do plugin.json (não do nome do repo).
      run codex plugin marketplace add superdesigndev/superdesign-skill
      run codex plugin add superdesign@superdesign || echo "  ! falhou: superdesign"
      echo
    fi
  else
    echo "Plugins não instalados. Comandos e mais detalhes em README.md."
    echo
  fi
fi

echo "Pronto."
echo "Sugestão não instalada automaticamente: o plugin 'humanizer' (blader/humanizer)."
echo "Comandos em README.md, seção 'Sugeridos, não instalados'."
