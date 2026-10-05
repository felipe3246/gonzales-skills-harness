#!/usr/bin/env bash
# Setup script for gonzales-skills-hardness.
#
# Installs the skills in skills/ (as real copies, not symlinks) into the
# user-scope skill directory of Claude Code, Codex, and/or Kiro, and
# optionally installs the curated plugins for Claude Code and Codex. Kiro has
# no plugin system, so it only gets skills.
#
# Usage:
#   ./setup.sh                          interactive menu
#   ./setup.sh --all                    all three tools, skills only
#   ./setup.sh --claude --codex         pick tools via flags
#   ./setup.sh --all --with-plugins     also install plugins, no prompt
#   ./setup.sh --all --no-plugins       skip the plugins prompt entirely
#   ./setup.sh --all --dry-run          print what would happen, change nothing
#
# Re-running is safe. Every copy this script makes carries a marker file
# (.installed-from) so it can tell its own installs apart from anything else:
# its own copies are refreshed when the source changed and left alone when it
# didn't; symlinks left behind by older versions of this script are replaced
# by copies; anything else at the destination is moved aside with a
# .bak-<timestamp> suffix instead of being overwritten. Every install command
# used here is idempotent (verified: running it twice produces the same
# result, no duplicate marketplaces, no error on an already-installed plugin).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"

# Written for OpenCode specifically (mentions oh-my-opencode-slim), so it
# would misinform Claude Code / Codex / Kiro if exposed there. See
# README.md.
EXCLUDE_SKILLS=("reflect")

# Written inside every installed copy. Its presence is how the script knows a
# directory is its own (safe to refresh); its content is the source path.
MARKER=".installed-from"

# Working-tree noise that must not end up inside an install.
COPY_EXCLUDES=(".DS_Store" "__pycache__")

DO_CLAUDE=false
DO_CODEX=false
DO_KIRO=false
PLUGINS_MODE="ask"   # ask | yes | no
DRY_RUN=false
ANY_FLAG=false

usage() { sed -n '2,15p' "$0" | sed 's/^# //; s/^#//'; }

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

# --- skills: one real copy per tool's user-scope skill directory ---

# True when the installed copy at $2 already matches the source at $1
# (ignoring the marker and the excluded noise).
same_content() {
  local src="$1" dest="$2"
  local args=(-rq -x "$MARKER")
  local e
  for e in "${COPY_EXCLUDES[@]}"; do args+=(-x "$e"); done
  diff "${args[@]}" "$src" "$dest" >/dev/null 2>&1
}

copy_skill() {
  local dest_root="$1" name="$2"
  local dest="$dest_root/$name"
  local src="$SKILLS_DIR/$name"
  local verb="instalado"

  run mkdir -p "$dest_root"
  if $DRY_RUN; then
    printf '  [dry-run] copy %s -> %s\n' "$src" "$dest"
    return
  fi

  if [ -L "$dest" ]; then
    # Older versions of this script installed symlinks. A link that points at
    # this repo is just a pointer, so removing it loses nothing; a link that
    # points anywhere else is someone else's and gets moved aside.
    if [ "$(readlink "$dest")" = "$src" ]; then
      rm "$dest"
      verb="convertido de link para cópia"
    else
      mv "$dest" "$dest.bak-$(date +%s)"
      echo "  ! $name: link antigo apontava para outro lugar, movido para backup"
    fi
  elif [ -d "$dest" ]; then
    if [ -f "$dest/$MARKER" ]; then
      if same_content "$src" "$dest"; then
        echo "  = $name (já instalado, sem mudanças)"
        return
      fi
      rm -rf "$dest"
      verb="atualizado"
    else
      mv "$dest" "$dest.bak-$(date +%s)"
      echo "  ! $name: já existia uma pasta que não foi instalada por este script, movida para backup"
    fi
  elif [ -e "$dest" ]; then
    mv "$dest" "$dest.bak-$(date +%s)"
    echo "  ! $name: já existia algo (não era pasta), movido para backup"
  fi

  cp -Rp "$src" "$dest"
  local e
  for e in "${COPY_EXCLUDES[@]}"; do
    find "$dest" -name "$e" -prune -exec rm -rf {} +
  done
  printf '%s\n' "$src" > "$dest/$MARKER"
  echo "  + $name: $verb (de $src)"
}

install_skills_for() {
  local label="$1" dest_root="$2"
  echo "== Skills: $label ($dest_root) =="
  for skill_path in "$SKILLS_DIR"/*/; do
    local name
    name="$(basename "$skill_path")"
    [[ " ${EXCLUDE_SKILLS[*]} " == *" $name "* ]] && continue
    copy_skill "$dest_root" "$name"
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
echo "Lembrete: as skills globais são cópias. Depois de editar skills/, rode ./setup.sh de novo para atualizá-las."
echo "Sugestão não instalada automaticamente: o plugin 'humanizer' (blader/humanizer)."
echo "Comandos em README.md, seção 'Sugeridos, não instalados'."
