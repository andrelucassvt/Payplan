---
name: writing-plan
description: Generates a structured Markdown implementation plan and saves it to the /plan folder. Use this skill whenever the user asks to "create a plan", "write a plan", "make a plan", "plan this feature", "draft a plan for", "gerar um plano", "criar um plano", "escrever um plano", or describes any multi-step task they want planned out — even if they just say "plan this" or "how should I approach X". Also triggers when the user shares a feature description, refactoring goal, or implementation request and wants a roadmap before coding. Always prefer this skill over ad-hoc bullet lists when the user wants a reusable, saveable plan document.
---

# Writing Plan

## O que esta skill faz

Gera um plano estruturado em Markdown e salva em `./plan/<nome-do-plano>.md` (cria a pasta se não existir).

O plano segue o padrão das melhores práticas de planejamento de software: objetivo claro, fases com checkboxes, passos acionáveis, verificações e critérios de sucesso.

---

## Fluxo de Execução

### 1. Entender o contexto

Antes de escrever o plano, responda mentalmente:

- **O que** precisa ser feito? (feature, refactor, fix, investigação, deploy)
- **Por quê?** Qual problema resolve?
- **Quais arquivos/sistemas** estão envolvidos?
- **Qual o critério de conclusão?** Como saber que está pronto?

Se o prompt for vago, faça **uma única pergunta de clarificação** antes de prosseguir. Não faça múltiplas perguntas — escolha a mais importante.

### 1.5. Classificar o tipo de mudança

Antes de montar as fases, classifique o escopo:

**UI-only** — mudanças que envolvem apenas:
- Estrutura visual de Views/telas (layout, componentes, estilos, animações)
- Extração de componentes para subpastas de UI
- Ajustes de rota sem nova lógica
- Textos, traduções, assets

→ **Não inclua fases de teste no plano.**

**Logic** — mudanças que envolvem qualquer um dos itens abaixo:
- Camada de estado/domínio (ViewModels, Cubits, Controllers, Stores, Reducers…)
- Serviços de negócio ou sistema
- Interfaces ou implementações de Repository
- DataSources, clientes HTTP, acesso a banco

→ **Aplique TDD: a fase de testes vem ANTES da implementação da lógica.** Os testes definem o contrato; a implementação os faz passar.

### 2. Verificar flows existentes

Antes de escrever o plano, verifique se já existe um flow da funcionalidade em `./flow/`.

```bash
ls ./flow/ 2>/dev/null
```

**Se existir um flow relacionado** (ex: planejando mudanças no login → existe `./flow/login.md`):
- Leia o arquivo completo
- Use as informações do flow (arquivos envolvidos, ordem de execução, regras de negócio) para preencher o plano com caminhos reais de arquivo e detalhes de implementação mais precisos
- Se o plano envolver mudanças **estruturais** (novos arquivos, renomeação de camadas, mudança de responsabilidade), adicione uma fase final no plano: **"Atualizar Flow"** com os passos concretos de o que atualizar em `./flow/<nome>.md`
- Se for apenas mudança interna sem impacto estrutural, não precisa de fase de atualização

**Se não existir nenhum flow relacionado:**
- Continue normalmente com o plano
- Adicione uma seção ao final do plano (fora das fases) chamada `## Após a Implementação` com o seguinte conteúdo:

```markdown
## Após a Implementação

> Perguntar ao usuário: "Deseja criar um flow dessa funcionalidade em `./flow/`? Ele documenta o caminho completo do fluxo (UI → Cubit → Repository → DataSource) e serve de referência para futuros planos e revisões."
```

Essa pergunta deve **sempre** ser feita quando não há flow — nunca assuma que o usuário não quer.

### 3. Escolher o nome do arquivo

Derive um `kebab-case` conciso do objetivo. Exemplos:
- "plano para tela de login" → `login-screen.md`
- "refatorar repositório de usuário" → `refactor-user-repository.md`
- "implementar push notifications" → `implement-push-notifications.md`

### 4. Criar a pasta e o arquivo

```bash
mkdir -p ./plan
# salvar em ./plan/<nome>.md
```

### 5. Escrever o plano usando a estrutura abaixo

---

## Estrutura do Plano (template obrigatório)

```markdown
# [Título do Plano]

> **Objetivo:** Uma frase descrevendo o que será entregue ao final.

## Contexto

[2–4 frases explicando o estado atual, o problema ou a motivação. Por que isso precisa ser feito agora?]

## Arquitetura / Escopo

[Diagrama textual ou tabela mapeando os arquivos/módulos afetados e suas responsabilidades. Inclua apenas o que muda ou é criado.]

| Arquivo | Ação | Responsabilidade |
|---------|------|-----------------|
| `<caminho>` | criar | ... |

## Fases

<!-- 
  ATENÇÃO AO GERAR O PLANO:
  - Mudança UI-only → use o template A (sem testes)
  - Mudança que envolve camada de estado / serviço / repositório / datasource → use o template B (TDD: testes antes da implementação)
  Remova este comentário e o template que não se aplica antes de salvar.
-->

<!-- TEMPLATE A — UI-only (sem testes) -->
### Fase 1 — [Nome da Fase]

- [ ] Passo 1: [ação concreta com arquivo e componente]
- [ ] Passo 2: ...
- [ ] Verificação: [como confirmar visualmente que a fase está completa]

### Fase 2 — [Nome da Fase]

- [ ] ...
- [ ] Verificação: ...

_(repita para cada fase)_

---

<!-- TEMPLATE B — Logic (TDD: testes primeiro) -->
### Fase 1 — Testes (contrato antes da implementação)

> Escreva os testes que definem o comportamento esperado. Eles vão falhar inicialmente — isso é intencional.

- [ ] Criar `<caminho>/test/<arquivo>.test.<ext>`
- [ ] Testar caso de sucesso: [descrição]
- [ ] Testar caso de erro/falha: [descrição]
- [ ] Testar estado de loading (quando aplicável)
- [ ] Verificação: todos os testes compilam e falham pelos motivos certos (não por erro de sintaxe)

### Fase 2 — Implementação (fazer os testes passarem)

- [ ] Implementar [ViewModel / Service / Repository / DataSource] em `<caminho>`
- [ ] Registrar no container de DI se necessário
- [ ] Verificação: testes passam sem erros

### Fase 3 — UI (se houver interface para a lógica implementada)

- [ ] Conectar View à camada de estado
- [ ] Verificação: fluxo visual funciona de ponta a ponta

_(repita fases de implementação/UI conforme necessário)_

## Critérios de Sucesso

- [ ] [resultado observável 1]
- [ ] [resultado observável 2]
- [ ] Build sem erros
- [ ] _(somente para mudanças Logic)_ Todos os testes unitários passando

## Riscos e Mitigações

| Risco | Probabilidade | Mitigação |
|-------|--------------|-----------|
| ... | Baixa/Média/Alta | ... |

## Rollback

[Como desfazer as mudanças se algo der errado. Se não aplicável, escreva "N/A".]
```

---

## Regras de Qualidade

**Passos acionáveis** — cada item de checkbox deve ser específico o suficiente para ser executado sem ambiguidade. Ruim: "adicionar validação". Bom: "adicionar validação de email em `src/features/login/components/EmailField.tsx`".

**Sem placeholders vagos** — nunca escreva "TBD", "ver depois", "adicionar lógica aqui". Se não souber, diga explicitamente o que precisa ser investigado e por quê.

**Fases sequenciais e seguras** — ordene para que cada fase possa ser concluída e verificada antes da próxima começar. Mudanças de tipos/interfaces vêm antes de implementações.

**Tamanho das fases** — idealmente 3–7 passos por fase. Se uma fase ficar grande, divida.

**Seção de riscos não é opcional para planos com 3+ fases** — qualquer plano não trivial deve listar pelo menos um risco real.

---

## Após salvar o arquivo

Informe o usuário:
1. O caminho do arquivo gerado (ex: `./plan/login-screen.md`)
2. Um resumo de 2–3 linhas do plano (quantas fases, escopo geral)
3. Pergunte se quer ajustar algo antes de começar a execução

Não execute o plano automaticamente — a decisão de começar é do usuário.
