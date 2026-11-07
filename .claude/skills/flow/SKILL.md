---
name: flow
description: Mapeia uma feature ou processo de ponta a ponta varrendo o projeto atual e gera um documento Markdown em ./docs/flow/ com os arquivos envolvidos, a ordem de chamada, a responsabilidade de cada camada e as regras de negócio. Use quando o usuário pedir "criar um flow", "mapear/documentar o flow de X", "flow do login", "fluxo do checkout", "como funciona o fluxo de X", "map how X works", ou qualquer pedido para rastrear uma feature do ponto de entrada até a camada de dados.
license: MIT
metadata:
  version: "3.0.0"
---

# Flow

## O que esta skill faz

Analisa o repositório atual e gera `./docs/flow/<nome-do-fluxo>.md` mapeando de ponta a ponta como um fluxo (feature, processo ou caso de uso) funciona: quais arquivos participam, em que ordem são acionados, qual a responsabilidade de cada camada e quais regras de negócio existem no código. O objetivo é uma fotografia precisa e navegável, suficiente para entender, depurar ou estender a feature sem redescobrir o caminho lendo o código inteiro.

### Referências

Resolvida a partir do diretório desta skill:

| Arquivo | Quando ler |
|---------|-----------|
| `references/flow-template.md` | No passo 4, antes de escrever o documento — estrutura obrigatória, regras de frontmatter, checklist de autorrevisão e critérios de utilidade |

---

## Fluxo de Execução

### 1. Entender qual fluxo mapear

Fixe: **ponto de entrada** (tela, botão, rota, deep link, evento, cron), **resultado final esperado** (navegação, persistência, chamada de API, side effect) e **escopo** (só caminho feliz, ou também erros e edge cases relevantes).

Se o nome do fluxo for ambíguo no contexto do projeto (ex: dois "checkout" diferentes), faça **uma única pergunta de clarificação**. Caso contrário, prossiga.

### 2. Varrer o projeto

Mapeie o código de verdade — não invente arquivos. Se o ambiente oferecer subagente somente-leitura, delegue a varredura com o ponto de entrada, resultado esperado e escopo do passo 1; exija um mapa estruturado com arquivos reais por camada, ordem de chamada, ramificações, regras de negócio com arquivo e testes existentes. A thread escreve o documento a partir do mapa e só relê arquivos para confirmar citações duvidosas. Sem subagente, faça a varredura diretamente.

Comece pelo nome do fluxo como termo de busca (ex: `login`, `checkout`, `createUser`) e siga as referências da UI aos dados e dos serviços compartilhados de volta à UI quando relevante.

Cubra: pontos de entrada (Views, rotas, handlers, listeners), camada de apresentação/orquestração (Cubits, ViewModels, Controllers), domínio (Entities, Use Cases, regras puras), dados (Repositories, DataSources, clientes HTTP, queries), serviços auxiliares (Storage, Auth, Analytics, interceptors), configuração (DI, rotas declaradas) e testes existentes que cobrem o fluxo.

Respeite a nomenclatura real do código — não force o vocabulário de uma arquitetura que o projeto não adota.

### 3. Criar o arquivo

Derive um nome `kebab-case` curto ("flow do login" → `login.md`; "fluxo de pagamento via Pix" → `payment-pix.md`) e salve em `./docs/flow/` (`mkdir -p ./docs/flow`).

Se o arquivo já existir, **não sobrescreva silenciosamente** — informe o usuário e pergunte se deve atualizar (preservando seções customizadas) ou regenerar do zero.

Antes de escrever, registre a rastreabilidade da análise:

```bash
git rev-parse --short HEAD 2>/dev/null
git status --porcelain 2>/dev/null
```

### 4. Escrever o documento

Leia `references/flow-template.md` e siga a estrutura obrigatória, preenchendo o frontmatter com a rastreabilidade coletada no passo 3.

### 5. Autorrevisar antes de salvar

Aplique as duas checagens de `references/flow-template.md`: a **checklist de autorrevisão**, confrontando o documento com o código analisado, e os **critérios de utilidade**, que julgam se o documento serve para depurar a feature e para o agente selecionar flows por relevância. Passar nas duas é o que permite marcar o flow como `current`.

---

## Regras de Qualidade

**Citações reais** — todo arquivo, classe ou método mencionado deve existir no repositório. Se não tem certeza, releia o código antes de escrever.

**Ordem reflete execução** — o "Passo a Passo" segue a ordem real de chamada no runtime, não a ordem de descoberta.

**Vocabulário do projeto** — se o projeto chama de "Cubit", use "Cubit"; se chama de "ViewModel", use "ViewModel". Não traduza nem padronize à força. O documento é escrito no idioma da conversa com o usuário.

**Profundidade adequada** — uma a duas frases por passo: o suficiente para entender o caminho sem abrir cada arquivo, sem colar código inteiro.

**Sem placeholders** — se algo não está claro no código (ex: rota dinâmica), escreva "definido em runtime via X" em vez de "TBD".

**Rastreabilidade honesta** — metadados descrevem o estado realmente analisado. Um commit com alterações locais deve permanecer identificado como `source_state: dirty`.

**Imparcialidade** — documente o que existe; problemas vão em "Observações" de forma factual.

---

## Após salvar o arquivo

Informe o caminho gerado, o status de verificação e um resumo de 2–3 linhas (camadas atravessadas, arquivos mapeados, observações relevantes). Pergunte se quer detalhar algum passo ou gerar o flow de outra feature.

Não modifique o código do projeto — esta skill é puramente documental.
