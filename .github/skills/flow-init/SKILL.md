---
name: flow-init
description: Analisa o projeto inteiro e inicializa a pasta ./flow/ com um documento de estrutura geral do projeto e, opcionalmente, flows individuais de cada feature. Use sempre que o usuário pedir "inicializar flows", "criar flows do projeto", "mapear o projeto inteiro", "documentar a estrutura do projeto", "gerar todos os flows", "flow-init", "quero criar os flows do projeto", "criar mapa do projeto", "iniciar documentação de flows", "mapear features do projeto", ou qualquer pedido para ter uma visão documental completa de um projeto antes de começar a trabalhar nele. Prefira sempre esta skill sobre criar flows individuais manualmente quando o objetivo for ter uma base documental inicial do projeto.
disable-model-invocation: true
---

# Flow Init

## O que esta skill faz

Varre o repositório e inicializa a pasta `./flow/` com dois tipos de documentos:

1. **`flow/project-structure.md`** — sempre criado. Documenta a estrutura geral do projeto: stack detectado, arquitetura adotada, camadas, features existentes, serviços compartilhados e configuração.
2. **Flows individuais por feature** — opcionais. Criados seguindo o mesmo formato da skill `flow`, um por feature detectada.

Se o usuário optar por não gerar os flows completos agora, cria **`flow/flow-suggestions.md`** com a lista das features detectadas e um resumo do que cada flow cobriria — para que a equipe saiba o que falta documentar.

Por fim, atualiza o `CLAUDE.md` do projeto para registrar a existência da pasta `./flow/`, para que futuras sessões saibam que essa documentação existe.

---

## Fluxo de Execução

### Passo 1 — Detectar o stack e varrer o projeto

Antes de gerar qualquer arquivo, identifique o stack e mapeie o código real. Não invente arquivos nem suponha estruturas.

#### 1a — Identificar o stack

Procure os arquivos de manifesto/configuração de dependências mais comuns:

| Stack | Arquivo indicador |
|-------|------------------|
| Flutter / Dart | `pubspec.yaml` |
| Node.js / JS / TS | `package.json` |
| Python | `requirements.txt`, `pyproject.toml`, `setup.py`, `Pipfile` |
| Java / Kotlin (Maven) | `pom.xml` |
| Java / Kotlin (Gradle) | `build.gradle`, `build.gradle.kts` |
| Ruby | `Gemfile` |
| Go | `go.mod` |
| Rust | `Cargo.toml` |
| .NET / C# | `*.csproj`, `*.sln` |
| PHP | `composer.json` |

Leia o arquivo encontrado para extrair: nome do projeto, versão e dependências principais.

#### 1b — Mapear a estrutura do projeto

Com base no stack identificado, escaneie as pastas e arquivos mais relevantes:

- **Ponto de entrada do app**: `main.*`, `index.*`, `app.*`, `server.*`, `cmd/`, `src/main/`, ou equivalente
- **Configuração de rotas / navegação**: arquivos com `router`, `routes`, `navigation`, `urls` no nome
- **Injeção de dependência / Service Locator / Container**: arquivos com `injector`, `container`, `locator`, `di`, `provider`, `module` no nome
- **Inicialização / bootstrap**: arquivos com `initializer`, `bootstrap`, `setup`, `startup` no nome
- **Features / módulos / domínios**: pastas de primeiro nível dentro de `src/`, `lib/`, `app/`, `modules/`, `features/`, `pages/` ou equivalente
- **Código compartilhado**: pastas com `common`, `shared`, `core`, `utils`, `helpers`, `components`, `services` no nome
- **Temas / estilos**: pastas com `theme`, `styles`, `design`, `tokens` no nome
- **Testes**: pastas `test/`, `tests/`, `spec/`, `__tests__/` — verifique se há testes e qual a cobertura geral

O objetivo é ter uma lista real de features, serviços e camadas antes de escrever uma linha de documentação.

---

### Passo 2 — Criar `flow/project-structure.md`

Crie sempre, independente da resposta do usuário.

```bash
mkdir -p ./flow
```

Se o arquivo já existir, informe o usuário e pergunte se deve atualizar ou regenerar do zero antes de continuar.

#### Template obrigatório para `project-structure.md`

```markdown
# Estrutura do Projeto: [Nome do Projeto]

> **Resumo:** Uma frase descrevendo o que o projeto faz, qual stack utiliza e qual arquitetura adota.

## Stack e Tecnologias

| Elemento | Valor |
|----------|-------|
| Linguagem | [ex: Dart, TypeScript, Python, Java] |
| Framework | [ex: Flutter, Next.js, FastAPI, Spring Boot] |
| Gerenciador de pacotes | [ex: pub, npm, pip, maven] |
| Principais dependências | [lista resumida das libs mais relevantes] |

## Arquitetura

[Descreva a arquitetura adotada — Clean Architecture, MVVM, MVC, Hexagonal, Feature-first, Layered, etc. — em 2–4 frases. Mencione as camadas principais e como elas se comunicam. Use o vocabulário real do código — se o projeto usa "Cubit", escreva "Cubit"; se usa "ViewModel", escreva "ViewModel"; se usa "Controller", escreva "Controller".]

```
[Diagrama em texto da arquitetura, ex:]
Presentation → Domain ← Data
UI → Store → API
Request → Handler → Service → Repository → Database
```

### Regras de dependência

- [Regra real encontrada no projeto, ex: "domain não importa data"]
- [Se não houver regras explícitas, omita esta subseção]

## Features

Lista das features/módulos/domínios detectados no projeto.

| Feature | Caminho principal | Descrição resumida |
|---------|------------------|-------------------|
| [feature] | `caminho/feature/` | O que essa feature faz |
| ... | ... | ... |

## Camadas / Módulos Compartilhados

Liste os componentes de uso global (fora das features individuais).

| Tipo | Caminho | Responsabilidade |
|------|---------|-----------------|
| [ex: Widgets / Components] | `caminho/` | ... |
| [ex: Serviços / Services] | `caminho/` | ... |
| [ex: Utils / Helpers] | `caminho/` | ... |
| [ex: Estilos / Theme] | `caminho/` | ... |

## Configuração

| Componente | Arquivo | Responsabilidade |
|-----------|---------|-----------------|
| [ex: DI / Injeção / Container] | `caminho/arquivo.ext` | Registro de dependências |
| [ex: Rotas / URLs] | `caminho/arquivo.ext` | Declaração e navegação |
| [ex: Inicialização / Bootstrap] | `caminho/arquivo.ext` | Startup do app |
| [ex: Error handling] | `caminho/arquivo.ext` | Padrão de tratamento de erros |

_(Inclua apenas os componentes que existem no projeto. Adapte os nomes ao vocabulário real.)_

## Dependências Externas Principais

| Pacote / Biblioteca | Versão | Uso no projeto |
|--------------------|--------|---------------|
| [pacote] | x.y.z | Para que é usado |
| ... | ... | ... |

## Observações

[Notas relevantes sobre o projeto: padrões não óbvios, TODOs encontrados no setup, inconsistências na estrutura, pontos de atenção para quem for trabalhar no projeto. Se não houver nada relevante, omita esta seção.]
```

---

### Passo 3 — Perguntar sobre flows individuais

Após criar `project-structure.md`, exiba para o usuário a lista de features detectadas e faça a pergunta:

```
Criei o documento de estrutura do projeto em `./flow/project-structure.md`.

Features detectadas: [feature-1], [feature-2], [feature-3], ...

Deseja que eu crie os flows completos de todas as features agora?
- **Sim** — gero todos seguindo o formato da skill `flow`
- **Não** — crio um arquivo de sugestões com o que falta documentar
```

Aguarde a resposta antes de continuar.

---

### Passo 4a — Se SIM: criar flows individuais

Para cada feature detectada, crie um documento `./flow/<feature>.md` seguindo **exatamente** o mesmo template e processo da skill `flow`:

1. Varra o código real da feature (ponto de entrada, camadas, arquivos envolvidos)
2. Escreva o documento com: Resumo, Visão Geral, Passo a Passo, Arquivos Envolvidos, Regras de Negócio, Dependências Externas, Observações
3. Referencie apenas arquivos que existem no repositório

Ao final, informe o usuário quantos flows foram criados e liste os caminhos.

---

### Passo 4b — Se NÃO: criar `flow/flow-suggestions.md`

Crie o arquivo com a lista de flows sugeridos. Cada item deve ter título e um resumo curto — suficiente para alguém entender o que o flow cobriria e decidir qual criar primeiro.

#### Template obrigatório para `flow-suggestions.md`

```markdown
# Sugestões de Flows a Documentar

> Gerado em [data]. Execute `/flow <nome>` para criar qualquer um destes flows.

## Flows Sugeridos

### [Nome da Feature]
**Arquivo a criar:** `flow/<nome-kebab-case>.md`
**Resumo:** O que este flow documentaria — qual o gatilho, quais camadas percorre e qual o resultado final.

---

### [Nome da Feature]
**Arquivo a criar:** `flow/<nome-kebab-case>.md`
**Resumo:** ...

---

[repita para cada feature detectada]

## Já documentados

- `flow/project-structure.md` — Estrutura geral do projeto
```

Mantenha os resumos concisos (1–2 frases cada). O objetivo é uma lista rápida de consulta, não documentação completa.

---

### Passo 5 — Reescrever o `CLAUDE.md`

Após criar os arquivos de flow, **sempre** gere um `CLAUDE.md` novo do zero — independente de já existir um. Não faça atualização parcial; substitua o arquivo inteiro.

#### 5a — Ler o guia de boas práticas

Antes de escrever o `CLAUDE.md`, leia o guia em:

```
.claude/skills/flow-init/references/guide-claude-md.md
```

Internalize os princípios: menos é mais, instruções específicas e acionáveis, sem redundância com o que o código já comunica.

#### 5b — Gerar o `CLAUDE.md` do zero

Use o template enxuto do guia (seção 4) como base. Preencha com o que você descobriu no Passo 1. Aplique o checklist (seção 7) antes de salvar:

- Cabeçalho de 1 frase descrevendo o projeto
- Stack com versões importantes e decisões que o Claude não infere do código
- Estrutura: diretórios e seus propósitos (não arquivos individuais)
- Comandos que serão usados de verdade
- Convenções específicas e acionáveis (não genéricas)
- Gotchas: armadilhas reais encontradas na análise + workarounds
- Não fazer: comportamentos concretos a evitar

Não invente seções — inclua apenas o que sabe de fato sobre o projeto. Se o `CLAUDE.md` anterior tinha instruções válidas e específicas, migre-as; descarte genéricas.

Adicione ao final a seção de flows:

```markdown
## 📖 Documentação de Flows

Para qualquer feature ou fluxo, verifique a pasta `./flow/`: leia os títulos dos arquivos `.md` disponíveis e, se algum for relevante para a tarefa atual, leia-o antes de implementar ou debugar. Use `/flow <nome>` para criar ou atualizar flows individuais.
```

---

## Regras de Qualidade

**Apenas o que existe** — não documente arquivos, classes ou rotas que você não encontrou no código. Se algo parece estar faltando, registre em Observações.

**Use o vocabulário do projeto** — se o projeto chama de "Cubit", use "Cubit". Se usa "Controller", use "Controller". Se usa "Handler", use "Handler". Não imponha terminologia externa.

**Seja conservador nas sugestões** — liste como feature apenas o que você encontrou como pasta ou módulo distinto. Não fragmente demais nem agrupe features não relacionadas.

**Não modifique código** — esta skill é puramente documental. Não altere arquivos de código-fonte ou configuração além do `CLAUDE.md`.

**Idioma** — use o mesmo idioma da conversa com o usuário.

---

## Ao finalizar

Informe o usuário:

1. Quais arquivos foram criados em `./flow/`
2. Que o `CLAUDE.md` foi reescrito do zero com base no guia de boas práticas
3. Como usar a skill `flow` para criar ou atualizar flows individuais no futuro
