# Guia: Como estruturar um `CLAUDE.md` eficaz

> Um `CLAUDE.md` bem feito é a diferença entre o Claude Code "chutando" decisões a cada sessão e ele entrar no projeto já sabendo onde pisa. Este guia consolida as melhores práticas atuais (Anthropic + comunidade) com foco em projetos reais — Flutter, Spring Boot, Swift, Electron, etc.

---

## 1. Princípios fundamentais

Antes de qualquer estrutura, internalize estes 4 princípios. Eles são mais importantes que qualquer template.

**Menos é mais.** Pesquisa atual indica que LLMs frontier conseguem seguir consistentemente cerca de 150–200 instruções. Cada linha do seu `CLAUDE.md` compete por atenção com o trabalho real. O consenso da comunidade aponta para **menos de 200–300 linhas**, e times maduros (HumanLayer, Builder.io) operam com arquivos de 60–150 linhas.

**Teste de relevância.** Para cada linha, pergunte: *"O Claude erraria sem essa instrução?"* Se a resposta é "não" ou "talvez", remova. Instruções genéricas tipo "escreva código limpo" são ruído puro.

**Onboarding, não enciclopédia.** O `CLAUDE.md` responde três perguntas:
- **WHAT** — qual é o stack, a estrutura, o que cada parte faz
- **WHY** — qual o propósito do projeto e dos módulos
- **HOW** — como rodar, testar, validar mudanças

**Disclosure progressivo.** Não jogue tudo no arquivo raiz. Use `CLAUDE.md` em subdiretórios (carregados sob demanda) e skills (carregadas quando relevantes) para contexto específico de tarefa.

---

## 2. Estrutura recomendada

Esta é uma estrutura modular que funciona bem para projetos solo e em time. Adapte — não é dogma.

```markdown
# [Nome do Projeto]

[Uma frase descrevendo o que é o projeto e seu stack principal]

## Stack & arquitetura
## Estrutura do projeto
## Comandos essenciais
## Convenções de código
## Workflow & gotchas
## O que NÃO fazer
```

### 2.1. Cabeçalho de orientação (1 linha)

Comece com **uma frase** que orienta o Claude imediatamente. Não é "sobre o projeto" — é a TL;DR.

```markdown
# CleanerForDevs

App macOS nativo (Swift/SwiftUI) para limpeza de cache de desenvolvimento, distribuído via Mac App Store, com integração opcional com Ollama para sugestões locais.
```

Em uma frase o Claude já sabe: plataforma, linguagem, canal de distribuição, dependências externas relevantes.

### 2.2. Stack & arquitetura

Liste as tecnologias com **versões importantes** e decisões arquiteturais que o Claude não consegue inferir do código.

```markdown
## Stack

- Swift 5.9 / SwiftUI (mínimo macOS 13)
- App sandbox habilitado (entitlements em `Resources/Entitlements/`)
- StoreKit 2 para IAP
- Ollama via HTTP local (porta 11434, opcional)

## Arquitetura

MVVM com Coordinators. Lógica de limpeza isolada em `CleaningEngine`
(testável sem UI). UI nunca acessa filesystem diretamente — sempre via engine.
```

### 2.3. Estrutura do projeto

Mapa do código. **Crítico em monorepos**, útil em qualquer projeto.

```markdown
## Estrutura

- `lib/features/` — features verticais (auth, library, player)
- `lib/core/` — base compartilhada (di, networking, storage)
- `lib/shared/widgets/` — widgets reutilizáveis
- `test/` — espelha estrutura de `lib/`
- `tools/` — scripts internos (Jarvis bot, build automation)
```

Não documente arquivos individualmente. Documente **diretórios e seu propósito**.

### 2.4. Comandos essenciais

Comandos que o Claude vai usar com frequência. Inclua tudo que você digitaria repetidamente.

```markdown
## Comandos

- `flutter run -d macos` — roda no macOS
- `flutter test` — roda testes unitários
- `dart run build_runner build --delete-conflicting-outputs` — gera código
- `./tools/jarvis build android release` — build Android via bot interno
- `./tools/jarvis ship ios` — sobe TestFlight
```

### 2.5. Convenções de código

Específicas, não genéricas. **Bom:** "use `Riverpod` providers, nunca `Provider` legado". **Ruim:** "escreva código limpo".

```markdown
## Convenções

- State management: Riverpod 2.x (nunca Provider legado)
- Navegação: go_router com rotas tipadas em `lib/core/router/`
- Erros: Result<T, Failure> custom (ver `lib/core/result.dart`), nunca exceptions cruas em camada de feature
- Testes: prefira fakes a mocks; mocks só com mocktail
- Strings: sempre via ARB (l10n), nunca hardcoded em widgets
```

### 2.6. Workflow & gotchas

Aqui mora o ouro. Decisões arquiteturais, armadilhas conhecidas, regras do time.

```markdown
## Workflow

- Branch: `feat/`, `fix/`, `chore/` (nunca `feature/`)
- Commits: um arquivo por commit em mudanças de docs/skills
- PRs precisam de `flutter analyze` limpo + testes passando

## Gotchas

- StoreKit em sandbox às vezes retorna receipts vazios na 1ª tentativa —
  retry com 500ms resolve (ver `IAPService.purchase`)
- Build no CI quebra se `pubspec.lock` não estiver commitado — sempre commitar
- Hot reload não atualiza providers de `Riverpod` com `keepAlive: false` —
  use hot restart
```

### 2.7. O que NÃO fazer

Negativas explícitas economizam idas e voltas. Liste comportamentos do Claude que você já corrigiu mais de uma vez.

```markdown
## Não fazer

- Não rode `flutter pub upgrade` sem perguntar — versões são pinadas por motivo
- Não adicione comentários redundantes em código gerado
- Não crie novos pacotes em `lib/core/` sem discutir arquitetura
- Não use `print()` — sempre `logger.d/i/w/e`
```

---

## 3. Hierarquia: raiz, subdiretórios, skills

O Claude Code tem **três camadas** de contexto persistente. Use cada uma para o que ela faz melhor.

**`CLAUDE.md` na raiz** — carregado em toda sessão. Aqui vai só o essencial: stack, comandos, convenções universais, gotchas críticos.

**`CLAUDE.md` em subdiretórios** — carregado **sob demanda** quando o Claude trabalha naquela área. Ideal para regras específicas de um módulo.

```
projeto/
├── CLAUDE.md                    ← regras gerais (curto)
├── lib/
│   ├── features/
│   │   └── payments/
│   │       └── CLAUDE.md        ← regras de pagamento (PIX, Stripe Connect)
│   └── core/
│       └── networking/
│           └── CLAUDE.md        ← convenções de API
└── ios/
    └── CLAUDE.md                ← especificidades de iOS/Swift
```

**`.claude/skills/*/SKILL.md`** — carregadas quando o Claude detecta relevância pelo `description`. Use para conhecimento especializado que aparece *às vezes* (deploy, geração de release notes, formato de proposta comercial, etc.). Você já usa isso bem com `proposta-tech` e `html-to-pdf`.

A regra prática: **se uma instrução só importa em 20% das tarefas, ela não pertence ao `CLAUDE.md` raiz**. Mova para subdiretório ou skill.

---

## 4. Template enxuto (use como ponto de partida)

```markdown
# [Projeto]

[1 linha: o que é, stack principal, plataforma alvo]

## Stack

- [Linguagem/framework + versão]
- [Bibliotecas críticas]
- [Serviços externos]

## Estrutura

- `path/` — propósito
- `path/` — propósito

## Comandos

- `cmd` — descrição curta
- `cmd` — descrição curta

## Convenções

- [Regra específica e acionável]
- [Regra específica e acionável]

## Gotchas

- [Armadilha conhecida + workaround]

## Não fazer

- [Comportamento a evitar]
```

Comece com isto. **Adicione linhas só quando o Claude errar** e a correção couber numa instrução clara. Não tente prever todos os erros possíveis.

---

## 5. Como evoluir o arquivo

`CLAUDE.md` não é "configure e esqueça". É um documento vivo.

**Adicione quando:** você corrigiu o Claude no mesmo erro 2+ vezes em sessões diferentes. Vire isso uma linha.

**Remova quando:** você não consegue justificar por que uma linha está ali, ou ela descreve algo que o Claude já infere do código.

**Refatore quando:** o arquivo passar de ~150 linhas. Provavelmente algumas seções podem virar `CLAUDE.md` em subdiretório ou skill.

**Use o `/init`** para projetos novos — ele gera um esqueleto baseado no código. Mas **delete agressivamente** o que ele coloca a mais. É mais fácil deletar do que escrever do zero.

---

## 6. Anti-padrões comuns

Evite estes erros, que aparecem em 80% dos `CLAUDE.md` que circulam por aí.

**Genérico demais.** "Escreva código limpo e testável" não ajuda — todo modelo já tenta fazer isso. Substitua por regras específicas: "extraia lógica de `build()` para métodos quando passar de 30 linhas".

**Tudo num arquivo só.** Schema de banco, regras de UI, convenções de commit, deploy — tudo junto. Resultado: o Claude se distrai com o que não é relevante para a tarefa atual. Use subdiretórios e skills.

**Documentar o óbvio do código.** Se o Claude vai ler `pubspec.yaml`, não repita as dependências no `CLAUDE.md`. Mantenha o `CLAUDE.md` para o que **não está no código**.

**Instruções contraditórias.** "Sempre use Provider" no raiz e "use Riverpod" num subdiretório. Isso quebra o modelo. Faça auditorias periódicas.

**Esquecer de versionar.** `CLAUDE.md` deve estar no Git. Se ele muda, a mudança é histórica e revisável como qualquer código.

---

## 7. Checklist final

Antes de commitar seu `CLAUDE.md`, passe por estas perguntas:

- O arquivo tem menos de 200 linhas?
- Cada linha responde "o Claude erraria sem isso?" com sim?
- O cabeçalho descreve o projeto em 1 frase?
- Os comandos listados são os que eu digito de verdade?
- As convenções são específicas e acionáveis (não genéricas)?
- Há uma seção de "não fazer" com comportamentos já observados?
- Regras que só importam em partes específicas estão em subdiretórios ou skills?
- Não há contradição com outros `CLAUDE.md` ou skills do projeto?

---

**Referências consultadas:** documentação oficial do Claude Code (code.claude.com/docs), blog Anthropic ("Using CLAUDE.md files"), HumanLayer Blog ("Writing a good CLAUDE.md"), Builder.io ("How to Write a Good CLAUDE.md File"), e best-practices da comunidade no GitHub.