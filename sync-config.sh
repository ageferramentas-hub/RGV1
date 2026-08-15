#!/usr/bin/env bash
# sync-config.sh — copia a configuração deste repositório (Roger) pra raiz do
# monorepo AGE-IA, que é o que a equipe recebe ao clonar.
#
#   Roger/.claude/skills/     →  AGE-IA/.claude/skills/
#   Roger/.claude/settings.json →  AGE-IA/.claude/settings.json
#   Roger/.mcp.json           →  AGE-IA/.mcp.json
#
# Uso:
#   ./sync-config.sh <caminho-do-AGE-IA>
#   ./sync-config.sh ~/AGE/AGE-IA --dry-run
#
# Não faz commit nem push — só copia. Revise com `git diff` no AGE-IA antes de
# commitar.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST=""
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "Opção desconhecida: $arg (use --help)" >&2; exit 1 ;;
    *) DEST="$arg" ;;
  esac
done

if [ -z "$DEST" ]; then
  echo "Erro: informe o caminho do AGE-IA." >&2
  echo "  ./sync-config.sh ~/AGE/AGE-IA" >&2
  exit 1
fi

DEST="${DEST%/}"

if [ ! -d "$DEST/.git" ]; then
  echo "Erro: $DEST não é um repositório git." >&2
  exit 1
fi

remote="$(git -C "$DEST" remote get-url origin 2>/dev/null || echo '')"
if ! printf '%s' "$remote" | grep -qi 'age-ia'; then
  echo "Erro: $DEST não parece ser o AGE-IA (origin = ${remote:-nenhum})." >&2
  echo "Isso é proposital — evita sobrescrever a configuração do repo errado." >&2
  exit 1
fi

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry-run] $*"
  else
    "$@"
  fi
}

[ "$DRY_RUN" -eq 1 ] && echo "MODO DRY-RUN — nada será escrito."

printf '\n\033[1mRoger → %s\033[0m\n' "$DEST"

run mkdir -p "$DEST/.claude"
run rm -rf "$DEST/.claude/skills"
run cp -R "$REPO_DIR/.claude/skills" "$DEST/.claude/skills"
echo "  ~ .claude/skills/  ($(ls "$REPO_DIR/.claude/skills" | wc -l | tr -d ' ') skills)"

run cp "$REPO_DIR/.claude/settings.json" "$DEST/.claude/settings.json"
echo "  ~ .claude/settings.json"

run cp "$REPO_DIR/.mcp.json" "$DEST/.mcp.json"
echo "  ~ .mcp.json"

printf '\n\033[1mPronto.\033[0m\n'
echo "Revise e publique:"
echo ""
echo "  cd \"$DEST\""
echo "  git diff --stat"
echo "  git add -A && git commit -m 'Atualiza configuração vinda do Roger' && git push"
