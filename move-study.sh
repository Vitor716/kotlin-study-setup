#!/bin/bash

# ──────────────────────────────────────────────
#  move-study.sh — Mover projeto entre status
# ──────────────────────────────────────────────

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

REPO_BASE="$HOME/repository"

print_ok()  { echo -e "${GREEN}✔ $1${RESET}"; }
print_err() { echo -e "${RED}✖ $1${RESET}"; exit 1; }

# ─── Listar projetos ──────────────────────────

list_projects() {
  echo -e "\n${BOLD}Projetos em andamento:${RESET}"
  ls "$REPO_BASE/in-progress/" 2>/dev/null | sed 's/^/  - /' || echo "  (nenhum)"

  echo -e "\n${BOLD}Projetos finalizados:${RESET}"
  ls "$REPO_BASE/done/" 2>/dev/null | sed 's/^/  - /' || echo "  (nenhum)"
  echo ""
}

# ─── Argumentos ───────────────────────────────

if [[ "$1" == "--list" || "$1" == "-l" ]]; then
  list_projects
  exit 0
fi

PROJECT_NAME="$1"
TARGET_STATUS="$2"

if [[ -z "$PROJECT_NAME" || -z "$TARGET_STATUS" ]]; then
  echo -e "${BOLD}Uso:${RESET} ./move-study.sh <nome-do-projeto> <status>"
  echo ""
  echo -e "  ${BOLD}Status disponíveis:${RESET} in-progress | done"
  echo ""
  echo -e "  ${BOLD}Exemplos:${RESET}"
  echo "    ./move-study.sh solid-principles done"
  echo "    ./move-study.sh kotlin-flows in-progress"
  echo ""
  echo -e "  ${BOLD}Listar projetos:${RESET}"
  echo "    ./move-study.sh --list"
  exit 1
fi

if [[ "$TARGET_STATUS" != "in-progress" && "$TARGET_STATUS" != "done" ]]; then
  print_err "Status inválido. Use: in-progress | done"
fi

# ─── Encontrar projeto ────────────────────────

SOURCE=""
for STATUS in "in-progress" "done"; do
  if [[ -d "$REPO_BASE/$STATUS/$PROJECT_NAME" ]]; then
    SOURCE="$REPO_BASE/$STATUS/$PROJECT_NAME"
    CURRENT_STATUS="$STATUS"
    break
  fi
done

if [[ -z "$SOURCE" ]]; then
  print_err "Projeto '$PROJECT_NAME' não encontrado em $REPO_BASE"
fi

if [[ "$CURRENT_STATUS" == "$TARGET_STATUS" ]]; then
  echo -e "${YELLOW}⚠ Projeto já está com status '$TARGET_STATUS'${RESET}"
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
cd "$DEST"
git add README.md 2>/dev/null || true
git commit -q -m "chore: status atualizado para $TARGET_STATUS" 2>/dev/null || true

print_ok "Projeto movido: '$CURRENT_STATUS' → '$TARGET_STATUS'"
echo -e "  📁 $DEST"
