# GitHub Copilot Instructions — Base App Flutter

Este arquivo é lido primeiro pelo Copilot e serve como ponto de entrada para todas as instruções do projeto.
Ele referencia os arquivos filhos que detalham cada camada e contexto específico.

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
| `implement-view` | [`SKILL.md`](skills/implement-view/SKILL.md) | Ao criar ou modificar Views em `lib/presentation/**/view/**` |
| `implement-view-model` | [`SKILL.md`](skills/implement-view-model/SKILL.md) | Ao criar ou modificar Cubits/States em `lib/presentation/**/view_model/**` |
| `implement-widget` | [`SKILL.md`](skills/implement-widget/SKILL.md) | Ao criar ou modificar Widgets em `lib/presentation/**/widgets/**` ou `lib/common/widgets/**` |
| `implement-domain` | [`SKILL.md`](skills/implement-domain/SKILL.md) | Ao trabalhar em `lib/domain/**` |
| `implement-data` | [`SKILL.md`](skills/implement-data/SKILL.md) | Ao trabalhar em `lib/data/**` |
| `configure-di` | [`SKILL.md`](skills/configure-di/SKILL.md) | Ao trabalhar em `lib/config/inject/**` |
| `configure-navigation` | [`SKILL.md`](skills/configure-navigation/SKILL.md) | Ao trabalhar em `lib/config/routes/**` ou navegação |
| `analyze-view` | [`SKILL.md`](skills/analyze-view/SKILL.md) | Ao revisar, auditar ou refatorar arquivos de View |
| `implement-in-app-purchase` | [`SKILL.md`](skills/implement-in-app-purchase/SKILL.md) | Ao implementar compras in-app, assinaturas ou paywall — pergunta se há back-end e gera o código completo seguindo a arquitetura do projeto |
| `implement-admob` | [`SKILL.md`](skills/implement-admob/SKILL.md) | Ao implementar ou modificar anúncios AdMob — banner, nativo, intersticial, AdConfig, AdService e DI |
| `custom-paint` | [`SKILL.md`](skills/custom-paint/SKILL.md) | Ao desenhar formas, gráficos, animações canvas, clipping customizado ou qualquer pintura 2D com CustomPaint/CustomPainter |
| `guideline-apple` | [`SKILL.md`](skills/guideline-apple/SKILL.md) | Ao revisar, preparar ou auditar o app para submissão na App Store — verifica privacidade, IAP, ATT, SafeArea, acessibilidade, metadados e conformidade com as Apple App Store Review Guidelines |
| `implement-auth-token-flow` | [`SKILL.md`](skills/implement-auth-token-flow/SKILL.md) | Ao implementar autenticação com Bearer token — login, salvar token, refresh proativo, expiração, redirecionamento ao login e logout |
| `implement-firebase-notifications` | [`SKILL.md`](skills/implement-firebase-notifications/SKILL.md) | Ao implementar ou auditar push notifications via Firebase Cloud Messaging — cobre iOS (APNs, entitlements, AppDelegate) e Android (manifest, canal), NotificationService, DI e diagnóstico |
| `flutter-isolates` | [`SKILL.md`](skills/flutter-isolates/SKILL.md) | Ao trabalhar com paralelismo, concorrência, performance de UI, jank ou tarefas CPU-intensivas — cobre compute(), Isolate.spawn, Isolate.run, SendPort, ReceivePort e critérios de decisão |
| `flutter-animating-apps` | [`SKILL.md`](skills/flutter-animating-apps/SKILL.md) | Ao implementar animações visuais, efeitos, transições de tela, hero animations, animações implícitas/explícitas ou physics-based animations |

---

## 📝 Prompts Disponíveis

Prompt files em `.github/prompts/` para tarefas pré-definidas:

| Prompt | Descrição |
|---|---|
| [`analyze_view.prompt.md`](prompts/analyze_view.prompt.md) | Auditar/analisar arquivos de View |
| [`commit.prompt.md`](prompts/commit.prompt.md) | Gerar mensagens de commit |
| [`create.prompt.md`](prompts/create.prompt.md) | Criar nova feature |
| [`project_plan.prompt.md`](prompts/project_plan.prompt.md) | Gerar plano de projeto |
| [`refactore.prompt.md`](prompts/refactore.prompt.md) | Refatorar um módulo existente com base nas instruções e skills do projeto |

---

## ⚡ Regras Globais (resumo)

- Arquitetura em camadas: `presentation` → `domain` ← `data`
- Imports **sempre absolutos**: `package:base_app/...`
- State management: **Cubit (BLoC)**
- Error handling: **`Result<T>`** (Ok/Error)
- DI: **GetIt** via `AppInjector`
- Navegação: **GoRouter** — sempre na View, nunca no Cubit
- Textos visíveis: **sempre** `context.l10n.<chave>` — zero strings hardcoded
- Entities: `@immutable`, `const`, `final`, `copyWith()`, `==`, `hashCode`
- Cubits → `registerFactory`; todo o resto → `registerLazySingleton`
- Performance: **nunca** crie métodos `Widget _buildXxx()` nem classes privadas de widget (ex: `_RecursosContent`) dentro da View — extraia para `widgets/` se reutilizável, ou para `content/` se for auxiliar específico da View (dialog/bottomSheet são exceção)
- SafeArea: **sempre** envolva o conteúdo principal da View com `SafeArea` para respeitar limites do dispositivo
- **Nunca** crie arquivos `.md` para documentar mudanças de código
