# Templates dos documentos de inicialização

Estruturas obrigatórias de `docs/flow/project-structure.md` (sempre criado) e `docs/flow/flow-suggestions.md` (criado apenas quando o usuário recusa gerar os flows individuais agora).

Regras de frontmatter valem para os dois: `source_commit` é o hash curto de `git rev-parse --short HEAD`, `source_state` é `clean`/`dirty` conforme `git status --porcelain`, e ambos viram `not-available` fora de um repositório Git. Em atualização, preserve o `generated_at` original e renove `verified_at`.

---

## `project-structure.md`

```markdown
---
generated_at: YYYY-MM-DD
source_commit: abc1234
source_state: clean
verified_at: YYYY-MM-DD
status: current
---

# Estrutura do Projeto: [Nome do Projeto]

> **Resumo:** Uma frase descrevendo o que o projeto faz, qual stack utiliza e qual arquitetura adota.

## Stack e Tecnologias

| Elemento | Valor |
|----------|-------|
| Linguagem | [ex: Dart, TypeScript] |
| Framework | [ex: Flutter, Next.js] |
| Gerenciador de pacotes | [ex: pub, npm] |
| Principais dependências | [libs mais relevantes] |

## Arquitetura

[2–4 frases sobre a arquitetura adotada e como as camadas se comunicam. Use o vocabulário real do código — se usa "Cubit", escreva "Cubit".]

```
[Diagrama em texto, ex:]
Presentation → Domain ← Data
```

### Regras de dependência

- [Regra real encontrada, ex: "domain não importa data". Se não houver, omita esta subseção]

## Features

| Feature | Caminho principal | Descrição resumida |
|---------|------------------|-------------------|
| [feature] | `caminho/feature/` | O que essa feature faz |

## Camadas / Módulos Compartilhados

| Tipo | Caminho | Responsabilidade |
|------|---------|-----------------|
| [ex: Widgets, Serviços, Utils, Theme] | `caminho/` | ... |

## Configuração

| Componente | Arquivo | Responsabilidade |
|-----------|---------|-----------------|
| [ex: DI, Rotas, Bootstrap, Error handling] | `caminho/arquivo.ext` | ... |

_(Inclua apenas o que existe no projeto, com o vocabulário real.)_

## Dependências Externas Principais

| Pacote | Versão | Uso no projeto |
|--------|--------|---------------|
| [pacote] | x.y.z | Para que é usado |

## Observações

[Padrões não óbvios, TODOs, inconsistências, pontos de atenção. Se não houver, omita.]
```

---

## `flow-suggestions.md`

Resumos concisos (1–2 frases) — é uma lista rápida de consulta, não documentação completa.

```markdown
---
generated_at: YYYY-MM-DD
source_commit: abc1234
source_state: clean
verified_at: YYYY-MM-DD
status: current
---

# Sugestões de Flows a Documentar

> Gerado em [data]. Invoque a skill `flow` para criar qualquer um destes flows.

## Flows Sugeridos

### [Nome da Feature]
**Arquivo a criar:** `docs/flow/<nome-kebab-case>.md`
**Resumo:** O que este flow documentaria — gatilho, camadas percorridas e resultado final.

---

[repita para cada feature detectada]

## Já documentados

- `docs/flow/project-structure.md` — Estrutura geral do projeto
```
