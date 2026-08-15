#!/usr/bin/env bash
# sync-config.sh — copia a configuração deste repositório (Roger) pra raiz do
# monorepo AGE-IA, que é o que a equipe recebe ao clonar.
#
#   Roger/.claude/skills/       →  AGE-IA/.claude/skills/
#   Roger/.claude/agents/       →  AGE-IA/.claude/agents/
#   Roger/.claude/commands/     →  AGE-IA/.claude/commands/
#   Roger/.claude/hooks/        →  AGE-IA/.claude/hooks/
#   Roger/.claude/settings.json →  AGE-IA/.claude/settings.json
#   Roger/.mcp.json             →  AGE-IA/.mcp.json
#
# Pasta que não existe aqui é pulada, nunca apagada no destino.
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

# Pastas de configuração. Ausente na origem = pulada, não apagada no destino.
for dir in skills agents commands hooks; do
  src="$REPO_DIR/.claude/$dir"
  if [ ! -d "$src" ]; then
    echo "  · .claude/$dir/ (não existe aqui, pulando)"
    continue
  fi
  run rm -rf "$DEST/.claude/$dir"
  run cp -R "$src" "$DEST/.claude/$dir"
  echo "  ~ .claude/$dir/  ($(ls "$src" | wc -l | tr -d ' ') itens)"
done

if [ -f "$REPO_DIR/.mcp.json" ]; then
  run cp "$REPO_DIR/.mcp.json" "$DEST/.mcp.json"
  echo "  ~ .mcp.json"
else
  echo "  · .mcp.json (não existe aqui, pulando)"
fi

# settings.json é MESCLADO, não sobrescrito. Daqui vêm só os marketplaces e os
# plugins; o resto do arquivo no destino é preservado. Sobrescrever apagaria os
# hooks do AGE-IA — foi o que matou o SessionStart do motor de carrossel uma vez.
if [ ! -f "$REPO_DIR/.claude/settings.json" ]; then
  echo "  · .claude/settings.json (não existe aqui, pulando)"
elif [ "$DRY_RUN" -eq 1 ]; then
  echo "  [dry-run] mesclar .claude/settings.json (marketplaces + plugins)"
  echo "  ~ .claude/settings.json (mesclado)"
else
  ORIGEM="$REPO_DIR/.claude/settings.json" DESTINO="$DEST/.claude/settings.json" python3 - <<'PY'
import json, os

origem, destino = os.environ["ORIGEM"], os.environ["DESTINO"]
novo = json.load(open(origem))

try:
    atual = json.load(open(destino))
except (FileNotFoundError, json.JSONDecodeError):
    atual = {}

for chave in ("extraKnownMarketplaces", "enabledPlugins"):
    if chave in novo:
        atual[chave] = novo[chave]

os.makedirs(os.path.dirname(destino), exist_ok=True)
with open(destino, "w") as f:
    json.dump(atual, f, indent=2, ensure_ascii=False)
    f.write("\n")

preservadas = [k for k in atual if k not in ("extraKnownMarketplaces", "enabledPlugins")]
print("  ~ .claude/settings.json (mesclado" +
      (f"; preservado: {', '.join(preservadas)}" if preservadas else "") + ")")
PY
fi

printf '\n\033[1mPronto.\033[0m\n'
echo "Revise e publique:"
echo ""
echo "  cd \"$DEST\""
echo "  git diff --stat"
echo "  git add -A && git commit -m 'Atualiza configuração vinda do Roger' && git push"
