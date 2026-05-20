# Kotlin Study Setup

Scripts para criar e gerenciar projetos de estudo em Kotlin + Maven no WSL, sem perder tempo com configuração.

Dois tipos de projeto disponíveis: **simples** (pacote único) e **modular** (monolito multi-módulo Maven com arquitetura em camadas).

---

## Estrutura de pastas gerada

```
~/workspace/
├── studies/
│   ├── in-progress/    ← projetos de estudo ativos
│   └── done/           ← estudos finalizados
└── kotlin-study-setup/ ← este repositório (scripts)
```

---

## Instalação (só uma vez)

```bash
# 1. Clone o repositório
git clone https://github.com/Vitor716/kotlin-study-setup
cd kotlin-study-setup

# 2. Dê permissão e rode o setup
chmod +x setup.sh new-study.sh move-study.sh
./setup.sh

# 3. Ative no terminal atual
source ~/.bashrc
```

O `setup.sh` vai:
- Criar a estrutura `~/workspace/studies/{in-progress,done}` e `~/workspace/projects/`
- Instalar os scripts no PATH (`~/.study-scripts/`)
- Configurar os aliases `new-study`, `move-study` e `studies`
- Verificar dependências (git, mvn, java, gh)
- Autenticar o GitHub CLI se necessário

> **Atenção:** após o setup, use `new-study` (sem `.sh`).  
> Se ainda não rodou o setup, chame diretamente: `./new-study.sh`

---

## Uso diário

### Criar projeto simples

```bash
new-study -n solid-principles -t solid
new-study -n kotlin-flows -t coroutines
new-study -n design-patterns -t patterns --private
```

### Criar projeto modular (monolito)

```bash
new-study -n clean-arch-study -t ddd --modular
new-study -n hexagonal-arch -t architecture --modular --private
```

### Flags do new-study

| Flag | Descrição | Exemplo |
|------|-----------|---------|
| `-n` | Nome do projeto | `-n solid-principles` |
| `-t` | Tópico de estudo | `-t coroutines` |
| `-s` | Status inicial | `-s done` |
| `-m` | Projeto modular (multi-módulo Maven) | `--modular` |
| `-p` | Repo privado no GitHub | `--private` |

---

## Tipos de projeto

### Simples (padrão)

Projeto único com um pacote. Ideal para estudar conceitos pontuais.

```
project-name/
├── pom.xml
├── README.md
├── docs/anotacoes.md
└── src/
    ├── main/kotlin/br/com/study/topic/
    │   └── Main.kt
    └── test/kotlin/br/com/study/topic/
        └── ExampleTest.kt
```

### Modular (`--modular`)

Spring Boot + Spring Modulith, seguindo o padrão do projeto `auditoria-corridas`.
Cada subpacote do pacote raiz é um módulo Spring Modulith com fronteiras enforçadas automaticamente.
Ideal para estudar DDD, Clean Architecture, Hexagonal, SOLID aplicado.

```
project-name/                        ← Gradle project
├── build.gradle.kts
├── settings.gradle.kts
├── src/main/kotlin/{project}/
│   ├── {Project}Application.kt      ← @SpringBootApplication
│   ├── {topic}/                     ← módulo Spring Modulith
│   │   ├── model/{Topic}.kt         ← @Entity JPA
│   │   ├── repository/              ← JpaRepository
│   │   ├── service/                 ← @Service
│   │   └── controller/              ← @RestController
│   └── shared/exception/            ← @RestControllerAdvice
└── src/main/resources/
    └── application.properties       ← H2 in-memory pronto para uso
```

**Dependências pré-configuradas (modular):**

| Dependência | Função |
|---|---|
| `spring-boot-starter-web` | REST API |
| `spring-boot-starter-data-jpa` | JPA + repositórios |
| `spring-modulith-starter-core` | Fronteiras de módulo |
| `spring-modulith-starter-test` | Testes de módulo |
| `h2` (runtime) | Banco in-memory para estudo |

**Para rodar:**

```bash
./gradlew bootRun
# App: http://localhost:8080
# H2 Console: http://localhost:8080/h2-console
```

---

## Gerenciar projetos com move-study

```bash
# Listar todos os projetos (com data do último commit)
move-study --list

# Mover para finalizado
move-study solid-principles done

# Retomar um estudo
move-study solid-principles in-progress

# Ver detalhes de um projeto (git info, commits, etc.)
move-study --info solid-principles

# Atalho para ver apenas os ativos
studies
```

Documentação completa: [docs/move-study.md](docs/move-study.md)

---

## Dependências pré-configuradas

**Projeto simples (Maven):**

| Dependência | Versão | Escopo |
|---|---|---|
| `kotlin-stdlib` | 2.0.21 | compile |
| `kotlinx-coroutines-core` | 1.8.1 | compile |
| `junit-jupiter` | 5.10.2 | test |
| `kotlin-test-junit5` | 2.0.21 | test |

**Projeto modular (Gradle + Spring Boot):**

| Dependência | Versão |
|---|---|
| Spring Boot | 4.0.5 |
| Kotlin | 2.2.21 |
| Spring Modulith BOM | 2.0.0 |
| H2 (in-memory) | gerenciado pelo BOM |

---

## Comandos úteis

```bash
# Projeto simples (Maven)
mvn test
mvn compile
mvn exec:java

# Projeto modular (Gradle)
./gradlew bootRun     # sobe a aplicação
./gradlew test        # roda os testes
./gradlew build       # compila + testa + empacota
```

---

## Dependências necessárias no WSL

```bash
sudo apt update

# Java 21
sudo apt install openjdk-21-jdk

# Maven
sudo apt install maven

# GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh

gh auth login
```

---

## IntelliJ no WSL

Para abrir o IntelliJ pelo terminal do WSL, adicione o launcher ao PATH:

```bash
# Ajuste para sua versão e caminho:
echo 'export PATH="$PATH:/mnt/c/Program Files/JetBrains/IntelliJ IDEA/bin"' >> ~/.bashrc
```

Ou abra manualmente com `File > Open` e navegue até `\\wsl$\Ubuntu\home\seu-usuario\workspace\studies`.

---

## Evoluindo o script

O projeto é mantido como base viva — contribuições e ajustes são bem-vindos.

Ideias para próximas evoluções:
- Suporte a Gradle (além de Maven)
- Template para projetos Spring Boot
- Template para projetos Ktor
- Opção de adicionar MockK às dependências de teste
- Suporte a módulos customizados no `--modular`
- Comando `move-study --archive` para comprimir projetos finalizados

Abra uma issue ou PR com sua sugestão.
