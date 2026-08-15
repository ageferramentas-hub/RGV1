#!/usr/bin/env bash
# setup-workspace.sh — clona os repositórios da agência na sua máquina.
#
#   ~/AGE/
#     ├── AGE-IA/     ← monorepo dos apps (GERADOR-DE-CARROSSEL, EDITOR-DE-VIDEO, ...)
#     ├── Roger/      ← ambiente de trabalho (este repositório, só configuração)
#     └── Cleverton/  ← projeto
#
# Uso:
#   ./setup-workspace.sh            # cria a pasta e clona o que faltar
#   ./setup-workspace.sh --dry-run  # mostra o que faria, sem escrever
#
# Idempotente: repositório já clonado é pulado, nunca sobrescrito.

set -euo pipefail

WORKSPACE="${AGE_WORKSPACE:-$HOME/AGE}"
GH_OWNER="ageferramentas-hub"

# Nome do repositório no GitHub → nome da pasta local.
REPOS=(
  "AGE-IA:AGE-IA"
  "Roger:Roger"
  "Cleverton:Cleverton"
)

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
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
    say "    + $local_name"
  else
    say "    ! $local_name — falhou ao clonar $url"
    say "      O repositório existe no GitHub com esse nome exato? É privado?"
  fi
done

step "Pronto."
say "Repositórios em $WORKSPACE"
say ""
say "App novo (EDITOR-DE-VIDEO, por exemplo) é uma pasta dentro do AGE-IA —"
say "não precisa de repositório separado:"
say ""
say "  mkdir \"$WORKSPACE/AGE-IA/EDITOR-DE-VIDEO\""
say ""
say "Para publicar skills e MCPs no escopo de usuário (valem em todos os apps),"
say "rode dentro do Roger:"
say ""
say "  cd \"$WORKSPACE/Roger\" && ./install.sh"

# Por último, porque é a única coisa aqui que exige ação antes do primeiro
# commit — e o git só reclama disso quando já está atrapalhando.
if ! git config --global user.name >/dev/null 2>&1; then
  say ""
  printf '\033[1m  ! Identidade do git não configurada\033[0m\n'
  say "    Sem isso o primeiro commit falha. Configure antes:"
  say ""
  say "      git config --global user.name \"Roger\""
  say "      git config --global user.email \"seu@email.com\""
fi
