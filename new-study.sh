#!/bin/bash

# ─────────────────────────────────────────────
#  new-study.sh — Kotlin Study Project Generator
# ─────────────────────────────────────────────

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

REPO_BASE="$HOME/workspace/studies"
GITHUB_USER=""
OPEN_EDITOR="intellij"

print_step() { echo -e "\n${CYAN}▸ $1${RESET}"; }
print_ok()   { echo -e "${GREEN}✔ $1${RESET}"; }
print_warn() { echo -e "${YELLOW}⚠ $1${RESET}"; }
print_err()  { echo -e "${RED}✖ $1${RESET}"; exit 1; }

usage() {
  echo -e "${BOLD}Uso:${RESET} ./new-study.sh [opções]"
  echo ""
  echo -e "${BOLD}Opções:${RESET}"
  echo "  -n, --name       Nome do projeto (ex: design-patterns)"
  echo "  -t, --topic      Tópico de estudo (ex: solid, collections, coroutines)"
  echo "  -s, --status     Status inicial: in-progress | done  (padrão: in-progress)"
  echo "  -m, --modular    Cria projeto como monolito modular (multi-módulo Maven)"
  echo "  -p, --private    Cria o repositório GitHub como privado"
  echo "  -h, --help       Exibe esta ajuda"
  echo ""
  echo -e "${BOLD}Tipos de projeto:${RESET}"
  echo "  simples (padrão)  — src/main/kotlin em pacote único"
  echo "  modular (-m)      — módulos: domain / application / infrastructure / api"
  echo ""
  echo -e "${BOLD}Exemplos:${RESET}"
  echo "  ./new-study.sh -n solid-principles -t solid"
  echo "  ./new-study.sh -n kotlin-flows -t coroutines --private"
  echo "  ./new-study.sh -n clean-arch-study -t ddd --modular"
  exit 0
}

# ─── Argumentos ───────────────────────────────

PROJECT_NAME=""
TOPIC=""
STATUS="in-progress"
PRIVATE_FLAG=""
PROJECT_TYPE="simple"

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -n|--name)    PROJECT_NAME="$2"; shift ;;
    -t|--topic)   TOPIC="$2"; shift ;;
    -s|--status)  STATUS="$2"; shift ;;
    -m|--modular) PROJECT_TYPE="modular" ;;
    -p|--private) PRIVATE_FLAG="--private" ;;
    -h|--help)    usage ;;
    *) print_err "Argumento desconhecido: $1" ;;
  esac
  shift
done

# ─── Validações ───────────────────────────────

if [[ -z "$PROJECT_NAME" ]]; then
  echo -e -n "${CYAN}▸ Nome do projeto:${RESET} "
  read PROJECT_NAME
fi

if [[ -z "$PROJECT_NAME" ]]; then
  print_err "Nome do projeto é obrigatório."
fi

if [[ -z "$TOPIC" ]]; then
  echo -e -n "${CYAN}▸ Tópico de estudo (ex: solid, ddd, coroutines):${RESET} "
  read TOPIC
fi

TOPIC="${TOPIC:-geral}"
TOPIC="${TOPIC// /-}"

if [[ "$STATUS" != "in-progress" && "$STATUS" != "done" ]]; then
  print_err "Status inválido: $STATUS. Use: in-progress | done"
fi

# ─── Variáveis derivadas ──────────────────────

TARGET_DIR="$REPO_BASE/$STATUS/$PROJECT_NAME"
GROUP_ID="br.com.study.${TOPIC//-/_}"
ARTIFACT_ID="$PROJECT_NAME"
PACKAGE_PATH="${GROUP_ID//./\/}"

if [[ -d "$TARGET_DIR" ]]; then
  print_err "Projeto já existe em: $TARGET_DIR"
fi

# ─────────────────────────────────────────────
#  ARQUIVOS COMPARTILHADOS
# ─────────────────────────────────────────────

write_gitignore() {
  cat > "$TARGET_DIR/.gitignore" <<EOF
# Maven
target/
*.class

# IntelliJ IDEA
.idea/
*.iml
*.ipr
*.iws
out/

# VS Code
.vscode/

# OS
.DS_Store
Thumbs.db

# Logs
*.log
EOF
  print_ok ".gitignore gerado"
}

write_docs() {
  mkdir -p "$TARGET_DIR/docs"
  cat > "$TARGET_DIR/docs/anotacoes.md" <<EOF
# Anotações — ${PROJECT_NAME}

## ${TOPIC}

Use este arquivo para registrar descobertas, dúvidas e links úteis durante o estudo.
EOF
}

# ─────────────────────────────────────────────
#  PROJETO SIMPLES
# ─────────────────────────────────────────────

create_simple_project() {
  print_step "Criando estrutura simples em $TARGET_DIR"

  mkdir -p "$TARGET_DIR/src/main/kotlin/$PACKAGE_PATH"
  mkdir -p "$TARGET_DIR/src/main/resources"
  mkdir -p "$TARGET_DIR/src/test/kotlin/$PACKAGE_PATH"
  mkdir -p "$TARGET_DIR/src/test/resources"

  print_ok "Estrutura de pastas criada"

  # ── pom.xml ──
  print_step "Gerando pom.xml"
  cat > "$TARGET_DIR/pom.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>${GROUP_ID}</groupId>
    <artifactId>${ARTIFACT_ID}</artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>jar</packaging>

    <name>${PROJECT_NAME}</name>
    <description>Estudo sobre: ${TOPIC}</description>

    <properties>
        <kotlin.version>2.0.21</kotlin.version>
        <kotlin.code.style>official</kotlin.code.style>
        <junit.version>5.10.2</junit.version>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.jetbrains.kotlin</groupId>
            <artifactId>kotlin-stdlib</artifactId>
            <version>\${kotlin.version}</version>
        </dependency>

        <!-- Coroutines (remova se não precisar) -->
        <dependency>
            <groupId>org.jetbrains.kotlinx</groupId>
            <artifactId>kotlinx-coroutines-core</artifactId>
            <version>1.8.1</version>
        </dependency>

        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-api</artifactId>
            <version>\${junit.version}</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-engine</artifactId>
            <version>\${junit.version}</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.jetbrains.kotlin</groupId>
            <artifactId>kotlin-test-junit5</artifactId>
            <version>\${kotlin.version}</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <sourceDirectory>\${project.basedir}/src/main/kotlin</sourceDirectory>
        <testSourceDirectory>\${project.basedir}/src/test/kotlin</testSourceDirectory>

        <plugins>
            <plugin>
                <groupId>org.jetbrains.kotlin</groupId>
                <artifactId>kotlin-maven-plugin</artifactId>
                <version>\${kotlin.version}</version>
                <executions>
                    <execution>
                        <id>compile</id>
                        <goals><goal>compile</goal></goals>
                    </execution>
                    <execution>
                        <id>test-compile</id>
                        <goals><goal>test-compile</goal></goals>
                    </execution>
                </executions>
            </plugin>

            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>3.2.5</version>
            </plugin>

            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-jar-plugin</artifactId>
                <version>3.3.0</version>
                <configuration>
                    <archive>
                        <manifest>
                            <mainClass>${GROUP_ID}.MainKt</mainClass>
                        </manifest>
                    </archive>
                </configuration>
            </plugin>

            <plugin>
                <groupId>org.codehaus.mojo</groupId>
                <artifactId>exec-maven-plugin</artifactId>
                <version>3.1.0</version>
                <configuration>
                    <mainClass>${GROUP_ID}.MainKt</mainClass>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
EOF
  print_ok "pom.xml gerado"

  # ── Main.kt ──
  print_step "Criando Main.kt"
  cat > "$TARGET_DIR/src/main/kotlin/$PACKAGE_PATH/Main.kt" <<EOF
package ${GROUP_ID}

fun main() {
    println("Estudo iniciado: ${PROJECT_NAME}")
}
EOF
  print_ok "Main.kt criado"

  # ── ExampleTest.kt ──
  print_step "Criando teste de exemplo"
  cat > "$TARGET_DIR/src/test/kotlin/$PACKAGE_PATH/ExampleTest.kt" <<EOF
package ${GROUP_ID}

import org.junit.jupiter.api.Test
import kotlin.test.assertEquals

class ExampleTest {

    @Test
    fun \`deve passar como exemplo inicial\`() {
        val resultado = 1 + 1
        assertEquals(2, resultado)
    }
}
EOF
  print_ok "ExampleTest.kt criado"

  # ── README.md ──
  cat > "$TARGET_DIR/README.md" <<EOF
# ${PROJECT_NAME}

> **Tópico:** ${TOPIC}
> **Status:** ${STATUS}
> **Linguagem:** Kotlin + Maven

## Objetivo

Descreva aqui o que você está estudando e por quê.

## Conceitos abordados

- [ ] Conceito 1
- [ ] Conceito 2
- [ ] Conceito 3

## Estrutura

\`\`\`
src/
├── main/kotlin/         # Código principal
└── test/kotlin/         # Testes
docs/                    # Anotações e referências
\`\`\`

## Como rodar

\`\`\`bash
mvn compile
mvn test
mvn exec:java
\`\`\`

## Anotações

> Adicione suas anotações de estudo aqui.

## Referências

- [Kotlin Docs](https://kotlinlang.org/docs/home.html)
EOF
}

# ─────────────────────────────────────────────
#  PROJETO MODULAR (monolito multi-módulo Maven)
# ─────────────────────────────────────────────
#
#  Arquitetura:
#   domain         — entidades, value objects, portas (interfaces)
#   application    — casos de uso, orquestração de regras
#   infrastructure — implementações de repositórios e adapters
#   api            — composição dos módulos, ponto de entrada
# ─────────────────────────────────────────────

create_modular_project() {
  print_step "Criando monolito modular em $TARGET_DIR"

  local DOMAIN_PKG="${GROUP_ID}.domain"
  local APP_PKG="${GROUP_ID}.application"
  local INFRA_PKG="${GROUP_ID}.infrastructure"
  local API_PKG="${GROUP_ID}.api"

  local DOMAIN_PATH="${PACKAGE_PATH}/domain"
  local APP_PATH="${PACKAGE_PATH}/application"
  local INFRA_PATH="${PACKAGE_PATH}/infrastructure"
  local API_PATH="${PACKAGE_PATH}/api"

  # Estrutura de diretórios
  mkdir -p "$TARGET_DIR/domain/src/main/kotlin/$DOMAIN_PATH/model"
  mkdir -p "$TARGET_DIR/domain/src/main/kotlin/$DOMAIN_PATH/port"
  mkdir -p "$TARGET_DIR/domain/src/main/resources"
  mkdir -p "$TARGET_DIR/domain/src/test/kotlin/$DOMAIN_PATH/model"
  mkdir -p "$TARGET_DIR/domain/src/test/resources"

  mkdir -p "$TARGET_DIR/application/src/main/kotlin/$APP_PATH/usecase"
  mkdir -p "$TARGET_DIR/application/src/main/resources"
  mkdir -p "$TARGET_DIR/application/src/test/kotlin/$APP_PATH/usecase"
  mkdir -p "$TARGET_DIR/application/src/test/resources"

  mkdir -p "$TARGET_DIR/infrastructure/src/main/kotlin/$INFRA_PATH/repository"
  mkdir -p "$TARGET_DIR/infrastructure/src/main/resources"
  mkdir -p "$TARGET_DIR/infrastructure/src/test/kotlin/$INFRA_PATH/repository"
  mkdir -p "$TARGET_DIR/infrastructure/src/test/resources"

  mkdir -p "$TARGET_DIR/api/src/main/kotlin/$API_PATH"
  mkdir -p "$TARGET_DIR/api/src/main/resources"

  print_ok "Estrutura de módulos criada"

  # ── Parent pom.xml ──
  print_step "Gerando pom.xml (parent + módulos)"
  cat > "$TARGET_DIR/pom.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>${GROUP_ID}</groupId>
    <artifactId>${ARTIFACT_ID}</artifactId>
    <version>1.0-SNAPSHOT</version>
    <packaging>pom</packaging>

    <name>${PROJECT_NAME} — Parent</name>
    <description>Monolito Modular — Estudo: ${TOPIC}</description>

    <modules>
        <module>domain</module>
        <module>application</module>
        <module>infrastructure</module>
        <module>api</module>
    </modules>

    <properties>
        <kotlin.version>2.0.21</kotlin.version>
        <kotlin.code.style>official</kotlin.code.style>
        <junit.version>5.10.2</junit.version>
        <coroutines.version>1.8.1</coroutines.version>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.jetbrains.kotlin</groupId>
                <artifactId>kotlin-stdlib</artifactId>
                <version>\${kotlin.version}</version>
            </dependency>
            <dependency>
                <groupId>org.jetbrains.kotlinx</groupId>
                <artifactId>kotlinx-coroutines-core</artifactId>
                <version>\${coroutines.version}</version>
            </dependency>
            <dependency>
                <groupId>org.junit.jupiter</groupId>
                <artifactId>junit-jupiter-api</artifactId>
                <version>\${junit.version}</version>
                <scope>test</scope>
            </dependency>
            <dependency>
                <groupId>org.junit.jupiter</groupId>
                <artifactId>junit-jupiter-engine</artifactId>
                <version>\${junit.version}</version>
                <scope>test</scope>
            </dependency>
            <dependency>
                <groupId>org.jetbrains.kotlin</groupId>
                <artifactId>kotlin-test-junit5</artifactId>
                <version>\${kotlin.version}</version>
                <scope>test</scope>
            </dependency>
            <!-- Módulos internos -->
            <dependency>
                <groupId>${GROUP_ID}</groupId>
                <artifactId>domain</artifactId>
                <version>\${project.version}</version>
            </dependency>
            <dependency>
                <groupId>${GROUP_ID}</groupId>
                <artifactId>application</artifactId>
                <version>\${project.version}</version>
            </dependency>
            <dependency>
                <groupId>${GROUP_ID}</groupId>
                <artifactId>infrastructure</artifactId>
                <version>\${project.version}</version>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <build>
        <pluginManagement>
            <plugins>
                <plugin>
                    <groupId>org.jetbrains.kotlin</groupId>
                    <artifactId>kotlin-maven-plugin</artifactId>
                    <version>\${kotlin.version}</version>
                    <executions>
                        <execution>
                            <id>compile</id>
                            <goals><goal>compile</goal></goals>
                            <configuration>
                                <sourceDirs>
                                    <sourceDir>\${project.basedir}/src/main/kotlin</sourceDir>
                                </sourceDirs>
                            </configuration>
                        </execution>
                        <execution>
                            <id>test-compile</id>
                            <goals><goal>test-compile</goal></goals>
                            <configuration>
                                <sourceDirs>
                                    <sourceDir>\${project.basedir}/src/test/kotlin</sourceDir>
                                </sourceDirs>
                            </configuration>
                        </execution>
                    </executions>
                </plugin>
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-surefire-plugin</artifactId>
                    <version>3.2.5</version>
                </plugin>
            </plugins>
        </pluginManagement>
    </build>
</project>
EOF

  # ── domain/pom.xml ──
  cat > "$TARGET_DIR/domain/pom.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>${GROUP_ID}</groupId>
        <artifactId>${ARTIFACT_ID}</artifactId>
        <version>1.0-SNAPSHOT</version>
    </parent>

    <artifactId>domain</artifactId>
    <description>Entidades, regras de negócio e portas (interfaces)</description>

    <dependencies>
        <dependency>
            <groupId>org.jetbrains.kotlin</groupId>
            <artifactId>kotlin-stdlib</artifactId>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-api</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-engine</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.jetbrains.kotlin</groupId>
            <artifactId>kotlin-test-junit5</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.jetbrains.kotlin</groupId>
                <artifactId>kotlin-maven-plugin</artifactId>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
EOF

  # ── application/pom.xml ──
  cat > "$TARGET_DIR/application/pom.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>${GROUP_ID}</groupId>
        <artifactId>${ARTIFACT_ID}</artifactId>
        <version>1.0-SNAPSHOT</version>
    </parent>

    <artifactId>application</artifactId>
    <description>Casos de uso e orquestração de regras de negócio</description>

    <dependencies>
        <dependency>
            <groupId>org.jetbrains.kotlin</groupId>
            <artifactId>kotlin-stdlib</artifactId>
        </dependency>
        <dependency>
            <groupId>${GROUP_ID}</groupId>
            <artifactId>domain</artifactId>
        </dependency>
        <dependency>
            <groupId>org.jetbrains.kotlinx</groupId>
            <artifactId>kotlinx-coroutines-core</artifactId>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-api</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-engine</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.jetbrains.kotlin</groupId>
            <artifactId>kotlin-test-junit5</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.jetbrains.kotlin</groupId>
                <artifactId>kotlin-maven-plugin</artifactId>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
EOF

  # ── infrastructure/pom.xml ──
  cat > "$TARGET_DIR/infrastructure/pom.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>${GROUP_ID}</groupId>
        <artifactId>${ARTIFACT_ID}</artifactId>
        <version>1.0-SNAPSHOT</version>
    </parent>

    <artifactId>infrastructure</artifactId>
    <description>Implementações de repositórios, adapters e integrações externas</description>

    <dependencies>
        <dependency>
            <groupId>org.jetbrains.kotlin</groupId>
            <artifactId>kotlin-stdlib</artifactId>
        </dependency>
        <dependency>
            <groupId>${GROUP_ID}</groupId>
            <artifactId>domain</artifactId>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-api</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-engine</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.jetbrains.kotlin</groupId>
            <artifactId>kotlin-test-junit5</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.jetbrains.kotlin</groupId>
                <artifactId>kotlin-maven-plugin</artifactId>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
EOF

  # ── api/pom.xml ──
  cat > "$TARGET_DIR/api/pom.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>${GROUP_ID}</groupId>
        <artifactId>${ARTIFACT_ID}</artifactId>
        <version>1.0-SNAPSHOT</version>
    </parent>

    <artifactId>api</artifactId>
    <description>Ponto de entrada — composição e wiring dos módulos</description>

    <dependencies>
        <dependency>
            <groupId>org.jetbrains.kotlin</groupId>
            <artifactId>kotlin-stdlib</artifactId>
        </dependency>
        <dependency>
            <groupId>${GROUP_ID}</groupId>
            <artifactId>application</artifactId>
        </dependency>
        <dependency>
            <groupId>${GROUP_ID}</groupId>
            <artifactId>infrastructure</artifactId>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.jetbrains.kotlin</groupId>
                <artifactId>kotlin-maven-plugin</artifactId>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-jar-plugin</artifactId>
                <version>3.3.0</version>
                <configuration>
                    <archive>
                        <manifest>
                            <mainClass>${API_PKG}.MainKt</mainClass>
                        </manifest>
                    </archive>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.codehaus.mojo</groupId>
                <artifactId>exec-maven-plugin</artifactId>
                <version>3.1.0</version>
                <configuration>
                    <mainClass>${API_PKG}.MainKt</mainClass>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
EOF
  print_ok "pom.xml de todos os módulos gerado"

  # ──────────────────────────────────────────
  #  domain — model + port
  # ──────────────────────────────────────────
  print_step "Criando classes: domain"

  cat > "$TARGET_DIR/domain/src/main/kotlin/$DOMAIN_PATH/model/User.kt" <<EOF
package ${DOMAIN_PKG}.model

data class User(
    val id: String,
    val name: String,
    val email: String
)
EOF

  cat > "$TARGET_DIR/domain/src/main/kotlin/$DOMAIN_PATH/port/UserRepository.kt" <<EOF
package ${DOMAIN_PKG}.port

import ${DOMAIN_PKG}.model.User

interface UserRepository {
    fun save(user: User): User
    fun findById(id: String): User?
    fun findAll(): List<User>
    fun deleteById(id: String): Boolean
}
EOF

  cat > "$TARGET_DIR/domain/src/test/kotlin/$DOMAIN_PATH/model/UserTest.kt" <<EOF
package ${DOMAIN_PKG}.model

import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class UserTest {

    @Test
    fun \`deve criar usuario com dados validos\`() {
        val user = User(id = "1", name = "Alice", email = "alice@example.com")

        assertNotNull(user)
        assertEquals("Alice", user.name)
        assertEquals("alice@example.com", user.email)
    }
}
EOF
  print_ok "domain: User, UserRepository, UserTest"

  # ──────────────────────────────────────────
  #  application — use cases
  # ──────────────────────────────────────────
  print_step "Criando classes: application"

  cat > "$TARGET_DIR/application/src/main/kotlin/$APP_PATH/usecase/CreateUserUseCase.kt" <<EOF
package ${APP_PKG}.usecase

import ${DOMAIN_PKG}.model.User
import ${DOMAIN_PKG}.port.UserRepository
import java.util.UUID

class CreateUserUseCase(private val userRepository: UserRepository) {

    data class Input(val name: String, val email: String)

    fun execute(input: Input): User {
        val user = User(
            id = UUID.randomUUID().toString(),
            name = input.name,
            email = input.email
        )
        return userRepository.save(user)
    }
}
EOF

  cat > "$TARGET_DIR/application/src/main/kotlin/$APP_PATH/usecase/FindUserUseCase.kt" <<EOF
package ${APP_PKG}.usecase

import ${DOMAIN_PKG}.model.User
import ${DOMAIN_PKG}.port.UserRepository

class FindUserUseCase(private val userRepository: UserRepository) {

    fun execute(id: String): User? = userRepository.findById(id)

    fun findAll(): List<User> = userRepository.findAll()
}
EOF

  cat > "$TARGET_DIR/application/src/test/kotlin/$APP_PATH/usecase/CreateUserUseCaseTest.kt" <<EOF
package ${APP_PKG}.usecase

import ${DOMAIN_PKG}.model.User
import ${DOMAIN_PKG}.port.UserRepository
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class CreateUserUseCaseTest {

    private val userRepository = object : UserRepository {
        private val store = mutableMapOf<String, User>()
        override fun save(user: User) = user.also { store[it.id] = it }
        override fun findById(id: String) = store[id]
        override fun findAll() = store.values.toList()
        override fun deleteById(id: String) = store.remove(id) != null
    }

    private val useCase = CreateUserUseCase(userRepository)

    @Test
    fun \`deve criar e persistir usuario\`() {
        val input = CreateUserUseCase.Input(name = "Alice", email = "alice@example.com")
        val user = useCase.execute(input)

        assertNotNull(user.id)
        assertEquals("Alice", user.name)
        assertEquals("alice@example.com", user.email)
    }
}
EOF
  print_ok "application: CreateUserUseCase, FindUserUseCase, CreateUserUseCaseTest"

  # ──────────────────────────────────────────
  #  infrastructure — repository impl
  # ──────────────────────────────────────────
  print_step "Criando classes: infrastructure"

  cat > "$TARGET_DIR/infrastructure/src/main/kotlin/$INFRA_PATH/repository/InMemoryUserRepository.kt" <<EOF
package ${INFRA_PKG}.repository

import ${DOMAIN_PKG}.model.User
import ${DOMAIN_PKG}.port.UserRepository

class InMemoryUserRepository : UserRepository {

    private val store = mutableMapOf<String, User>()

    override fun save(user: User): User {
        store[user.id] = user
        return user
    }

    override fun findById(id: String): User? = store[id]

    override fun findAll(): List<User> = store.values.toList()

    override fun deleteById(id: String): Boolean = store.remove(id) != null
}
EOF

  cat > "$TARGET_DIR/infrastructure/src/test/kotlin/$INFRA_PATH/repository/InMemoryUserRepositoryTest.kt" <<EOF
package ${INFRA_PKG}.repository

import ${DOMAIN_PKG}.model.User
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class InMemoryUserRepositoryTest {

    private lateinit var repository: InMemoryUserRepository

    @BeforeEach
    fun setUp() {
        repository = InMemoryUserRepository()
    }

    @Test
    fun \`deve salvar e recuperar usuario\`() {
        val user = User(id = "1", name = "Bob", email = "bob@example.com")
        repository.save(user)

        val found = repository.findById("1")
        assertNotNull(found)
        assertEquals("Bob", found.name)
    }

    @Test
    fun \`deve retornar null para id inexistente\`() {
        assertNull(repository.findById("nao-existe"))
    }

    @Test
    fun \`deve deletar usuario\`() {
        val user = User(id = "2", name = "Carol", email = "carol@example.com")
        repository.save(user)

        assertTrue(repository.deleteById("2"))
        assertNull(repository.findById("2"))
    }
}
EOF
  print_ok "infrastructure: InMemoryUserRepository, InMemoryUserRepositoryTest"

  # ──────────────────────────────────────────
  #  api — main entry point
  # ──────────────────────────────────────────
  print_step "Criando: api/Main.kt"

  cat > "$TARGET_DIR/api/src/main/kotlin/$API_PATH/Main.kt" <<EOF
package ${API_PKG}

import ${APP_PKG}.usecase.CreateUserUseCase
import ${APP_PKG}.usecase.FindUserUseCase
import ${INFRA_PKG}.repository.InMemoryUserRepository

fun main() {
    val userRepository = InMemoryUserRepository()
    val createUser    = CreateUserUseCase(userRepository)
    val findUser      = FindUserUseCase(userRepository)

    val user = createUser.execute(CreateUserUseCase.Input(
        name  = "Alice",
        email = "alice@example.com"
    ))
    println("Criado : \$user")

    val found = findUser.execute(user.id)
    println("Encontrado: \$found")
    println("Total: \${findUser.findAll().size} usuário(s)")
}
EOF
  print_ok "api: Main.kt"

  # ── README.md do projeto modular ──
  cat > "$TARGET_DIR/README.md" <<EOF
# ${PROJECT_NAME}

> **Tópico:** ${TOPIC}
> **Status:** ${STATUS}
> **Tipo:** Monolito Modular
> **Linguagem:** Kotlin + Maven

## Arquitetura

\`\`\`
domain          — entidades, value objects, interfaces (portas)
application     — casos de uso, orquestração de regras
infrastructure  — implementações de repos e adapters externos
api             — composição dos módulos, ponto de entrada
\`\`\`

Dependências entre módulos:

\`\`\`
api → application → domain
api → infrastructure → domain
\`\`\`

## Estrutura gerada

\`\`\`
${PROJECT_NAME}/
├── domain/src/main/kotlin/.../domain/
│   ├── model/User.kt
│   └── port/UserRepository.kt
├── application/src/main/kotlin/.../application/
│   └── usecase/
│       ├── CreateUserUseCase.kt
│       └── FindUserUseCase.kt
├── infrastructure/src/main/kotlin/.../infrastructure/
│   └── repository/InMemoryUserRepository.kt
└── api/src/main/kotlin/.../api/
    └── Main.kt
\`\`\`

## Como rodar

\`\`\`bash
# Compilar todos os módulos
mvn compile

# Rodar todos os testes
mvn test

# Executar (a partir da raiz)
mvn -pl api exec:java
\`\`\`

## Objetivo

Descreva aqui o que você está estudando e por quê.

## Conceitos abordados

- [ ] Separação de responsabilidades por módulo
- [ ] Inversão de dependência (domain não depende de infra)
- [ ] Use cases como orquestradores
- [ ] Ports & Adapters (Hexagonal)

## Referências

- [Kotlin Docs](https://kotlinlang.org/docs/home.html)
- [Modular Monolith](https://martinfowler.com/bliki/MonolithFirst.html)
EOF
}

# ─────────────────────────────────────────────
#  EXECUÇÃO PRINCIPAL
# ─────────────────────────────────────────────

echo ""
echo -e "${BOLD}${CYAN}════════════════════════════════════════${RESET}"
echo -e "${BOLD}  Kotlin Study — ${PROJECT_TYPE^} Project${RESET}"
echo -e "${BOLD}${CYAN}════════════════════════════════════════${RESET}"

if [[ "$PROJECT_TYPE" == "modular" ]]; then
  create_modular_project
else
  create_simple_project
fi

write_gitignore
write_docs

# ─── Git init + commit inicial ────────────────

print_step "Inicializando Git"

cd "$TARGET_DIR"
git init -q
git add .
git commit -q -m "chore: estrutura inicial — ${PROJECT_TYPE} — ${PROJECT_NAME}

- Tópico: ${TOPIC}
- Tipo: ${PROJECT_TYPE}
- Package: ${GROUP_ID}
- Kotlin 2.0.21 + Maven + JUnit 5"

print_ok "Commit inicial criado"

# ─── GitHub ───────────────────────────────────

if command -v gh &> /dev/null; then
  print_step "Criando repositório no GitHub"

  REPO_DESC="Estudo Kotlin [${PROJECT_TYPE}]: ${TOPIC} | ${PROJECT_NAME}"

  gh repo create "$PROJECT_NAME" \
    --description "$REPO_DESC" \
    $PRIVATE_FLAG \
    --source=. \
    --remote=origin \
    --push \
    2>/dev/null \
    && print_ok "Repositório criado: github.com/${GITHUB_USER}/${PROJECT_NAME}" \
    || print_warn "Não foi possível criar o repo. Rode: gh repo create"
else
  print_warn "GitHub CLI não encontrado. Instale com: sudo apt install gh"
fi

# ─── Abrir editor ─────────────────────────────

print_step "Abrindo editor"

case "$OPEN_EDITOR" in
  intellij)
    if command -v idea &> /dev/null; then
      idea "$TARGET_DIR" &
      print_ok "IntelliJ IDEA aberto"
    elif command -v idea.sh &> /dev/null; then
      idea.sh "$TARGET_DIR" &
      print_ok "IntelliJ IDEA aberto"
    else
      print_warn "IntelliJ não encontrado no PATH. Abra manualmente: $TARGET_DIR"
    fi
    ;;
  vscode)
    if command -v code &> /dev/null; then
      code "$TARGET_DIR"
      print_ok "VS Code aberto"
    else
      print_warn "VS Code não encontrado no PATH."
    fi
    ;;
  none) ;;
esac

# ─── Resumo final ─────────────────────────────

echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════════${RESET}"
echo -e "${BOLD}  Projeto pronto!${RESET}"
echo -e "${GREEN}════════════════════════════════════════${RESET}"
echo -e "  ${BOLD}Local:${RESET}   $TARGET_DIR"
echo -e "  ${BOLD}Package:${RESET} ${GROUP_ID}"
echo -e "  ${BOLD}Tipo:${RESET}    ${PROJECT_TYPE}"
echo -e "  ${BOLD}Tópico:${RESET}  ${TOPIC}"
echo -e "  ${BOLD}Status:${RESET}  ${STATUS}"

if [[ "$PROJECT_TYPE" == "modular" ]]; then
  echo ""
  echo -e "  ${CYAN}Módulos criados:${RESET} domain / application / infrastructure / api"
  echo -e "  ${CYAN}Para rodar:${RESET}      mvn -pl api exec:java"
else
  echo -e "  ${CYAN}Para rodar:${RESET}      mvn exec:java"
fi

echo -e "${GREEN}════════════════════════════════════════${RESET}"
echo ""
