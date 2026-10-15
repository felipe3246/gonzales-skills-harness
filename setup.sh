#!/usr/bin/env bash
# Setup script for gonzales-skills-hardness.
#
# Installs the skills in skills/ and the guidelines in guidelines/AGENTS.md
# (as real copies, not symlinks) into the user-scope config of Claude Code,
# Codex, and/or Kiro, and optionally installs the curated plugins for Claude
# Code and Codex. Kiro has no plugin system, so it only gets skills.
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

# Always-on guidelines (Karpathy's four principles plus additions). Installed
# as a block delimited by these two markers inside each harness's global
# instruction file, so it can coexist with blocks written by other tools (the
# context7 plugin writes one into ~/.codex/AGENTS.md, for example) and be
# replaced in place on re-run.
GUIDELINES_SRC="$REPO_ROOT/guidelines/AGENTS.md"
G_START='<!-- project-guidelines:start -->'
G_END='<!-- project-guidelines:end -->'

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

  # Decide first, act (or just report) after, so --dry-run shows the same
  # answer the real run acts on.
  local action verb="instalado"
  if [ -L "$dest" ]; then
    # Older versions of this script installed symlinks. A link that points at
    # this repo is just a pointer, so removing it loses nothing; a link that
    # points anywhere else is someone else's and gets moved aside.
    if [ "$(readlink "$dest")" = "$src" ]; then
      action="relink"; verb="convertido de link para cópia"
    else
      action="backup"
      echo "  ! $name: link antigo aponta para outro lugar, será movido para backup"
    fi
  elif [ -d "$dest" ]; then
    if [ -f "$dest/$MARKER" ]; then
      if same_content "$src" "$dest"; then
        echo "  = $name (já instalado, sem mudanças)"
        return
      fi
      action="update"; verb="atualizado"
    else
      action="backup"
      echo "  ! $name: já existe uma pasta que não foi instalada por este script, será movida para backup"
    fi
  elif [ -e "$dest" ]; then
    action="backup"
    echo "  ! $name: já existe algo que não é pasta, será movido para backup"
  else
    action="install"
  fi

  if $DRY_RUN; then
    case "$action" in
      install) printf '  [dry-run] %s: instalar (de %s)\n' "$name" "$src" ;;
      update)  printf '  [dry-run] %s: atualizar, o conteúdo mudou (de %s)\n' "$name" "$src" ;;
      relink)  printf '  [dry-run] %s: converter link antigo em cópia (de %s)\n' "$name" "$src" ;;
      backup)  printf '  [dry-run] %s: mover o que está lá para backup e instalar (de %s)\n' "$name" "$src" ;;
    esac
    return
  fi

  case "$action" in
    relink) rm "$dest" ;;
    update) rm -rf "$dest" ;;
    backup) mv "$dest" "$dest.bak-$(date +%s)" ;;
  esac

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
  run mkdir -p "$dest_root"
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

# --- guidelines: one marker-delimited block per tool's global instruction file ---

# The exact text that goes between the markers: a source pointer (same role as
# the .installed-from marker for skills) followed by the guidelines themselves.
guidelines_block() {
  printf '%s\n' "$G_START"
  printf '<!-- source: %s. Installed by setup.sh; edit the source, then re-run. -->\n' "$GUIDELINES_SRC"
  cat "$GUIDELINES_SRC"
  printf '%s\n' "$G_END"
}

install_guidelines() {
  local label="$1" dest="$2"
  echo "== Guidelines: $label ($dest) =="

  # Decide what this run would do before touching anything, so dry-run can
  # report the same answer the real run acts on.
  local action
  if [ ! -f "$dest" ]; then
    action="criar"
  elif grep -qF -- "$G_START" "$dest" && grep -qF -- "$G_END" "$dest"; then
    action="substituir"
  else
    action="anexar"
    echo "  ! $dest já existe e não tem o bloco de guidelines: o bloco será anexado ao final do arquivo, o conteúdo atual fica como está"
  fi

  # Build the would-be result in a temp file first, so both modes can tell a
  # no-op apart from a real change.
  local block tmp verb
  block="$(mktemp)"; tmp="$(mktemp)"
  guidelines_block > "$block"

  case "$action" in
    criar)
      cp "$block" "$tmp"
      verb="instalado"
      ;;
    substituir)
      # Replace only what sits between our markers; everything else is left as is.
      awk -v s="$G_START" -v e="$G_END" -v bf="$block" '
        index($0, s) && !done { while ((getline line < bf) > 0) print line; close(bf); skip=1; next }
        skip && index($0, e)   { skip=0; done=1; next }
        !skip                  { print }
      ' "$dest" > "$tmp"
      verb="atualizado"
      ;;
    anexar)
      # Someone else's content, no block of ours yet: append after a blank line.
      cp "$dest" "$tmp"
      [ -s "$tmp" ] && [ "$(tail -c1 "$tmp" | wc -l)" -eq 0 ] && echo >> "$tmp"
      echo >> "$tmp"
      cat "$block" >> "$tmp"
      verb="anexado ao final"
      ;;
  esac

  if [ -f "$dest" ] && cmp -s "$tmp" "$dest"; then
    echo "  = guidelines (já instalado, sem mudanças)"
  elif $DRY_RUN; then
    case "$action" in
      criar)      printf '  [dry-run] guidelines -> %s (criar o arquivo)\n' "$dest" ;;
      substituir) printf '  [dry-run] guidelines -> %s (substituir o bloco existente)\n' "$dest" ;;
      anexar)     printf '  [dry-run] guidelines -> %s (anexar ao final)\n' "$dest" ;;
    esac
  else
    mkdir -p "$(dirname "$dest")"
    cat "$tmp" > "$dest"   # not mv: keeps an existing file's mode, and a new one gets the umask default
    echo "  + guidelines: $verb (de $GUIDELINES_SRC)"
  fi
  rm -f "$block" "$tmp"
  echo
}

$DO_CLAUDE && install_guidelines "Claude Code" "$HOME/.claude/rules/project-guidelines.md"
$DO_CODEX  && install_guidelines "Codex"       "$HOME/.codex/AGENTS.md"
$DO_KIRO   && install_guidelines "Kiro"        "$HOME/.kiro/steering/project-guidelines.md"

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
echo "Lembrete: skills e guidelines globais são cópias. Depois de editar skills/ ou guidelines/, rode ./setup.sh de novo para atualizá-las."
echo "Sugestão não instalada automaticamente: o plugin 'humanizer' (blader/humanizer)."
echo "Comandos em README.md, seção 'Sugeridos, não instalados'."
