---
name: flow
description: Maps a feature or process end-to-end by scanning the current project and generates a Markdown document in ./flow/ describing the full flow — files involved, call order, layer responsibilities, and business rules. Use this skill whenever the user asks to "create a flow", "map the flow of X", "document the login/checkout/signup flow", "flow do login", "fluxo do checkout", "fluxo de criação de usuário", "como funciona o fluxo de X", "explica o fluxo de X", "mapear como X funciona no projeto", or any request to understand how a specific feature works across the codebase from entry point to data layer. Always prefer this skill over ad-hoc explanations when the user wants a saveable, structured document tracing a feature through the project.
---

# Flow

## O que esta skill faz

Analisa o repositório atual e gera um documento Markdown em `./flow/<nome-do-fluxo>.md` mapeando, de ponta a ponta, como um fluxo (feature, processo ou caso de uso) funciona no projeto: quais arquivos participam, em que ordem são acionados, qual a responsabilidade de cada camada e quais regras de negócio relevantes existem no código.

O objetivo é dar ao desenvolvedor (ou a outra IA) uma fotografia precisa e navegável do fluxo, suficiente para entender, depurar ou estender a feature sem precisar redescobrir o caminho lendo o código inteiro.

---

## Fluxo de Execução

### 1. Entender qual fluxo mapear

O usuário descreve o fluxo em linguagem natural ("flow do login", "fluxo do checkout", "como funciona o cadastro de usuário"). Antes de varrer o código, fixe mentalmente:

- **Qual é o ponto de entrada?** (uma tela, um botão, uma rota, um deep link, um evento, um cron)
- **Qual é o resultado final esperado?** (navegação, persistência, chamada de API, exibição de dado, side effect)
- **Qual o escopo?** Apenas o caminho feliz, ou também erros e edge cases relevantes?

Se o nome do fluxo for ambíguo no contexto do projeto (ex: o app tem dois "checkout" diferentes), faça **uma única pergunta de clarificação**. Caso contrário, prossiga.

### 2. Varrer o projeto

Antes de escrever, mapeie o código de verdade. Não invente arquivos. Use as ferramentas disponíveis (grep/glob/view/leitura semântica) para descobrir:

- **Pontos de entrada**: Views, telas, rotas, handlers, controllers, comandos CLI, listeners, webhooks.
- **Camada de apresentação / orquestração**: Cubits, Blocs, ViewModels, Controllers, Notifiers, Reducers.
- **Camada de domínio**: Entities, Use Cases, Interfaces de Repository, regras de negócio puras.
- **Camada de dados**: Repositories (impl), DataSources, Models, clientes HTTP, queries de banco, integrações com SDKs.
- **Serviços auxiliares**: Storage, Auth, Analytics, Notifications, Feature Flags, gateways de pagamento, interceptors.
- **Configuração**: Injeção de dependência (registro do que esse fluxo usa), rotas declaradas, middlewares.
- **Testes existentes** que cobrem o fluxo (úteis para confirmar comportamento esperado).

Comece pelo nome do fluxo como termo de busca (ex: `login`, `checkout`, `signup`, `createUser`) e siga as referências: do ponto de entrada para baixo (UI → estado → repositório → datasource → API/DB), e dos serviços compartilhados de volta para a UI quando relevante (ex: interceptor que injeta token).

Se o projeto usar uma arquitetura conhecida (Clean, MVVM, MVC, Feature-first, layered), respeite a nomenclatura real do código — não force o vocabulário de uma arquitetura que o projeto não adota.

### 3. Escolher o nome do arquivo

Derive um `kebab-case` curto a partir do fluxo. Exemplos:

- "flow do login" → `login.md`
- "fluxo do checkout" → `checkout.md`
- "flow de criação de usuário" → `create-user.md`
- "flow de refresh token" → `refresh-token.md`
- "fluxo de pagamento via Pix" → `payment-pix.md`

### 4. Criar a pasta e o arquivo

```bash
mkdir -p ./flow
# salvar em ./flow/<nome>.md
```

Se o arquivo já existir, **não sobrescreva silenciosamente** — informe o usuário e pergunte se deve atualizar (preservando seções customizadas) ou regenerar do zero.

### 5. Escrever o documento usando a estrutura abaixo

---

## Estrutura do Documento (template obrigatório)

```markdown
# Flow: [Nome do Fluxo]

> **Resumo:** Uma frase descrevendo o que esse fluxo faz no produto, da perspectiva do usuário ou do sistema.

## Visão Geral

[2–5 parágrafos em prosa explicando como o fluxo funciona de ponta a ponta. Comece pelo gatilho (ex: "o usuário toca no botão Entrar"), passe pelas camadas envolvidas, e termine no efeito final (ex: "o token é salvo e o usuário é redirecionado para a Home"). Mencione decisões importantes — autenticação, validações, side effects, integrações externas — sem entrar em detalhes de implementação.]

## Passo a Passo

Sequência ordenada do que acontece, do gatilho até o resultado final. Cada passo deve referenciar o arquivo/classe/função real do projeto.

1. **[Camada/Componente]** — `caminho/do/arquivo.ext` → `MétodoOuClasse`
   Descrição curta do que acontece neste passo.
2. **[Camada/Componente]** — `caminho/do/arquivo.ext` → `MétodoOuClasse`
   Descrição curta...
3. ...

_(Use sub-itens para ramificações relevantes: erro, cache hit, retry, etc.)_

### Caminhos alternativos

- **Erro de rede:** [o que acontece e em qual arquivo é tratado]
- **Token expirado:** [...]
- **Validação falha:** [...]

_(Inclua apenas ramificações que existem de fato no código.)_

## Arquivos Envolvidos

Tabela completa dos arquivos que participam do fluxo, agrupados por camada.

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Apresentação | `caminho/arquivo.ext` | O que esse arquivo faz neste fluxo |
| Estado / ViewModel | `caminho/arquivo.ext` | ... |
| Domínio | `caminho/arquivo.ext` | ... |
| Dados | `caminho/arquivo.ext` | ... |
| Serviços | `caminho/arquivo.ext` | ... |
| Configuração | `caminho/arquivo.ext` | ... |
| Testes | `caminho/arquivo.ext` | ... |

## Regras de Negócio Relevantes

Liste regras encontradas no código que afetam o fluxo (validações, gates, limites, side effects condicionais). Para cada regra, cite o arquivo onde mora.

- **[Regra]** — `caminho/arquivo.ext`: explicação curta.
- ...

_(Se o fluxo for puramente técnico e não tiver regras de negócio, escreva "Nenhuma regra de negócio relevante além do controle de fluxo padrão.")_

## Dependências Externas

APIs, SDKs, serviços de terceiros, variáveis de ambiente ou configurações que o fluxo consome.

- ...

_(Se não houver, omita esta seção.)_

## Observações

[Notas úteis encontradas durante a análise: TODOs deixados no código, inconsistências, pontos frágeis, oportunidades de refactor, divergências entre o que o código faz e o que o nome sugere. Seja objetivo — sem opinião gratuita.]
```

---

## Regras de Qualidade

**Citações reais** — todo arquivo, classe ou método mencionado deve existir no repositório. Se você não tem certeza, releia o código antes de escrever. Não invente caminhos.

**Ordem reflete execução** — o "Passo a Passo" precisa refletir a ordem real de chamada no runtime, não a ordem em que você descobriu os arquivos.

**Nomeie a camada com a linguagem do projeto** — se o projeto chama de "Cubit" use "Cubit"; se chama de "ViewModel" use "ViewModel"; se chama de "Controller" use "Controller". Não traduza nem padronize à força.

**Profundidade adequada** — descreva o suficiente para alguém entender o caminho sem precisar abrir cada arquivo, mas sem colar o código inteiro. Uma a duas frases por passo.

**Sem placeholders** — se algo no fluxo não está claro a partir do código (ex: uma rota dinâmica, um valor vindo de configuração), escreva explicitamente "definido em runtime via X" em vez de "TBD" ou "ver depois".

**Imparcialidade** — documente o que existe. Se identificar um problema, registre-o em "Observações" de forma factual; não reescreva o fluxo do jeito que você acha que deveria ser.

**Idioma** — use o mesmo idioma da conversa com o usuário (português por padrão neste projeto).

---

## Após salvar o arquivo

Informe o usuário:

1. O caminho do arquivo gerado (ex: `./flow/login.md`).
2. Um resumo de 2–3 linhas: quantas camadas o fluxo atravessa, quantos arquivos foram mapeados, e se há alguma observação relevante encontrada.
3. Pergunte se quer detalhar algum passo, mapear um caminho alternativo específico, ou gerar o flow de outra feature.

Não modifique o código do projeto — esta skill é puramente documental.
