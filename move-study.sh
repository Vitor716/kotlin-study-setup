#!/bin/bash

# ──────────────────────────────────────────────
#  move-study.sh — Gerenciar projetos de estudo
# ──────────────────────────────────────────────

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'
DIM='\033[2m'

REPO_BASE="$HOME/workspace/studies"

print_ok()   { echo -e "${GREEN}✔ $1${RESET}"; }
print_err()  { echo -e "${RED}✖ $1${RESET}"; exit 1; }
print_warn() { echo -e "${YELLOW}⚠ $1${RESET}"; }

# ─── Listagem de projetos ─────────────────────

list_projects() {
  local total_in=0
  local total_done=0

  echo ""
  echo -e "${BOLD}${CYAN}════════════════════════════════════════${RESET}"
  echo -e "${BOLD}  Projetos de Estudo${RESET}"
  echo -e "${BOLD}${CYAN}════════════════════════════════════════${RESET}"

  # Em andamento
  echo -e "\n${BOLD}Em andamento:${RESET}"
  if compgen -G "$REPO_BASE/in-progress/*" > /dev/null 2>&1; then
    for dir in "$REPO_BASE/in-progress"/*/; do
      [[ -d "$dir" ]] || continue
      name=$(basename "$dir")
      total_in=$((total_in + 1))
      last=""
      if [[ -d "$dir/.git" ]]; then
        last=$(cd "$dir" && git log -1 --format="%cr" 2>/dev/null || echo "")
        [[ -n "$last" ]] && last=" ${DIM}(${last})${RESET}"
      fi
      echo -e "  ${CYAN}●${RESET} ${BOLD}${name}${RESET}${last}"
    done
  else
    echo -e "  ${DIM}(nenhum)${RESET}"
  fi

  # Finalizados
  echo -e "\n${BOLD}Finalizados:${RESET}"
  if compgen -G "$REPO_BASE/done/*" > /dev/null 2>&1; then
    for dir in "$REPO_BASE/done"/*/; do
      [[ -d "$dir" ]] || continue
      name=$(basename "$dir")
      total_done=$((total_done + 1))
      last=""
      if [[ -d "$dir/.git" ]]; then
        last=$(cd "$dir" && git log -1 --format="%cr" 2>/dev/null || echo "")
        [[ -n "$last" ]] && last=" ${DIM}(${last})${RESET}"
      fi
      echo -e "  ${GREEN}✔${RESET} ${name}${last}"
    done
  else
    echo -e "  ${DIM}(nenhum)${RESET}"
  fi

  echo ""
  echo -e "  ${DIM}Total: ${total_in} em andamento · ${total_done} finalizados${RESET}"
  echo -e "${BOLD}${GREEN}════════════════════════════════════════${RESET}"
  echo ""
}

# ─── Info de um projeto ───────────────────────

project_info() {
  local name="$1"
  local dir=""

  for status in "in-progress" "done"; do
    if [[ -d "$REPO_BASE/$status/$name" ]]; then
      dir="$REPO_BASE/$status/$name"
      current_status="$status"
      break
    fi
  done

  [[ -z "$dir" ]] && print_err "Projeto '$name' não encontrado."

  echo ""
  echo -e "${BOLD}${CYAN}── $name ──────────────────────────────${RESET}"
  echo -e "  ${BOLD}Status:${RESET}  $current_status"
  echo -e "  ${BOLD}Local:${RESET}   $dir"

  if [[ -d "$dir/.git" ]]; then
    branch=$(cd "$dir" && git branch --show-current 2>/dev/null || echo "?")
    commits=$(cd "$dir" && git rev-list --count HEAD 2>/dev/null || echo "0")
    last=$(cd "$dir" && git log -1 --format="%ci — %s" 2>/dev/null || echo "sem commits")
    echo -e "  ${BOLD}Branch:${RESET}  $branch"
    echo -e "  ${BOLD}Commits:${RESET} $commits"
    echo -e "  ${BOLD}Último:${RESET}  $last"
  else
    echo -e "  ${YELLOW}⚠ Sem repositório git${RESET}"
  fi

  if [[ -f "$dir/README.md" ]]; then
    echo -e "  ${BOLD}README:${RESET}  sim"
  fi
  echo ""
}

# ─── Uso ──────────────────────────────────────

usage() {
  echo -e "${BOLD}Uso:${RESET} move-study.sh <comando> [args]"
  echo ""
  echo -e "${BOLD}Comandos:${RESET}"
  echo "  <projeto> <status>     Move projeto para in-progress ou done"
  echo "  -l, --list             Lista todos os projetos com último commit"
  echo "  -i, --info <projeto>   Mostra detalhes de um projeto"
  echo "  -h, --help             Exibe esta ajuda"
  echo ""
  echo -e "${BOLD}Status disponíveis:${RESET}"
  echo "  in-progress   projeto em andamento"
  echo "  done          projeto finalizado"
  echo ""
  echo -e "${BOLD}Exemplos:${RESET}"
  echo "  move-study solid-principles done"
  echo "  move-study kotlin-flows in-progress"
  echo "  move-study --list"
  echo "  move-study --info solid-principles"
  exit 0
}

# ─── Roteamento de argumentos ─────────────────

case "$1" in
  -l|--list)  list_projects; exit 0 ;;
  -i|--info)  [[ -z "$2" ]] && print_err "Informe o nome do projeto."; project_info "$2"; exit 0 ;;
  -h|--help)  usage ;;
  "")         list_projects; exit 0 ;;
esac

PROJECT_NAME="$1"
TARGET_STATUS="$2"

if [[ -z "$PROJECT_NAME" || -z "$TARGET_STATUS" ]]; then
  usage
fi

if [[ "$TARGET_STATUS" != "in-progress" && "$TARGET_STATUS" != "done" ]]; then
  print_err "Status inválido. Use: in-progress | done"
fi

# ─── Encontrar o projeto ──────────────────────

SOURCE=""
CURRENT_STATUS=""

for status in "in-progress" "done"; do
  if [[ -d "$REPO_BASE/$status/$PROJECT_NAME" ]]; then
    SOURCE="$REPO_BASE/$status/$PROJECT_NAME"
    CURRENT_STATUS="$status"
    break
  fi
done

if [[ -z "$SOURCE" ]]; then
  print_err "Projeto '$PROJECT_NAME' não encontrado em $REPO_BASE"
fi

if [[ "$CURRENT_STATUS" == "$TARGET_STATUS" ]]; then
  print_warn "Projeto já está com status '$TARGET_STATUS'"
  exit 0
fi

# ─── Mover ────────────────────────────────────

DEST="$REPO_BASE/$TARGET_STATUS/$PROJECT_NAME"
mkdir -p "$REPO_BASE/$TARGET_STATUS"
mv "$SOURCE" "$DEST"

# Atualizar README
if [[ -f "$DEST/README.md" ]]; then
  sed -i "s/\*\*Status:\*\* .*/\*\*Status:\*\* $TARGET_STATUS/" "$DEST/README.md"
fi

# Commit de status
if [[ -d "$DEST/.git" ]]; then
  cd "$DEST"
  git add README.md 2>/dev/null || true
  git commit -q -m "chore: status atualizado para $TARGET_STATUS" 2>/dev/null || true
fi

print_ok "Projeto movido: '${CURRENT_STATUS}' → '${TARGET_STATUS}'"
echo -e "  ${CYAN}$DEST${RESET}"
