---
agent: agent
description: Analisa este projeto Flutter e gera CLAUDE.md, AGENTS.md e copilot-instructions.md personalizados com base na arquitetura real do projeto.
---

Você é um agente especialista em Flutter/Dart. Sua tarefa é **analisar este projeto** e gerar arquivos de contexto de IA personalizados para ele.

## Passo 1 — Explorar o projeto

Leia os seguintes arquivos/pastas para coletar dados reais:

- `pubspec.yaml` → nome do projeto, versão Flutter/Dart, dependências
- `ios/Podfile` ou `ios/Runner.xcodeproj/project.pbxproj` → iOS deployment target
- `android/app/build.gradle` → Android minSdkVersion
- Pastas `android/`, `ios/`, `web/`, `macos/`, `linux/`, `windows/` → plataformas suportadas
- `lib/main*.dart` (ex: `main_development.dart`) → flavors configurados
- `lib/` → estrutura real de pastas e arquitetura usada
- `Makefile` ou `scripts/` → comandos disponíveis

## Passo 2 — Inventariar as Skills

Leia cada arquivo `SKILL.md` encontrado em `.claude/skills/`, `.agents/skills/` **e** `.github/skills/`:

Para cada skill, extraia:
- **nome** (campo `name` do frontmatter)
- **quando usar** (campo `description` do frontmatter — primeira frase)
- **caminho** do arquivo lido

Monte uma tabela com essas três colunas. Esse inventário será usado nos arquivos gerados.

## Passo 3 — Gerar os arquivos

Com base na análise, escreva os três arquivos abaixo com informações **reais e específicas** deste projeto. Não copie conteúdo genérico de template.

---

### Arquivo 1: `CLAUDE.md` (raiz do projeto)

```
# [Nome do Projeto] — Claude Code Instructions

## Sobre Este Projeto
[Descrição curta. Flutter X.X / Dart X.X. Plataformas: iOS (target X), Android (minSdk X), ...]
[Flavors encontrados, se houver]

## Regra Obrigatória de Leitura

**Antes de gerar ou modificar qualquer código**, leia SEMPRE o arquivo
`.claude/rules/architecture.instructions.md` — ele contém as regras gerais de
arquitetura que se aplicam a todo o projeto.

Depois, conforme o contexto da tarefa, leia a skill correspondente (tabela abaixo).

## 📂 Arquivos de Instrução

| Arquivo | Quando ler |
|---|---|
| `.claude/rules/architecture.instructions.md` | **Sempre** — regras gerais de arquitetura |

## 🛠️ Skills Especializadas

[Tabela gerada a partir do inventário do Passo 2:]
| Skill | Arquivo | Quando usar |
|---|---|---|
| `<nome>` | `.claude/skills/<nome>/SKILL.md` | <quando usar extraído do description> |
...

## 📝 Prompts Disponíveis

[Liste os arquivos encontrados em `.github/prompts/` com uma linha de descrição cada]

## ⚡ Regras Globais

[Copie as regras da seção "Regras-Chave para IA" de `.claude/rules/architecture.instructions.md`]

## Estrutura do Projeto

[Árvore de lib/ com uma linha de descrição por pasta — baseada na estrutura real]

## Comandos Úteis

[Apenas comandos que existirem no projeto: build, test, lint, run por flavor]

## Dependências Externas

[Pacotes reais do pubspec.yaml, agrupados por categoria: State Management, DI, Network, etc.]
```

---

### Arquivo 2: `AGENTS.md` (raiz do projeto)

```
# [Nome do Projeto] — Agent Instructions

## Sobre Este Projeto
[Mesma descrição do CLAUDE.md]

## Regra Obrigatória de Leitura

**Antes de gerar ou modificar qualquer código**, leia SEMPRE o arquivo
`.agents/rules/architecture.instructions.md`.

Depois, conforme o contexto, leia a skill correspondente (tabela abaixo).

## 📂 Arquivos de Instrução

| Arquivo | Quando ler |
|---|---|
| `.agents/rules/architecture.instructions.md` | **Sempre** — regras gerais de arquitetura |

## 🛠️ Skills

[Mesma tabela do CLAUDE.md, mas apontando para `.agents/skills/<nome>/SKILL.md`]

## ⚡ Regras Globais

[Mesmas regras copiadas de `.claude/rules/architecture.instructions.md`]

## Estrutura do Projeto

[Mesma árvore do CLAUDE.md]
```

---

### Arquivo 3: `.github/copilot-instructions.md`

```
# Copilot Instructions — [Nome do Projeto]

## Contexto
[Nome, Flutter/Dart version, plataformas, iOS target, Android minSdk]

## Arquitetura: [padrão detectado] — Flutter

### Regras Obrigatórias
[Regras reais de `.claude/rules/architecture.instructions.md` — adaptadas para Copilot]

### Compatibilidade de Plataformas
[Tabela: Plataforma | Status | Observações — baseada nas plataformas detectadas]

### Convenções de Nomenclatura
[Específicas do projeto — extraídas do código existente]

### Estrutura de Pastas
[Árvore real de lib/]

## Skills Disponíveis
[Lista: nome da skill — quando usar (uma linha cada)]
```

---

## Passo 4 — Corrigir referências de path

Antes de escrever, verifique se o `CLAUDE.md` gerado contém alguma ocorrência de
`.github/instructions/architecture.instructions.md`. Se encontrar, substitua por
`.claude/rules/architecture.instructions.md`.

Faça a mesma verificação no `AGENTS.md` (substitua por `.agents/rules/architecture.instructions.md`)
e no `copilot-instructions.md` (substitua por `.github/instructions/architecture.instructions.md`).

## Passo 5 — Escrever os arquivos

Escreva os três arquivos:
- `CLAUDE.md`
- `AGENTS.md`
- `.github/copilot-instructions.md`

Ao final, confirme quais arquivos foram escritos e faça um resumo de 2-3 linhas sobre o projeto e as skills encontradas.
