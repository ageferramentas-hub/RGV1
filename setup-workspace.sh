#!/usr/bin/env bash
# setup-workspace.sh — monta a estrutura de pastas da AGE I.A na sua máquina.
#
#   ~/AGE-IA/                    ← a mãe
#     ├── RGV1/                  ← ambiente de trabalho (configuração do Claude)
#     ├── CLEVERTON/             ← projeto
#     ├── GERADOR-DE-CARROSSEL/  ← projeto
#     └── <novos apps>/          ← projetos
#
# Uso:
#   ./setup-workspace.sh            # cria a pasta e clona o que faltar
#   ./setup-workspace.sh --dry-run  # mostra o que faria, sem escrever
#
# A pasta no disco é AGE-IA (sem espaço nem ponto) pra não quebrar caminho em
# terminal e script. "AGE I.A" continua sendo o nome de exibição.
#
# Idempotente: repositório já clonado é pulado, nunca sobrescrito.

set -euo pipefail

WORKSPACE="${AGE_WORKSPACE:-$HOME/AGE-IA}"
GH_OWNER="ageferramentas-hub"

# Nome do repositório no GitHub → nome da pasta local.
# Ajuste a coluna da esquerda depois de renomear no GitHub.
REPOS=(
  "RGV1:RGV1"
  "AGE-OS:CLEVERTON"
  "GERADOR-DE-CARROSSEL:GERADOR-DE-CARROSSEL"
)

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
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

step "Workspace: $WORKSPACE"
run mkdir -p "$WORKSPACE"

for entry in "${REPOS[@]}"; do
  remote_name="${entry%%:*}"
  local_name="${entry##*:}"
  dest="$WORKSPACE/$local_name"
  url="https://github.com/$GH_OWNER/$remote_name"

  if [ -d "$dest/.git" ]; then
    say "    · $local_name (já clonado)"
    continue
  fi

  if [ -e "$dest" ]; then
    say "    ! $local_name existe mas não é repositório git — pulando por segurança."
    continue
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    say "    [dry-run] git clone $url $dest"
    continue
  fi

  if git clone "$url" "$dest" 2>/dev/null; then
    say "    + $local_name  ($remote_name)"
  else
    say "    ! $local_name — falhou ao clonar $url"
    say "      O repositório existe no GitHub com esse nome exato?"
  fi
done

step "Pronto."
say "Estrutura em $WORKSPACE"
say ""
say "Cada projeto é um repositório independente, com seu próprio deploy e"
say "histórico. O RGV1 é só configuração — nenhum código de app mora nele."
say ""
say "Para publicar as skills e MCPs no escopo de usuário (valem em todos os"
say "projetos), rode dentro do RGV1:"
say ""
say "  cd \"$WORKSPACE/RGV1\" && ./install.sh"
