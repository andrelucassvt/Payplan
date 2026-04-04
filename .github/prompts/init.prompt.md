---
agent: agent
---

## Tarefa

Analisar o projeto atual e criar o arquivo `.github/instructions/current_project.instructions.md`, `.claude/rules/current_project.rules.md` e com um resumo estruturado do projeto.

---

## Passo a Passo

1. **Explorar a estrutura do projeto**
   - Liste os arquivos e pastas raiz
   - Leia `pubspec.yaml` (Flutter), `package.json` (Node/JS), `pyproject.toml` / `requirements.txt` (Python), `Cargo.toml` (Rust), `go.mod` (Go), `build.gradle` (Android) ou equivalente para identificar linguagem, framework e dependências
   - Leia `README.md` se existir

2. **Identificar os comandos principais**
   - Verifique `Makefile`, `package.json` (scripts), `pubspec.yaml`, `justfile` ou documentação inline para extrair os comandos de instalação, dev, build, teste e lint

3. **Mapear a arquitetura**
   - Liste as pastas principais e infira a responsabilidade de cada uma
   - Identifique padrões arquiteturais (Clean Architecture, MVC, feature-based, monorepo, etc.)
   - Verifique arquivos de configuração de DI, rotas e estado se existirem

4. **Levantar convenções**
   - Analise nomes de arquivos, classes e funções existentes para inferir padrão de nomenclatura
   - Verifique `.commitlintrc`, `CONTRIBUTING.md` ou histórico de commits para padrão de commits
   - Note onde ficam os diferentes tipos de arquivo (telas, modelos, testes, etc.)

5. **Identificar avisos e pontos de atenção**
   - Dependências críticas ou com comportamento não óbvio
   - Integrações externas (APIs, SDKs, serviços de terceiros)
   - Arquivos ou pastas que nunca devem ser modificados diretamente

6. **Gerar os arquivos** `.github/instructions/current_project.instructions.md` e `.claude/rules/current_project.rules.md` com o conteúdo abaixo preenchido.

---

## Formato do Arquivo Gerado

```markdown
---
applyTo: '**'
---

# [Nome do Projeto]

## Visão Geral
<!-- Uma linha: o que é e qual problema resolve -->

## Stack
<!-- Linguagens, frameworks, ferramentas principais com versões -->

## Comandos
\```bash
# Instalar


# Dev


# Build


# Testes


# Lint
\```

## Arquitetura
<!-- Pastas principais e o que cada uma faz -->
<!-- Padrões arquiteturais usados -->

## Convenções
<!-- Nomenclatura de arquivos, funções, variáveis -->
<!-- Padrão de commits -->
<!-- Onde criar novos arquivos de cada tipo -->

## Avisos
<!-- O que nunca fazer neste projeto -->
<!-- Dependências com comportamento não óbvio -->
<!-- Integrações externas que precisam de atenção -->
```

---

## Regras

- Preencha apenas o que foi **confirmado** pela análise — não invente informações
- Se um campo não puder ser determinado com certeza, deixe um comentário explicando o que falta
- O arquivo gerado deve usar o frontmatter `applyTo: '**'` para ser carregado em todos os contextos
- Não crie nenhum outro arquivo além de `.github/instructions/current_project.instructions.md` e `.claude/rules/current_project.rules.md`
