#!/bin/bash

# ──────────────────────────────────────────────
#  setup.sh — Configuração inicial do ambiente
#  Execute este script UMA vez para configurar tudo
# ──────────────────────────────────────────────

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

print_step() { echo -e "\n${CYAN}▸ $1${RESET}"; }
print_ok()   { echo -e "${GREEN}✔ $1${RESET}"; }
print_warn() { echo -e "${YELLOW}⚠ $1${RESET}"; }
print_err()  { echo -e "${RED}✖ $1${RESET}"; }

REPO_BASE="$HOME/workspace/studies"
SCRIPTS_DIR="$HOME/.study-scripts"

echo ""
echo -e "${BOLD}${CYAN}════════════════════════════════════════${RESET}"
echo -e "${BOLD}  Configuração do Ambiente de Estudos${RESET}"
echo -e "${BOLD}${CYAN}════════════════════════════════════════${RESET}"

# ─── 1. Configurar GitHub user ────────────────

print_step "Configuração do GitHub"
echo -e -n "  Seu usuário do GitHub: "
read GITHUB_USER

if [[ -z "$GITHUB_USER" ]]; then
  print_warn "Usuário não informado. Você pode editar depois em ~/.study-scripts/new-study.sh"
  GITHUB_USER="seu-usuario"
fi

# ─── 2. Escolher editor ───────────────────────

print_step "Editor padrão"
echo "  1) IntelliJ IDEA"
echo "  2) VS Code"
echo "  3) Nenhum (abrir manualmente)"
echo -e -n "  Escolha [1/2/3]: "
read EDITOR_CHOICE

case "$EDITOR_CHOICE" in
  1) OPEN_EDITOR="intellij" ;;
  2) OPEN_EDITOR="vscode" ;;
  *) OPEN_EDITOR="none" ;;
esac

# ─── 3. Criar estrutura de pastas ─────────────

print_step "Criando estrutura de pastas"

mkdir -p "$REPO_BASE"/{in-progress,done}
mkdir -p "$HOME/workspace/projects"
print_ok "Criado: $REPO_BASE/in-progress/"
print_ok "Criado: $REPO_BASE/done/"
print_ok "Criado: $HOME/workspace/projects/"

# ─── 4. Instalar scripts ──────────────────────

print_step "Instalando scripts em $SCRIPTS_DIR"

mkdir -p "$SCRIPTS_DIR"

SCRIPT_DIR_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copiar scripts
cp "$SCRIPT_DIR_SOURCE/new-study.sh"  "$SCRIPTS_DIR/"
cp "$SCRIPT_DIR_SOURCE/move-study.sh" "$SCRIPTS_DIR/"

# Aplicar configurações no new-study.sh
sed -i "s|GITHUB_USER=\"\"|GITHUB_USER=\"$GITHUB_USER\"|g" "$SCRIPTS_DIR/new-study.sh"
sed -i "s|OPEN_EDITOR=\"intellij\"|OPEN_EDITOR=\"$OPEN_EDITOR\"|g" "$SCRIPTS_DIR/new-study.sh"
sed -i "s|REPO_BASE=\"\$HOME/workspace/studies\"|REPO_BASE=\"$REPO_BASE\"|g" "$SCRIPTS_DIR/new-study.sh"
sed -i "s|REPO_BASE=\"\$HOME/workspace/studies\"|REPO_BASE=\"$REPO_BASE\"|g" "$SCRIPTS_DIR/move-study.sh"

chmod +x "$SCRIPTS_DIR/new-study.sh"
chmod +x "$SCRIPTS_DIR/move-study.sh"

print_ok "Scripts instalados"

# ─── 5. Adicionar ao PATH ─────────────────────

print_step "Adicionando scripts ao PATH"

SHELL_RC="$HOME/.bashrc"
[[ -f "$HOME/.zshrc" ]] && SHELL_RC="$HOME/.zshrc"

ALIAS_BLOCK="
# ── Kotlin Study Scripts ──────────────────────
export PATH=\"\$PATH:$SCRIPTS_DIR\"
alias new-study='new-study.sh'
alias move-study='move-study.sh'
alias studies='ls $REPO_BASE/in-progress/'
# ─────────────────────────────────────────────"

if ! grep -q "Kotlin Study Scripts" "$SHELL_RC" 2>/dev/null; then
  echo "$ALIAS_BLOCK" >> "$SHELL_RC"
  print_ok "Aliases adicionados em $SHELL_RC"
else
  print_warn "Aliases já existem em $SHELL_RC"
fi

# ─── 6. Verificar dependências ────────────────

print_step "Verificando dependências"

check_dep() {
  if command -v "$1" &> /dev/null; then
    print_ok "$1 encontrado ($(command -v $1))"
  else
    print_warn "$1 não encontrado — $2"
  fi
}

check_dep "git"  "sudo apt install git"
check_dep "mvn"  "sudo apt install maven"
check_dep "java" "sudo apt install openjdk-21-jdk"
check_dep "gh"   "curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && echo 'deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main' | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null && sudo apt update && sudo apt install gh"

# ─── 7. Autenticar GitHub CLI ─────────────────

if command -v gh &> /dev/null; then
  if ! gh auth status &> /dev/null; then
    print_step "Autenticando GitHub CLI"
    gh auth login
  else
    print_ok "GitHub CLI já autenticado"
  fi
fi

# ─── Resumo ───────────────────────────────────

echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════════${RESET}"
echo -e "${BOLD}  Ambiente configurado com sucesso!${RESET}"
echo -e "${GREEN}════════════════════════════════════════${RESET}"
echo ""
echo -e "  ${BOLD}Para usar, reinicie o terminal ou rode:${RESET}"
echo -e "  ${CYAN}source $SHELL_RC${RESET}"
echo ""
echo -e "  ${BOLD}Depois, crie seu primeiro projeto:${RESET}"
echo -e "  ${CYAN}new-study -n meu-estudo -t solid${RESET}"
echo ""
echo -e "  ${BOLD}Comandos disponíveis:${RESET}"
echo -e "  ${CYAN}new-study${RESET}   → cria projeto novo"
echo -e "  ${CYAN}move-study${RESET}  → muda status do projeto"
echo -e "  ${CYAN}studies${RESET}     → lista projetos em andamento"
echo ""
echo -e "  ${BOLD}Estrutura criada em:${RESET}"
echo -e "  ${CYAN}~/workspace/${RESET}"
echo -e "  ├── studies/in-progress/   ← projetos de estudo ativos"
echo -e "  ├── studies/done/          ← estudos finalizados"
echo -e "  └── projects/              ← projetos reais / trabalho"
echo ""
