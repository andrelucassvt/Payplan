# Payplan — Codex Agent Instructions

App Flutter de controle financeiro pessoal: gestão de dívidas, devedores, gráficos e plano premium.
Flutter 3 / Dart ^3.5.4 · Versão 2.5.5+70 · Pacote: `notes_app`
Plataformas: **iOS** (target 13.0) e **Android** (minSdk 24, targetSdk 35, compileSdk 36).
Sem flavors — único `main.dart`. Localização: pt_BR, en_US, es_ES.

---

## Arquivos de instrução detalhados

Antes de gerar ou modificar código, leia o arquivo de arquitetura **sempre** e depois a skill correspondente à camada modificada:

| Arquivo | Quando ler |
|---|---|
| `.github/instructions/architecture.instructions.md` | **Sempre** — regras gerais de arquitetura |

## 🛠️ Skills especializadas

Leia o arquivo da skill antes de executar a tarefa correspondente:

| Skill | Arquivo | Quando usar |
|---|---|---|
| `implement-view` | `.agents/skills/implement-view/SKILL.md` | Ao criar ou modificar Views (StatefulWidget + Cubit + BlocBuilder) ou adicionar nova tela |
| `implement-view-model` | `.agents/skills/implement-view-model/SKILL.md` | Ao criar ou modificar Cubits/States, adicionar método async, gerenciar estados de loading/error |
| `implement-widget` | `.agents/skills/implement-widget/SKILL.md` | Ao criar ou modificar widgets em `features/**/widgets/` ou `util/widgets/` |
| `implement-domain` | `.agents/skills/implement-domain/SKILL.md` | Ao criar entidades, interfaces de repositório ou modelar conceitos de negócio |
| `implement-data` | `.agents/skills/implement-data/SKILL.md` | Ao implementar chamadas de API, serialização JSON, DataSources ou RepositoryImpl |
| `configure-di` | `.agents/skills/configure-di/SKILL.md` | Ao registrar ou modificar dependências com GetIt |
| `configure-navigation` | `.agents/skills/configure-navigation/SKILL.md` | Ao adicionar rotas, navegação entre telas ou deep links |
| `custom-paint` | `.agents/skills/custom-paint/SKILL.md` | Ao desenhar formas, gráficos ou animações 2D com CustomPaint/CustomPainter |
| `guideline-apple` | `.agents/skills/guideline-apple/SKILL.md` | Ao revisar, preparar ou auditar o app para submissão na App Store |
| `implement-in-app-purchase` | `.agents/skills/implement-in-app-purchase/SKILL.md` | Ao implementar compras in-app, assinaturas ou paywall (`in_app_purchase ^3.2.3`) |
| `implement-admob` | `.agents/skills/implement-admob/SKILL.md` | Ao implementar ou modificar anúncios AdMob (`google_mobile_ads ^6.0.0`) |
| `implement-auth-token-flow` | `.agents/skills/implement-auth-token-flow/SKILL.md` | Ao implementar autenticação com Bearer token, login, refresh token ou logout |
| `implement-firebase-notifications` | `.agents/skills/implement-firebase-notifications/SKILL.md` | Ao implementar ou auditar push notifications via Firebase Cloud Messaging (iOS + Android) |
| `flutter-isolates` | `.agents/skills/flutter-isolates/SKILL.md` | Ao trabalhar com paralelismo, concorrência, performance de UI ou tarefas CPU-intensivas |
| `flutter-animating-apps` | `.agents/skills/flutter-animating-apps/SKILL.md` | Ao implementar animações, transições, hero animations ou efeitos visuais |
| `skill-creator` | `.agents/skills/skill-creator/SKILL.md` | Ao criar, modificar ou otimizar arquivos de skill |

---

## 📝 Prompts Disponíveis

Prompt files em `.github/prompts/` para tarefas pré-definidas:

| Prompt | Descrição |
|---|---|
| `.github/prompts/analyze_view.prompt.md` | Auditar/analisar arquivos de View |
| `.github/prompts/commit.prompt.md` | Gerar mensagens de commit |
| `.github/prompts/create.prompt.md` | Criar nova feature |
| `.github/prompts/project_plan.prompt.md` | Gerar plano de projeto |
| `.github/prompts/refactore.prompt.md` | Refatorar um módulo existente |
| `.github/prompts/init.prompt.md` | Inicializar contexto do projeto |
| `.github/prompts/setup-project-context.prompt.md` | Atualizar arquivos de contexto da IA |

---

## ⚡ Regras Globais

- **Arquitetura**: `presentation` → `domain` ← `data` (Clean Architecture)
- **Imports**: SEMPRE absolutos — `package:notes_app/...` — NUNCA relativos
- **State management**: Cubit (BLoC) — `flutter_bloc ^9.0.0`
- **Error handling**: `Result<T>` (Ok/Error) — NUNCA relance exceções
- **DI**: GetIt via `AppInjector` — Cubits → `registerFactory`; resto → `registerLazySingleton`
- **Navegação**: GoRouter — SEMPRE na View ou `BlocListener`, NUNCA no Cubit
- **Textos na UI**: SEMPRE `context.l10n.<chave>` — ZERO strings hardcoded (suporte: pt_BR, en_US, es_ES)
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

## Estrutura do Projeto

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
