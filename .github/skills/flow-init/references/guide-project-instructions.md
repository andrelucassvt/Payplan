# Guia: instruções compartilhadas de projeto

> Use este guia para gerar instruções concisas e acionáveis em `AGENTS.md` e disponibilizá-las ao Claude Code por meio de um `CLAUDE.md` com o import `@AGENTS.md`.

## Sumário

1. Princípios fundamentais
2. Estrutura canônica e ponte do Claude Code
3. Estrutura recomendada
4. Template enxuto
5. Hierarquia e disclosure progressivo
6. Anti-padrões
7. Checklist final

## 1. Princípios fundamentais

**Menos é mais.** Cada linha compete por atenção com a tarefa real. Prefira um arquivo raiz curto, normalmente entre 60 e 150 linhas e sempre abaixo de 200 quando possível.

**Teste de relevância.** Para cada linha, pergunte: “o agente erraria sem esta instrução?”. Remova orientações genéricas como “escreva código limpo”.

**Onboarding, não enciclopédia.** O arquivo deve responder:

- **O quê:** stack, estrutura e responsabilidades principais.
- **Por quê:** decisões e restrições que não são óbvias no código.
- **Como:** comandos reais para analisar, testar e gerar artefatos.

**Disclosure progressivo.** Mantenha no arquivo raiz somente regras universais. Regras específicas de módulos devem ficar próximas desses módulos ou em skills carregadas sob demanda.

## 2. Estrutura canônica e ponte do Claude Code

- Use `AGENTS.md` como arquivo canônico das instruções completas e compartilhadas do projeto.
- Crie `CLAUDE.md` com `@AGENTS.md` para que o Claude Code importe o arquivo canônico.
- O prefixo `@` é obrigatório: `AGENTS.md` sozinho é apenas texto, não um import.

Quando `CLAUDE.md` não existir, seu conteúdo deve ser exatamente:

```markdown
@AGENTS.md
```

- Se `CLAUDE.md` já começar com `@AGENTS.md`, preserve abaixo do import apenas instruções realmente exclusivas do Claude Code.
- Um symlink existente de `CLAUDE.md` para `AGENTS.md` também é válido e não precisa ser substituído.
- Se `CLAUDE.md` existir sem o import, não o sobrescreva silenciosamente. Migre regras compartilháveis para `AGENTS.md`, preserve regras exclusivas abaixo do import e peça confirmação antes da reescrita.

Leia os arquivos existentes antes de reescrevê-los. Migre instruções específicas e ainda válidas; descarte duplicações e regras desatualizadas. Como `AGENTS.md` será lido pelas duas plataformas, mantenha nele somente linguagem e convenções compatíveis com ambas.

## 3. Estrutura recomendada

Adapte esta estrutura ao que foi confirmado no repositório:

```markdown
# [Nome do Projeto]

[Uma frase descrevendo o projeto, stack principal e ambientes atendidos]

## Stack e arquitetura
## Estrutura do projeto
## Comandos essenciais
## Convenções
## Workflow e gotchas
## Não fazer
```

### 3.1 Cabeçalho

Comece com uma frase que dê contexto imediato:

```markdown
# CleanerForDevs

App macOS nativo em SwiftUI para limpeza de caches de desenvolvimento, distribuído pela Mac App Store.
```

### 3.2 Stack e arquitetura

Liste versões relevantes e decisões que não sejam inferíveis apenas pelos manifestos:

```markdown
## Stack

- Swift 5.9 / SwiftUI, mínimo macOS 13
- StoreKit 2 para compras

## Arquitetura

MVVM com lógica de limpeza isolada em `CleaningEngine`. A UI não acessa o filesystem diretamente.
```

### 3.3 Estrutura

Documente diretórios e seus propósitos, não um inventário de arquivos:

```markdown
## Estrutura

- `lib/features/` — features verticais
- `lib/core/` — DI, rede e persistência compartilhadas
- `test/` — espelha a estrutura de `lib/`
```

### 3.4 Comandos essenciais

Inclua apenas comandos encontrados no projeto ou confirmados pelo usuário:

```markdown
## Comandos

- `flutter test` — executa testes automatizados
- `flutter analyze` — executa análise estática
- `dart run build_runner build --delete-conflicting-outputs` — gera código
```

### 3.5 Convenções

Escreva regras específicas e verificáveis:

```markdown
## Convenções

- Estado: Riverpod 2.x; não introduza Provider legado
- Navegação: rotas tipadas em `lib/core/router/`
- Strings de UI: sempre via ARB
```

### 3.6 Workflow e gotchas

Registre decisões do time, armadilhas conhecidas e seus workarounds:

```markdown
## Gotchas

- O build de CI exige `pubspec.lock` versionado
- Código gerado deve ser atualizado antes da análise estática
```

### 3.7 Não fazer

Inclua proibições concretas que previnam erros recorrentes:

```markdown
## Não fazer

- Não rode upgrades de dependências sem solicitação explícita
- Não edite arquivos gerados manualmente
```

## 4. Template enxuto

```markdown
# [Projeto]

[Uma linha: finalidade, stack principal e ambientes atendidos]

## Stack

- [Linguagem/framework + versão relevante]
- [Bibliotecas ou serviços críticos]

## Estrutura

- `path/` — propósito

## Comandos

- `comando` — descrição curta

## Convenções

- [Regra específica e acionável]

## Gotchas

- [Armadilha conhecida + workaround]

## Não fazer

- [Comportamento concreto a evitar]
```

Comece pelo template e adicione somente seções sustentadas por evidência no projeto.

### 4.1 Blocos finais obrigatórios

Anexe ao final do `AGENTS.md` gerado, exatamente como abaixo. São as duas convenções que o Brain Flows depende e que o agente não infere do código:

```markdown
## 📖 Documentação de Flows

`./docs/flow/` documenta como cada feature funciona de ponta a ponta — arquivos, ordem de chamada e regras de negócio. `project-structure.md` é a visão geral do projeto.

- **Antes de implementar ou debugar:** leia a linha `**Resumo:**` de cada `.md` em `./docs/flow/` e abra por inteiro os relevantes para a tarefa.
- **Depois de alterar uma feature documentada:** atualize o flow dela no mesmo trabalho — arquivos, passo a passo, regras e frontmatter (`verified_at`, `source_commit`, `source_state`). Mudança de stack, estrutura ou comandos atualiza `project-structure.md`.
- **Feature nova ou sem flow:** invoque a skill `flow` para documentá-la.

## 🧪 Teste funcional

Após implementar, não execute o projeto para validar o resultado (rodar o app, emulador/simulador, dispositivo físico, servidor local, screenshots ou interação simulada). Teste funcional/visual é responsabilidade do usuário.

- Limite a verificação a análise estática, build/compile e testes automatizados
- Ao concluir, liste objetivamente o que o usuário deve testar manualmente
- Não pergunte se deve executar o projeto — só faça isso se o usuário pedir explicitamente
```

Estes blocos são a definição canônica no projeto de destino: com eles no `AGENTS.md`, o agente consulta e mantém os flows em toda tarefa sem depender de skill, e a regra de teste funcional não é repetida a cada invocação.

## 5. Hierarquia e disclosure progressivo

O arquivo na raiz contém stack, comandos, convenções universais e riscos críticos. Instruções específicas de um módulo podem ficar em arquivos equivalentes dentro do subdiretório quando a plataforma oferecer herança de contexto.

Skills guardam workflows especializados ativados apenas quando relevantes. Não duplique o corpo de uma skill no arquivo raiz; indique quando invocá-la.

A sintaxe de invocação varia entre plataformas. Como `AGENTS.md` também é importado pelo Claude Code, use nele uma formulação neutra como “invoque a skill `flow`”. Se uma instrução exclusiva do Claude Code for indispensável, coloque-a em `CLAUDE.md` abaixo de `@AGENTS.md`.

## 6. Anti-padrões

**Genérico demais.** Troque “escreva código testável” por comandos e padrões reais do projeto.

**Tudo no arquivo raiz.** Mova regras restritas a um módulo para contexto local ou skills.

**Documentar o óbvio.** Não copie integralmente dependências ou estrutura que o agente obtém dos manifestos.

**Instruções contraditórias.** Audite arquivos raiz, subdiretórios e skills para não impor padrões incompatíveis.

**Misturar plataformas.** Não coloque comandos `/plugin` do Claude nem sintaxes `$skill` do Codex no `AGENTS.md` compartilhado. Prefira linguagem neutra; mantenha instruções exclusivas do Claude Code abaixo do import em `CLAUDE.md`.

**Duplicar instruções na ponte.** Não copie para `CLAUDE.md` o conteúdo já mantido em `AGENTS.md`; o import resolve o compartilhamento.

**Esquecer de versionar.** O arquivo de instruções faz parte do projeto e deve ser revisável como o código.

## 7. Checklist final

- `AGENTS.md` é o arquivo canônico das instruções compartilhadas?
- `CLAUDE.md` começa com `@AGENTS.md` ou é um symlink válido para `AGENTS.md`?
- O arquivo tem menos de 200 linhas?
- O cabeçalho descreve o projeto em uma frase?
- Todos os caminhos e comandos foram encontrados no repositório?
- As convenções são específicas e acionáveis?
- Instruções existentes válidas foram preservadas?
- O conteúdo compartilhado evita sintaxes exclusivas de plataforma?
- Instruções exclusivas do Claude Code, se existirem, estão abaixo do import e sem duplicação?
- Não há contradições com arquivos em subdiretórios ou skills?
- A seção de flows manda consultar os flows antes da tarefa, atualizá-los depois e invocar a skill `flow` para features sem flow, sem assumir sintaxe de plataforma?
