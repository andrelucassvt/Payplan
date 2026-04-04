# Base App Flutter — Claude Code Instructions

Este arquivo é lido pelo Claude Code e serve como ponto de entrada para todas as instruções do projeto.

---

## Regra Obrigatória de Leitura

**Antes de gerar ou modificar qualquer código**, leia SEMPRE o arquivo `.github/instructions/architecture.instructions.md` — ele contém as regras gerais de arquitetura que se aplicam a todo o projeto.

Depois, **conforme o contexto da tarefa**, leia a skill correspondente à camada que será modificada (veja tabela de Skills abaixo).

---

## 📂 Arquivos de Instrução

Leia o arquivo correspondente antes de trabalhar na camada indicada:

| Arquivo | Quando ler |
|---|---|
| `.claude/rules/architecture.instructions.md` | **Sempre** — regras gerais de arquitetura |

---

## 🛠️ Skills Especializadas

Skills são capacidades especializadas. Leia o arquivo da skill **antes** de executar a tarefa correspondente:

| Skill | Arquivo | Quando usar |
|---|---|---|
| `implement-view` | `.claude/skills/implement-view/SKILL.md` | Ao criar ou modificar Views em `lib/presentation/**/view/**` |
| `implement-view-model` | `.claude/skills/implement-view-model/SKILL.md` | Ao criar ou modificar Cubits/States em `lib/presentation/**/view_model/**` |
| `implement-widget` | `.claude/skills/implement-widget/SKILL.md` | Ao criar ou modificar Widgets em `lib/presentation/**/widgets/**` ou `lib/common/widgets/**` |
| `implement-domain` | `.claude/skills/implement-domain/SKILL.md` | Ao trabalhar em `lib/domain/**` |
| `implement-data` | `.claude/skills/implement-data/SKILL.md` | Ao trabalhar em `lib/data/**` |
| `configure-di` | `.claude/skills/configure-di/SKILL.md` | Ao trabalhar em `lib/config/inject/**` |
| `configure-navigation` | `.claude/skills/configure-navigation/SKILL.md` | Ao trabalhar em `lib/config/routes/**` ou navegação |
| `implement-in-app-purchase` | `.claude/skills/implement-in-app-purchase/SKILL.md` | Ao implementar compras in-app, assinaturas ou paywall |
| `implement-admob` | `.claude/skills/implement-admob/SKILL.md` | Ao trabalhar com anúncios AdMob |
| `custom-paint` | `.claude/skills/custom-paint/SKILL.md` | Ao desenhar formas, gráficos, animações canvas ou qualquer pintura 2D com CustomPaint/CustomPainter |
| `guideline-apple` | `.claude/skills/guideline-apple/SKILL.md` | Ao revisar, preparar ou auditar o app para submissão na App Store |
| `implement-auth-token-flow` | `.claude/skills/implement-auth-token-flow/SKILL.md` | Ao implementar autenticação com Bearer token, login, refresh token ou logout |
| `implement-firebase-notifications` | `.claude/skills/implement-firebase-notifications/SKILL.md` | Ao implementar ou auditar push notifications via Firebase Cloud Messaging (iOS + Android) |
| `flutter-isolates` | `.claude/skills/flutter-isolates/SKILL.md` | Ao trabalhar com paralelismo, concorrência, performance de UI, jank ou tarefas CPU-intensivas — compute(), Isolate.spawn, Isolate.run, SendPort, ReceivePort |
| `flutter-animating-apps` | `.claude/skills/flutter-animating-apps/SKILL.md` | Ao implementar animações visuais, efeitos, transições de tela, hero animations, animações implícitas/explícitas ou physics-based animations |

---

## 📝 Prompts Disponíveis

Prompt files em `.github/prompts/` para tarefas pré-definidas:

| Prompt | Descrição |
|---|---|
| `.github/prompts/analyze_view.prompt.md` | Auditar/analisar arquivos de View |
| `.github/prompts/commit.prompt.md` | Gerar mensagens de commit |
| `.github/prompts/create.prompt.md` | Criar nova feature |
| `.github/prompts/project_plan.prompt.md` | Gerar plano de projeto |
| `.github/prompts/refactore.prompt.md` | Refatorar um módulo existente com base nas instruções e skills do projeto |

---

## ⚡ Regras Globais (resumo)

- **Arquitetura**: `presentation` → `domain` ← `data` (Clean Architecture)
- **Imports**: SEMPRE absolutos — `package:base_app/...` — NUNCA relativos
- **State management**: Cubit (BLoC) — `flutter_bloc`
- **Error handling**: `Result<T>` (Ok/Error) — NUNCA relance exceções
- **DI**: GetIt via `AppInjector` — Cubits → `registerFactory`; resto → `registerLazySingleton`
- **Navegação**: GoRouter — SEMPRE na View ou `BlocListener`, NUNCA no Cubit
- **Textos na UI**: SEMPRE `context.l10n.<chave>` — ZERO strings hardcoded
- **Entities**: `@immutable`, `const`, `final`, `copyWith()`, `==`, `hashCode`
- **SafeArea**: SEMPRE envolva o conteúdo principal da View com `SafeArea`
- **Performance**: NUNCA crie `Widget _buildXxx()` nem classes privadas de widget dentro da View — extraia para `widgets/` (reutilizável) ou `content/` (auxiliar específico); dialog/bottomSheet são exceção
- **Repositories**: SEMPRE envolva chamadas em `try/catch` e retorne `Result.error(...)`
- **Cubit async**: SEMPRE emita `Loading` primeiro → chame o repository → use `result.when()`
- **Nunca** crie arquivos `.md` para documentar mudanças de código

## 🧭 Fluxo para nova feature

1. **Mínimo obrigatório**: View + Cubit + State + rota + DI
2. **Dados locais**: injete `StorageService` diretamente no Cubit
3. **API externa**: crie também Entity + Repository Interface + Model + DataSource + RepositoryImpl
4. Siga a estrutura de pastas descrita em `.github/instructions/architecture.instructions.md`
