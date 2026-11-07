---
name: flow-init
description: Analisa o projeto inteiro e inicializa a pasta ./docs/flow/ com um documento de estrutura geral do projeto e, opcionalmente, flows individuais de cada feature. Use quando o usuário pedir "inicializar flows", "criar flows do projeto", "mapear o projeto inteiro", "documentar a estrutura do projeto", "gerar todos os flows", "flow-init", "criar mapa do projeto", ou qualquer pedido de visão documental completa de um projeto antes de começar a trabalhar nele.
license: MIT
metadata:
  version: "3.0.0"
---

# Flow Init

## O que esta skill faz

Varre o repositório e inicializa `./docs/flow/` com `project-structure.md` e, opcionalmente, um flow por feature. Se o usuário recusar os flows completos, cria `flow-suggestions.md`. Por fim, atualiza `AGENTS.md` como fonte compartilhada e garante a ponte `CLAUDE.md` com `@AGENTS.md`.

### Referências

Resolvidas a partir do diretório desta skill. Leia cada uma no momento indicado, não antes:

| Arquivo | Quando ler |
|---------|-----------|
| `references/document-templates.md` | Nos passos 2 e 4b, antes de escrever os documentos |
| `references/guide-project-instructions.md` | No passo 5, antes de gerar `AGENTS.md` — princípios, template, blocos obrigatórios e checklist |

---

## Fluxo de Execução

### Passo 1 — Detectar o stack e varrer o projeto

Não invente arquivos nem suponha estruturas — mapeie o código real.

**1a — Stack:** localize o manifesto de dependências (`pubspec.yaml`, `package.json`, `pyproject.toml`/`requirements.txt`, `go.mod`, `Cargo.toml`, `pom.xml`/`build.gradle`, `Gemfile`, `*.csproj`, `composer.json`…) e extraia nome, versão e dependências principais.

**1b — Estrutura:** mapeie ponto de entrada (`main.*`, `index.*`, `cmd/`), rotas, DI (`injector`, `container`, `locator`, `di`, `module`), bootstrap, features de primeiro nível, código compartilhado, temas/estilos e testes.

O objetivo é listar features, serviços e camadas reais antes de documentar.

**1c — Origem:** execute `git rev-parse --short HEAD` e `git status --porcelain` quando Git estiver disponível, para preencher `source_commit` e `source_state`.

---

### Passo 2 — Criar `docs/flow/project-structure.md`

Crie sempre, independente da resposta do usuário (`mkdir -p ./docs/flow`). Se o arquivo já existir, pergunte se deve atualizar ou regenerar antes de continuar.

Siga o template de `references/document-templates.md`, preenchido com o que você descobriu no Passo 1.

---

### Passo 3 — Perguntar sobre flows individuais

Exiba `Features detectadas: [feature-1], [feature-2], ...` e informe que `./docs/flow/project-structure.md` foi criado. Pergunte se deseja flows completos de todas as features agora: **Sim** gera pelo formato de `flow`; **Não** cria sugestões. Aguarde a resposta.

---

### Passo 4a — Se SIM: criar flows individuais

Se houver subagentes, despache um por feature detectada, em paralelo; cada um invoca `flow` para sua feature e salva seu próprio `docs/flow/<feature>.md`, sem sobreposição de arquivos. A thread recebe caminho + `status` de cada um e lista o resultado. Sem subagentes, gere sequencialmente como antes. Em ambos os modos, cada flow segue exatamente o template/processo de `flow`, referencia só arquivos reais e passa pelas duas checagens dessa skill. Ao final, informe quantidade e caminhos.

### Passo 4b — Se NÃO: criar `docs/flow/flow-suggestions.md`

Siga o template de `references/document-templates.md`, listando as features detectadas no Passo 1.

---

### Passo 5 — Atualizar as instruções compartilhadas

Após criar os flows, use esta estrutura em qualquer plataforma:

- **`AGENTS.md` é o arquivo canônico:** concentra as instruções completas e compartilhadas do projeto.
- **`CLAUDE.md` é a ponte para o Claude Code:** importa o arquivo canônico com `@AGENTS.md`.

Antes de substituir arquivos, leia os existentes e preserve instruções válidas e específicas. Como `AGENTS.md` é compartilhado, use linguagem neutra como "invoque a skill `flow`", sem `/brain-flows:flow` ou `$flow`.

**5a — Guia:** leia `references/guide-project-instructions.md` e aplique instruções específicas, acionáveis e sem redundância.

**5b — `AGENTS.md`:** gere pelo template enxuto (seção 4), usando o Passo 1, anexando os blocos obrigatórios (4.1) e aplicando o checklist (7).

Não invente seções — inclua apenas o que sabe de fato. Migre instruções anteriores válidas e específicas; descarte as genéricas.

**5c — Ponte:** crie ou valide `CLAUDE.md` conforme a seção 2 de `references/guide-project-instructions.md`.

---

### Passo 6 — Autorrevisar a documentação

Antes de finalizar, confronte cada documento com o repositório: caminhos, features, dependências, comandos e vocabulário devem ter evidência; não pode haver placeholders; `source_commit`, `source_state` e `verified_at` devem refletir a revisão; preserve `generated_at` e customizações; `AGENTS.md` deve ser compartilhável; `CLAUDE.md` deve começar com `@AGENTS.md` ou ser link válido, sem duplicação.

Use `status: current` somente nos documentos que passaram por essa revisão. Se uma referência não puder ser confirmada, explique a limitação em **Observações** e marque o documento como `possibly-stale`. Use `draft` para documento incompleto e `archived` apenas por decisão explícita do usuário.

Flows do Passo 4a também passam pela checklist de autorrevisão e pelos critérios de utilidade de `flow`; só então recebem `status: current`.

---

## Regras de Qualidade

**Regras:** documente apenas o que existe, use o vocabulário real, liste features como módulos distintos, preserve datas e sinalize `source_state: dirty` em alterações locais. Não modifique código: apenas flows, `AGENTS.md` e a ponte `CLAUDE.md`.

---

## Ao finalizar

Informe: quais arquivos foram criados em `./docs/flow/`, o status de verificação de cada um, que `AGENTS.md` foi reescrito com base no guia — incluindo o bloco que faz o agente consultar e atualizar os flows em toda tarefa —, o estado da ponte `CLAUDE.md`, e como invocar a skill `flow` para documentar features novas.
