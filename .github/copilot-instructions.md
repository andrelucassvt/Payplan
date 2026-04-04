# GitHub Copilot Instructions — Payplan

## Contexto

App Flutter de controle financeiro pessoal: gestão de dívidas, devedores, gráficos e plano premium.
Flutter 3 / Dart ^3.5.4 · Versão 2.5.5+70 · Pacote: `notes_app`
Plataformas: iOS (target 13.0) e Android (minSdk 24, targetSdk 35, compileSdk 36).
Sem flavors — único `main.dart`. Localização: pt_BR, en_US, es_ES.

---

## Prioridade de Leitura

1. **Este arquivo** — visão geral e referência central
2. **`architecture.instructions.md`** — regras gerais de arquitetura (vale para `**`)
3. Skills correspondentes à camada que está sendo modificada (listadas abaixo)

---

## 📂 Arquivos de Instrução

| Arquivo | Aplica-se a | Descrição |
|---|---|---|
| [`architecture.instructions.md`](instructions/architecture.instructions.md) | `**` | Arquitetura geral, fluxo de dados, convenções e anti-patterns |

---

## 🛠️ Agent Skills

Skills são capacidades especializadas carregadas automaticamente conforme o contexto da tarefa.
Ficam em `.github/skills/<skill-name>/SKILL.md` e seguem o padrão aberto [agentskills.io]

| Skill | Arquivo | Quando é carregada automaticamente |
|---|---|---|
| `implement-view` | [`SKILL.md`](skills/implement-view/SKILL.md) | Ao criar ou modificar Views (StatefulWidget + Cubit + BlocBuilder) ou adicionar nova tela |
| `implement-view-model` | [`SKILL.md`](skills/implement-view-model/SKILL.md) | Ao criar ou modificar Cubits/States, adicionar método async, gerenciar estados de loading/error |
| `implement-widget` | [`SKILL.md`](skills/implement-widget/SKILL.md) | Ao criar ou modificar widgets em `features/**/widgets/` ou `util/widgets/` |
| `implement-domain` | [`SKILL.md`](skills/implement-domain/SKILL.md) | Ao criar entidades, interfaces de repositório ou modelar conceitos de negócio |
| `implement-data` | [`SKILL.md`](skills/implement-data/SKILL.md) | Ao implementar chamadas de API, serialização JSON, DataSources ou RepositoryImpl |
| `configure-di` | [`SKILL.md`](skills/configure-di/SKILL.md) | Ao registrar ou modificar dependências com GetIt |
| `configure-navigation` | [`SKILL.md`](skills/configure-navigation/SKILL.md) | Ao adicionar rotas, navegação entre telas ou deep links |
| `implement-in-app-purchase` | [`SKILL.md`](skills/implement-in-app-purchase/SKILL.md) | Ao implementar compras in-app, assinaturas ou paywall (`in_app_purchase ^3.2.3`) |
| `implement-admob` | [`SKILL.md`](skills/implement-admob/SKILL.md) | Ao implementar ou modificar anúncios AdMob (`google_mobile_ads ^6.0.0`) |
| `custom-paint` | [`SKILL.md`](skills/custom-paint/SKILL.md) | Ao desenhar formas, gráficos ou animações 2D com CustomPaint/CustomPainter |
| `guideline-apple` | [`SKILL.md`](skills/guideline-apple/SKILL.md) | Ao revisar, preparar ou auditar o app para submissão na App Store |
| `implement-auth-token-flow` | [`SKILL.md`](skills/implement-auth-token-flow/SKILL.md) | Ao implementar autenticação com Bearer token, login, refresh token ou logout |
| `implement-firebase-notifications` | [`SKILL.md`](skills/implement-firebase-notifications/SKILL.md) | Ao implementar ou auditar push notifications via Firebase Cloud Messaging (iOS + Android) |
| `flutter-isolates` | [`SKILL.md`](skills/flutter-isolates/SKILL.md) | Ao trabalhar com paralelismo, concorrência, performance de UI ou tarefas CPU-intensivas |
| `flutter-animating-apps` | [`SKILL.md`](skills/flutter-animating-apps/SKILL.md) | Ao implementar animações, transições, hero animations ou efeitos visuais |
| `skill-creator` | [`SKILL.md`](skills/skill-creator/SKILL.md) | Ao criar, modificar ou otimizar arquivos de skill |

---

## 📝 Prompts Disponíveis

Prompt files em `.github/prompts/` para tarefas pré-definidas:

| Prompt | Descrição |
|---|---|
| [`analyze_view.prompt.md`](prompts/analyze_view.prompt.md) | Auditar/analisar arquivos de View |
| [`commit.prompt.md`](prompts/commit.prompt.md) | Gerar mensagens de commit |
| [`create.prompt.md`](prompts/create.prompt.md) | Criar nova feature |
| [`project_plan.prompt.md`](prompts/project_plan.prompt.md) | Gerar plano de projeto |
| [`refactore.prompt.md`](prompts/refactore.prompt.md) | Refatorar um módulo existente |
| [`init.prompt.md`](prompts/init.prompt.md) | Inicializar contexto do projeto |
| [`setup-project-context.prompt.md`](prompts/setup-project-context.prompt.md) | Atualizar arquivos de contexto da IA |

---

## ⚡ Regras Globais (resumo)

- Arquitetura em camadas: `presentation` → `domain` ← `data`
- Imports **sempre absolutos**: `package:notes_app/...`
- State management: **Cubit (BLoC)** — `flutter_bloc ^9.0.0`
- Error handling: **`Result<T>`** (Ok/Error)
- DI: **GetIt** via `AppInjector`
- Navegação: **GoRouter** — sempre na View, nunca no Cubit
- Textos visíveis: **sempre** `context.l10n.<chave>` — zero strings hardcoded (suporte: pt_BR, en_US, es_ES)
- Entities: `@immutable`, `const`, `final`, `copyWith()`, `==`, `hashCode`
- Cubits → `registerFactory`; todo o resto → `registerLazySingleton`
- Performance: **nunca** crie métodos `Widget _buildXxx()` nem classes privadas de widget dentro da View — extraia para `widgets/` se reutilizável, ou para `content/` se for auxiliar específico da View (dialog/bottomSheet são exceção)
- SafeArea: **sempre** envolva o conteúdo principal da View com `SafeArea` para respeitar limites do dispositivo
- **Nunca** crie arquivos `.md` para documentar mudanças de código

### Compatibilidade de Plataformas

| Plataforma | Status | Observações |
|---|---|---|
| iOS | ✅ Suportado | Target 13.0 · SafeArea obrigatória · APNs para notificações |
| Android | ✅ Suportado | minSdk 24 · targetSdk 35 · compileSdk 36 |
| Web | ❌ Não suportado | — |
| macOS | ❌ Não suportado | — |
| Windows | ❌ Não suportado | — |
| Linux | ❌ Não suportado | — |

### Convenções de Nomenclatura

| Elemento | Convenção | Exemplo |
|---|---|---|
| Arquivos | `snake_case` | `nova_divida_view.dart` |
| Classes | `PascalCase` | `NovaDevidaCubit` |
| Variáveis/Métodos | `camelCase` | `carregarDevedores()` |
| Privados | `_` prefix | `_cubit` |
| Features | português (BR) | `devedores/`, `nova_divida/` |

### Estrutura de Pastas

```
lib/
├── main.dart                    # Entry point — inicializa MobileAds e NotificationService
├── objectbox-model.json         # Modelo ObjectBox (gerado automaticamente)
├── i18n/                        # Strings de localização (pt_BR, en_US, es_ES)
└── src/
    ├── app_widget.dart          # Widget raiz da aplicação
    ├── features/
    │   ├── home/                # Tela principal — cubit/, view/, widgets/
    │   ├── devedores/           # Gerenciamento de devedores — cubit/, view/
    │   ├── grafico/             # Gráficos financeiros — view/, widgets/
    │   ├── nova_divida/         # Cadastro de nova dívida — view/
    │   └── plus/                # Tela de recursos premium — view/
    └── util/
        ├── colors/              # Paleta de cores do app
        ├── entity/              # Entidades de domínio
        ├── enum/                # Enumerações
        ├── extension/           # Extensions do Dart/Flutter
        ├── helpers/             # Funções utilitárias
        ├── service/             # NotificationService, AdMob helper
        ├── strings/             # Constantes de strings
        └── widgets/             # Widgets reutilizáveis globais
```
