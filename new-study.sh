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
  local build_tool="${1:-maven}"

  if [[ "$build_tool" == "gradle" ]]; then
    cat > "$TARGET_DIR/.gitignore" <<EOF
# Gradle
.gradle/
build/
!gradle/wrapper/gradle-wrapper.jar

# IntelliJ IDEA
.idea/
*.iml
out/

# VS Code
.vscode/

# OS
.DS_Store
Thumbs.db

# Logs
*.log
EOF
  else
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
  fi
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
#  PROJETO MODULAR (Spring Boot + Spring Modulith)
#
#  Padrao auditoria-corridas:
#   {pkg}/                     @SpringBootApplication
#   {pkg}/{topic}/             modulo principal (model/repo/service/controller)
#   {pkg}/shared/exception/    handler global
# ─────────────────────────────────────────────

create_modular_project() {
  local SPRING_PKG="${PROJECT_NAME//-/_}"
  local SPRING_PKG_PATH="${PROJECT_NAME//-/_}"
  local APP_CLASS
  APP_CLASS=$(echo "$PROJECT_NAME" | sed -E 's/(^|-)([a-zA-Z])/\U\2/g')
  local MODULE_CLASS
  MODULE_CLASS=$(echo "$TOPIC" | sed -E 's/(^|-)([a-zA-Z])/\U\2/g')
  local MODULE_PKG="${TOPIC//-/_}"

  print_step "Criando Spring Boot + Spring Modulith em $TARGET_DIR"

  # Diretorios
  mkdir -p "$TARGET_DIR/src/main/kotlin/$SPRING_PKG_PATH/$MODULE_PKG/model"
  mkdir -p "$TARGET_DIR/src/main/kotlin/$SPRING_PKG_PATH/$MODULE_PKG/repository"
  mkdir -p "$TARGET_DIR/src/main/kotlin/$SPRING_PKG_PATH/$MODULE_PKG/service"
  mkdir -p "$TARGET_DIR/src/main/kotlin/$SPRING_PKG_PATH/$MODULE_PKG/controller"
  mkdir -p "$TARGET_DIR/src/main/kotlin/$SPRING_PKG_PATH/shared/exception"
  mkdir -p "$TARGET_DIR/src/main/resources"
  mkdir -p "$TARGET_DIR/src/test/kotlin/$SPRING_PKG_PATH"
  mkdir -p "$TARGET_DIR/src/test/kotlin/$SPRING_PKG_PATH/$MODULE_PKG/service"
  mkdir -p "$TARGET_DIR/docs"
  print_ok "Estrutura de diretorios criada"

  # settings.gradle.kts
  print_step "Gerando Gradle build files"
  cat > "$TARGET_DIR/settings.gradle.kts" <<SETTINGSEOF
rootProject.name = "${PROJECT_NAME}"
SETTINGSEOF

  # build.gradle.kts
  cat > "$TARGET_DIR/build.gradle.kts" <<BUILDEOF
plugins {
    kotlin("jvm") version "2.2.21"
    kotlin("plugin.spring") version "2.2.21"
    id("org.springframework.boot") version "4.0.5"
    id("io.spring.dependency-management") version "1.1.7"
    kotlin("plugin.jpa") version "2.2.21"
}

group = "${GROUP_ID}"
version = "0.0.1-SNAPSHOT"

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.jetbrains.kotlin:kotlin-reflect")
    implementation("tools.jackson.module:jackson-module-kotlin")
    implementation("org.springframework.modulith:spring-modulith-starter-core")

    // H2 para estudo — troque por postgresql para producao
    runtimeOnly("com.h2database:h2")
    // runtimeOnly("org.postgresql:postgresql")

    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.jetbrains.kotlin:kotlin-test-junit5")
    testImplementation("org.springframework.modulith:spring-modulith-starter-test")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

dependencyManagement {
    imports {
        mavenBom("org.springframework.modulith:spring-modulith-bom:2.0.0")
    }
}

kotlin {
    compilerOptions {
        freeCompilerArgs.addAll("-Xjsr305=strict")
    }
}

allOpen {
    annotation("jakarta.persistence.Entity")
    annotation("jakarta.persistence.MappedSuperclass")
    annotation("jakarta.persistence.Embeddable")
}

tasks.withType<Test> {
    useJUnitPlatform()
}
BUILDEOF
  print_ok "build.gradle.kts + settings.gradle.kts gerados"

  # Gradle wrapper properties
  print_step "Configurando Gradle wrapper"
  mkdir -p "$TARGET_DIR/gradle/wrapper"
  cat > "$TARGET_DIR/gradle/wrapper/gradle-wrapper.properties" <<WRAPEOF
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-9.4.1-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
WRAPEOF

  if command -v gradle &> /dev/null; then
    (cd "$TARGET_DIR" && gradle wrapper --gradle-version 9.4.1 -q 2>/dev/null) \
      && print_ok "Gradle wrapper gerado (binarios incluidos)" \
      || print_warn "Falha ao gerar binarios — apenas .properties criado"
  else
    print_warn "Gradle nao encontrado — execute 'gradle wrapper --gradle-version 9.4.1' manualmente"
  fi

  # application.properties
  cat > "$TARGET_DIR/src/main/resources/application.properties" <<APPEOF
spring.application.name=${PROJECT_NAME}

spring.datasource.url=jdbc:h2:mem:${MODULE_PKG}db
spring.datasource.driver-class-name=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=create-drop
spring.h2.console.enabled=true
spring.h2.console.path=/h2-console
APPEOF

  # Application.kt
  print_step "Criando classes Kotlin"
  cat > "$TARGET_DIR/src/main/kotlin/$SPRING_PKG_PATH/${APP_CLASS}Application.kt" <<APPKTEOF
package ${SPRING_PKG}

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class ${APP_CLASS}Application

fun main(args: Array<String>) {
    runApplication<${APP_CLASS}Application>(*args)
}
APPKTEOF

  # Model
  cat > "$TARGET_DIR/src/main/kotlin/$SPRING_PKG_PATH/$MODULE_PKG/model/${MODULE_CLASS}.kt" <<MODELEOF
package ${SPRING_PKG}.${MODULE_PKG}.model

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Table

@Entity
@Table(name = "${MODULE_PKG}s")
data class ${MODULE_CLASS}(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @Column(nullable = false)
    val nome: String,

    @Column
    val descricao: String = ""
) {
    constructor() : this(id = null, nome = "", descricao = "")
}
MODELEOF

  # Repository
  cat > "$TARGET_DIR/src/main/kotlin/$SPRING_PKG_PATH/$MODULE_PKG/repository/${MODULE_CLASS}Repository.kt" <<REPOEOF
package ${SPRING_PKG}.${MODULE_PKG}.repository

import ${SPRING_PKG}.${MODULE_PKG}.model.${MODULE_CLASS}
import org.springframework.data.jpa.repository.JpaRepository

interface ${MODULE_CLASS}Repository : JpaRepository<${MODULE_CLASS}, Long> {
    fun findByNome(nome: String): List<${MODULE_CLASS}>
}
REPOEOF

  # Service
  cat > "$TARGET_DIR/src/main/kotlin/$SPRING_PKG_PATH/$MODULE_PKG/service/${MODULE_CLASS}Service.kt" <<SVCEOF
package ${SPRING_PKG}.${MODULE_PKG}.service

import ${SPRING_PKG}.${MODULE_PKG}.model.${MODULE_CLASS}
import ${SPRING_PKG}.${MODULE_PKG}.repository.${MODULE_CLASS}Repository
import org.springframework.stereotype.Service

@Service
class ${MODULE_CLASS}Service(
    private val repository: ${MODULE_CLASS}Repository
) {
    fun listarTodos(): List<${MODULE_CLASS}> = repository.findAll()

    fun buscarPorId(id: Long): ${MODULE_CLASS} =
        repository.findById(id).orElseThrow { NoSuchElementException("\${MODULE_CLASS} \${id} nao encontrado") }

    fun criar(entidade: ${MODULE_CLASS}): ${MODULE_CLASS} = repository.save(entidade)

    fun deletar(id: Long) = repository.deleteById(id)
}
SVCEOF

  # Controller
  cat > "$TARGET_DIR/src/main/kotlin/$SPRING_PKG_PATH/$MODULE_PKG/controller/${MODULE_CLASS}Controller.kt" <<CTRLEOF
package ${SPRING_PKG}.${MODULE_PKG}.controller

import ${SPRING_PKG}.${MODULE_PKG}.model.${MODULE_CLASS}
import ${SPRING_PKG}.${MODULE_PKG}.service.${MODULE_CLASS}Service
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/${MODULE_PKG}s")
class ${MODULE_CLASS}Controller(
    private val service: ${MODULE_CLASS}Service
) {
    @GetMapping
    fun listar(): List<${MODULE_CLASS}> = service.listarTodos()

    @GetMapping("/{id}")
    fun buscar(@PathVariable id: Long): ${MODULE_CLASS} = service.buscarPorId(id)

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun criar(@RequestBody entidade: ${MODULE_CLASS}): ${MODULE_CLASS} = service.criar(entidade)

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deletar(@PathVariable id: Long) = service.deletar(id)
}
CTRLEOF

  # GlobalExceptionHandler
  cat > "$TARGET_DIR/src/main/kotlin/$SPRING_PKG_PATH/shared/exception/GlobalExceptionHandler.kt" <<EXEOF
package ${SPRING_PKG}.shared.exception

import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestControllerAdvice

@RestControllerAdvice
class GlobalExceptionHandler {

    @ExceptionHandler(NoSuchElementException::class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    fun handleNotFound(ex: NoSuchElementException): Map<String, String> =
        mapOf("erro" to (ex.message ?: "Recurso nao encontrado"))
}
EXEOF
  print_ok "Application, ${MODULE_CLASS} (model/repo/service/ctrl), GlobalExceptionHandler"

  # Testes
  print_step "Criando testes"
  cat > "$TARGET_DIR/src/test/kotlin/$SPRING_PKG_PATH/${APP_CLASS}ApplicationTests.kt" <<ATEOF
package ${SPRING_PKG}

import org.junit.jupiter.api.Test
import org.springframework.boot.test.context.SpringBootTest

@SpringBootTest
class ${APP_CLASS}ApplicationTests {

    @Test
    fun contextLoads() {
    }
}
ATEOF

  cat > "$TARGET_DIR/src/test/kotlin/$SPRING_PKG_PATH/$MODULE_PKG/service/${MODULE_CLASS}ServiceTest.kt" <<STEOF
package ${SPRING_PKG}.${MODULE_PKG}.service

import ${SPRING_PKG}.${MODULE_PKG}.model.${MODULE_CLASS}
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.transaction.annotation.Transactional
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotNull

@SpringBootTest
@Transactional
class ${MODULE_CLASS}ServiceTest {

    @Autowired
    private lateinit var service: ${MODULE_CLASS}Service

    @Test
    fun \`deve criar e buscar entidade\`() {
        val nova = service.criar(${MODULE_CLASS}(nome = "Teste", descricao = "Descricao"))
        assertNotNull(nova.id)
        val encontrada = service.buscarPorId(nova.id!!)
        assertEquals("Teste", encontrada.nome)
    }

    @Test
    fun \`deve lancar excecao para id inexistente\`() {
        assertFailsWith<NoSuchElementException> {
            service.buscarPorId(-1L)
        }
    }
}
STEOF
  print_ok "${APP_CLASS}ApplicationTests, ${MODULE_CLASS}ServiceTest"

  # README
  cat > "$TARGET_DIR/README.md" <<READEOF
# ${PROJECT_NAME}

> **Topico:** ${TOPIC}
> **Status:** ${STATUS}
> **Tipo:** Monolito Modular — Spring Boot + Spring Modulith

## Estrutura

\`\`\`
${SPRING_PKG}/
+-- ${MODULE_PKG}/
|   +-- model/        entidades JPA
|   +-- repository/   Spring Data
|   +-- service/      regras de negocio
|   +-- controller/   endpoints REST
+-- shared/exception/ handler global
\`\`\`

## Como rodar

\`\`\`bash
./gradlew bootRun
\`\`\`

- App: http://localhost:8080
- H2 Console: http://localhost:8080/h2-console

## Endpoints

| Metodo | URL | Descricao |
|--------|-----|-----------|
| GET    | /${MODULE_PKG}s      | Lista todos  |
| GET    | /${MODULE_PKG}s/{id} | Busca por ID |
| POST   | /${MODULE_PKG}s      | Cria novo    |
| DELETE | /${MODULE_PKG}s/{id} | Remove       |

## Testes

\`\`\`bash
./gradlew test
\`\`\`

## Trocar para PostgreSQL

Em \`build.gradle.kts\`: descomente \`runtimeOnly("org.postgresql:postgresql")\`

Em \`application.properties\`:
\`\`\`properties
spring.datasource.url=jdbc:postgresql://localhost:5432/seu_banco
spring.datasource.username=usuario
spring.datasource.password=senha
spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect
spring.jpa.hibernate.ddl-auto=validate
\`\`\`

## Objetivo

Descreva aqui o que voce esta estudando e por que.

## Referencias

- [Spring Modulith](https://docs.spring.io/spring-modulith/docs/current/reference/html/)
- [Spring Boot](https://docs.spring.io/spring-boot/docs/current/reference/html/)
READEOF
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

if [[ "$PROJECT_TYPE" == "modular" ]]; then
  write_gitignore "gradle"
else
  write_gitignore "maven"
fi
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
- Build: Gradle+SpringBoot (modular) | Maven+JUnit5 (simples)"

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
  echo -e "  ${CYAN}Framework:${RESET}  Spring Boot + Spring Modulith"
  echo -e "  ${CYAN}Para rodar:${RESET} ./gradlew bootRun"
  echo -e "  ${CYAN}Testes:${RESET}     ./gradlew test"
else
  echo -e "  ${CYAN}Para rodar:${RESET} mvn exec:java"
fi

echo -e "${GREEN}════════════════════════════════════════${RESET}"
echo ""
