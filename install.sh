#!/usr/bin/env bash
# install.sh — publica a configuração do RGV1 no escopo de usuário (~/.claude),
# pra que skills, MCPs e plugins funcionem em TODOS os seus projetos, não só aqui.
#
# Uso:
#   ./install.sh            # instala (não sobrescreve skill já existente)
#   ./install.sh --force    # sobrescreve skills existentes
#   ./install.sh --dry-run  # mostra o que faria, sem escrever nada
#
# Idempotente: rodar de novo não duplica nada.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SKILLS_DEST="$CLAUDE_HOME/skills"

FORCE=0
DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --force)   FORCE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Opção desconhecida: $arg (use --help)" >&2; exit 1 ;;
  esac
done

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "    [dry-run] $*"
  else
    "$@"
  fi
}

say()  { printf '%s\n' "$*"; }
step() { printf '\n\033[1m%s\033[0m\n' "$*"; }

[ "$DRY_RUN" -eq 1 ] && say "MODO DRY-RUN — nada será escrito."

# ─── 1. Skills ────────────────────────────────────────────────

step "1/3  Skills → $SKILLS_DEST"

run mkdir -p "$SKILLS_DEST"

installed=0; skipped=0; updated=0
for src in "$REPO_DIR"/.claude/skills/*/; do
  [ -d "$src" ] || continue
  name="$(basename "$src")"
  dest="$SKILLS_DEST/$name"

  if [ -e "$dest" ]; then
    if [ "$FORCE" -eq 1 ]; then
      run rm -rf "$dest"
      run cp -R "$src" "$dest"
      say "    ~ $name (sobrescrita)"
      updated=$((updated + 1))
    else
      say "    · $name (já existe, pulando — use --force pra sobrescrever)"
      skipped=$((skipped + 1))
    fi
  else
    run cp -R "$src" "$dest"
    say "    + $name"
    installed=$((installed + 1))
  fi
done
say "    → $installed nova(s), $updated atualizada(s), $skipped pulada(s)"

# ─── 2. MCP servers ───────────────────────────────────────────

step "2/3  MCP servers (escopo usuário)"

if ! command -v claude >/dev/null 2>&1; then
  say "    ! CLI 'claude' não encontrada no PATH — pulando."
  say "      Instale o Claude Code e rode este script de novo."
else
  # Não dá pra checar com `claude mcp list`: rodando de dentro do RGV1 ele
  # também lista os servidores de escopo projeto (do .mcp.json), e o script
  # pularia o registro no escopo usuário achando que já existe. Em vez disso,
  # tentamos adicionar e tratamos a falha — `claude mcp add` recusa nome
  # duplicado dentro do mesmo escopo, que é exatamente o "já registrado".
  add_mcp() {
    local name="$1"; shift
    if [ "$DRY_RUN" -eq 1 ]; then
      say "    [dry-run] claude mcp add $name --scope user -- $*"
      return 0
    fi
    if err="$(claude mcp add "$name" --scope user -- "$@" 2>&1)"; then
      say "    + $name"
    elif printf '%s' "$err" | grep -qi 'already exists'; then
      say "    · $name (já registrado no escopo usuário)"
    else
      say "    ! $name falhou: $err"
    fi
  }

  add_mcp playwright       npx -y @playwright/mcp@latest
  add_mcp chrome-devtools  npx -y chrome-devtools-mcp@latest

  if command -v glyph >/dev/null 2>&1; then
    add_mcp glyph glyph mcp
  else
    say "    ! glyph não está no PATH — pulando."
    say "      Instale com: go install github.com/benmyles/glyph@latest"
    say "      e garanta que \$(go env GOPATH)/bin está no PATH."
  fi
fi

# ─── 3. Plugins ───────────────────────────────────────────────

step "3/3  Plugins"

say "    Plugins são registrados por comando de barra, não por shell."
say "    Cole estes no Claude Code (uma vez só — valem pra todos os projetos):"
say ""
say "      /plugin marketplace add bradautomates/claude-video"
say "      /plugin marketplace add obra/superpowers"
say "      /plugin marketplace add charlie947/social-media-skills"
say "      /plugin marketplace add anthropics/claude-plugins-official"
say ""
say "      /plugin install watch@claude-video"
say "      /plugin install superpowers@superpowers-dev"
say "      /plugin install social-media-skills@social-media-skills"
say "      /plugin install stripe@claude-plugins-official"

# ─── Fim ──────────────────────────────────────────────────────

step "Pronto."
say "Reinicie o Claude Code pra carregar tudo."
say ""
say "Opcional — gstack (70 MB, precisa de Bun):"
say "  git clone --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack"
say "  cd ~/.claude/skills/gstack && ./setup --team"
