# move-study — Guia Completo

Script para gerenciar o ciclo de vida dos seus projetos de estudo: mover entre status, listar com informações de git, e inspecionar projetos individualmente.

---

## Instalação

O `move-study` é instalado automaticamente pelo `setup.sh` e fica disponível como comando global:

```bash
./setup.sh        # instala e configura tudo
source ~/.bashrc  # ativa no terminal atual
```

Após isso você pode chamar `move-study` de qualquer diretório.

---

## Estrutura de pastas gerenciada

```
~/workspace/
├── studies/
│   ├── in-progress/    ← projetos ativos
│   └── done/           ← projetos finalizados
└── kotlin-study-setup/ ← scripts (este repo)
```

Tanto projetos Maven (simples) quanto Spring Boot Modulith (--modular) ficam em `studies/`.

---

## Comandos

### Listar todos os projetos

```bash
move-study
move-study --list
move-study -l
```

Mostra todos os projetos organizados por status, com data do último commit git.

**Saída exemplo:**
```
Em andamento:
  ● solid-principles  (2 days ago)
  ● kotlin-flows      (5 hours ago)

Finalizados:
  ✔ design-patterns   (3 weeks ago)

  Total: 2 em andamento · 1 finalizados
```

---

### Mover projeto de status

```bash
move-study <nome-do-projeto> <status>
```

Valores de status: `in-progress` ou `done`

**Exemplos:**

```bash
# Marcar estudo como finalizado
move-study solid-principles done

# Retomar estudo pausado
move-study kotlin-flows in-progress
```

O script:
1. Move a pasta para o diretório correto
2. Atualiza o campo `**Status:**` no `README.md` do projeto
3. Cria um commit automático com a mudança (se o projeto tiver `.git`)

---

### Ver detalhes de um projeto

```bash
move-study --info <nome-do-projeto>
move-study -i <nome-do-projeto>
```

Mostra informações do projeto: localização, status atual, branch, número de commits e último commit.

**Saída exemplo:**
```
── solid-principles ──────────────────────────
  Status:  in-progress
  Local:   ~/workspace/studies/in-progress/solid-principles
  Branch:  main
  Commits: 12
  Último:  2026-05-19 14:32:00 — feat: adiciona exemplo de OCP
```

---

### Ajuda

```bash
move-study --help
move-study -h
```

---

## Fluxo de vida de um projeto

```
new-study → in-progress → done
                ↑              |
                └──────────────┘  (pode voltar se quiser continuar)
```

**Criou um novo estudo:**
```bash
new-study -n solid-principles -t solid
# projeto criado em ~/workspace/studies/in-progress/solid-principles
```

**Finalizou o estudo:**
```bash
move-study solid-principles done
# movido para ~/workspace/studies/done/solid-principles
```

**Decidiu retomar:**
```bash
move-study solid-principles in-progress
# voltou para ~/workspace/studies/in-progress/solid-principles
```

**Verificou o que está ativo:**
```bash
move-study --list
# ou: studies  (alias que lista só o in-progress)
```

---

## Alias rápido

O `setup.sh` também instala o alias `studies` que lista apenas os projetos em andamento:

```bash
studies
# equivale a: ls ~/workspace/studies/in-progress/
```

---

## Integração com new-study

Os dois scripts compartilham o mesmo `REPO_BASE` (`~/workspace/studies`). Tudo que o `new-study` cria, o `move-study` consegue gerenciar — sem configuração extra.

---

## Localização dos scripts instalados

```bash
~/.study-scripts/
├── new-study.sh
└── move-study.sh
```

Para editar o comportamento após a instalação, edite os arquivos em `~/.study-scripts/`.
