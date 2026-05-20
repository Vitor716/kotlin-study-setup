# Kotlin Study Setup

Scripts para criar e gerenciar projetos de estudo em Kotlin + Maven no WSL, sem perder tempo com configuração.

Dois tipos de projeto disponíveis: **simples** (pacote único) e **modular** (monolito multi-módulo Maven com arquitetura em camadas).

---

## Instalação (só uma vez)

```bash
# 1. Clone ou copie a pasta kotlin-study-setup para o seu WSL
# 2. Entre na pasta e rode:

chmod +x setup.sh new-study.sh move-study.sh
./setup.sh
source ~/.bashrc
```

O `setup.sh` vai:
- Criar a estrutura `~/repository/in-progress/` e `~/repository/done/`
- Instalar os scripts no PATH
- Verificar dependências (git, mvn, java, gh)
- Autenticar o GitHub CLI se necessário

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

### Flags disponíveis

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

Monolito multi-módulo Maven com separação de responsabilidades em camadas.
Ideal para estudar DDD, Clean Architecture, Hexagonal, SOLID aplicado.

```
project-name/
├── pom.xml                          ← parent (packaging=pom)
├── README.md
├── docs/anotacoes.md
│
├── domain/                          ← entidades, value objects, portas
│   └── src/main/kotlin/.../domain/
│       ├── model/User.kt
│       └── port/UserRepository.kt
│
├── application/                     ← casos de uso
│   └── src/main/kotlin/.../application/
│       └── usecase/
│           ├── CreateUserUseCase.kt
│           └── FindUserUseCase.kt
│
├── infrastructure/                  ← implementações de repos e adapters
│   └── src/main/kotlin/.../infrastructure/
│       └── repository/
│           └── InMemoryUserRepository.kt
│
└── api/                             ← wiring, ponto de entrada
    └── src/main/kotlin/.../api/
        └── Main.kt
```

**Dependências entre módulos:**

```
api → application → domain
api → infrastructure → domain
```

O `domain` não depende de nada interno — é o núcleo isolado.

---

## Gerenciar projetos

```bash
# Ver projetos em andamento
studies

# Mover para finalizado
move-study solid-principles done

# Mover de volta para em andamento
move-study solid-principles in-progress

# Listar todos
move-study --list
```

---

## Dependências pré-configuradas

| Dependência | Versão | Escopo |
|---|---|---|
| `kotlin-stdlib` | 2.0.21 | compile |
| `kotlinx-coroutines-core` | 1.8.1 | compile |
| `junit-jupiter-api` | 5.10.2 | test |
| `junit-jupiter-engine` | 5.10.2 | test |
| `kotlin-test-junit5` | 2.0.21 | test |

No projeto modular, todas as versões são gerenciadas no parent pom via `<dependencyManagement>`.

---

## Comandos Maven úteis

```bash
# Projeto simples
mvn test
mvn compile
mvn exec:java

# Projeto modular (da raiz)
mvn compile              # compila todos os módulos
mvn test                 # testa todos os módulos
mvn -pl api exec:java    # executa o módulo api
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

Ou abra manualmente com `File > Open` e navegue até `\\wsl$\Ubuntu\home\seu-usuario\repository`.

---

## Evoluindo o script

O projeto é mantido como base viva — contribuições e ajustes são bem-vindos.

Ideias para próximas evoluções:
- Suporte a Gradle (além de Maven)
- Template para projetos Spring Boot
- Template para projetos Ktor
- Opção de adicionar MockK às dependências de teste
- Suporte a módulos customizados no `--modular`

Abra uma issue ou PR com sua sugestão.
