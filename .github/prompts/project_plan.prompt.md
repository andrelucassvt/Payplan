---
agent: agent
---

**IMPORTANTE: Antes de iniciar, você DEVE:**

1. Ler `.github/instructions/architecture.instructions.md` para entender a arquitetura geral do projeto (Clean Architecture + BLoC, padrões de nomenclatura, estrutura de pastas, convenções de código e anti-patterns).

2. Após entender a arquitetura, siga as etapas abaixo.

---

## Etapa 1 — Entendimento do Projeto

Faça as seguintes perguntas ao usuário (todas de uma vez) para coletar as informações necessárias:

1. **Nome do projeto**: Qual é o nome do app?
2. **Descrição**: O que o app faz? Qual problema resolve?
3. **Público-alvo**: Para quem é o app?
4. **Principais funcionalidades**: Quais são as telas e features principais?
5. **Integrações externas**: Haverá consumo de API, autenticação, pagamentos, notificações push, ou outros serviços?
6. **Armazenamento local**: Precisa salvar dados localmente (preferências, cache, dados offline)?
7. **Flavors**: Quais ambientes serão utilizados (development, staging, production)?
8. **Idiomas**: O app será apenas em português, inglês, ou multilíngue?

---

## Etapa 2 — Plano de Desenvolvimento

Com base nas respostas, gere um **Plano de Desenvolvimento** estruturado contendo:

### 2.1 Features e Telas

Liste todas as features identificadas com:
- Nome da feature
- Telas envolvidas
- Camadas necessárias (somente Presentation, ou também Domain + Data)
- Ordem de implementação sugerida (prioridade)

### 2.2 Estrutura de Pastas Esperada

Mostre a estrutura de pastas que o projeto terá ao final, seguindo a arquitetura obrigatória do projeto.

### 2.3 Integrações e Serviços

Liste os serviços externos, pacotes adicionais e configurações necessárias (ex: Dio, Firebase, in_app_purchase, etc).

### 2.4 Checklist de Implementação

Gere um checklist ordenado com todos os passos de implementação, do setup inicial até a entrega:

- [ ] Configurar flavors (development, staging, production)
- [ ] Configurar DI no AppInjector
- [ ] Criar feature: splash
- [ ] Criar feature: auth (login, cadastro)
- [ ] Criar feature: home
- [ ] ...

---

## Etapa 3 — Gerar Arquivo do Projeto

Após montar o plano, crie o arquivo `.github/PROJECT.md` com a estrutura abaixo, preenchida com as informações coletadas:

- **Nome do Projeto**
- **Descrição**
- **Público-alvo**
- **Flavors** (ambientes)
- **Idiomas suportados**
- **Features** (lista com descrição de cada uma)
- **Integrações externas**
- **Estrutura de pastas** (árvore completa esperada)
- **Plano de Desenvolvimento** (checklist ordenado)
- **Padrões Técnicos**:
  - Arquitetura: Clean Architecture (Presentation → Domain ← Data)
  - State Management: Cubit (BLoC)
  - DI: GetIt via AppInjector
  - Navegação: GoRouter
  - Error Handling: Result<T>
  - Storage: StorageService (SharedPreferences)

---

## Saída Esperada

1. Resumo das respostas coletadas.
2. Plano de desenvolvimento detalhado (Etapa 2).
3. Arquivo `.github/PROJECT.md` criado (Etapa 3).
