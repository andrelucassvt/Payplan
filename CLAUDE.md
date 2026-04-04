# Payplan — Claude Code Instructions

## Sobre Este Projeto

App Flutter de controle financeiro pessoal: gestão de dívidas, devedores, gráficos e plano premium.
Flutter 3 / Dart ^3.5.4 · Versão 2.5.5+70 · Pacote: `notes_app`
Plataformas: **iOS** (target 13.0) e **Android** (minSdk 24, targetSdk 35, compileSdk 36).
Sem flavors — único `main.dart`. Localização: pt_BR, en_US, es_ES.

---

## Regra Obrigatória de Leitura

**Antes de gerar ou modificar qualquer código**, leia SEMPRE o arquivo `.claude/rules/architecture.instructions.md` — ele contém as regras gerais de arquitetura que se aplicam a todo o projeto.

Depois, **conforme o contexto da tarefa**, leia a skill correspondente à camada que será modificada (veja tabela de Skills abaixo).

---

## 📂 Arquivos de Instrução

| Arquivo | Quando ler |
|---|---|
| `.claude/rules/architecture.instructions.md` | **Sempre** — regras gerais de arquitetura |

---

## 🛠️ Skills Especializadas

Skills são capacidades especializadas. Leia o arquivo da skill **antes** de executar a tarefa correspondente:

| Skill | Arquivo | Quando usar |
|---|---|---|
| `implement-view` | `.claude/skills/implement-view/SKILL.md` | Ao criar ou modificar Views (StatefulWidget + Cubit + BlocBuilder) ou adicionar nova tela |
| `implement-view-model` | `.claude/skills/implement-view-model/SKILL.md` | Ao criar ou modificar Cubits/States, adicionar método async, gerenciar estados de loading/error |
| `implement-widget` | `.claude/skills/implement-widget/SKILL.md` | Ao criar ou modificar widgets em `features/**/widgets/` ou `util/widgets/` |
| `implement-domain` | `.claude/skills/implement-domain/SKILL.md` | Ao criar entidades, interfaces de repositório ou modelar conceitos de negócio |
| `implement-data` | `.claude/skills/implement-data/SKILL.md` | Ao implementar chamadas de API, serialização JSON, DataSources ou RepositoryImpl |
| `configure-di` | `.claude/skills/configure-di/SKILL.md` | Ao registrar ou modificar dependências com GetIt |
| `configure-navigation` | `.claude/skills/configure-navigation/SKILL.md` | Ao adicionar rotas, navegação entre telas ou deep links |
| `implement-in-app-purchase` | `.claude/skills/implement-in-app-purchase/SKILL.md` | Ao implementar compras in-app, assinaturas ou paywall (`in_app_purchase ^3.2.3`) |
| `implement-admob` | `.claude/skills/implement-admob/SKILL.md` | Ao implementar ou modificar anúncios AdMob (`google_mobile_ads ^6.0.0`) |
| `custom-paint` | `.claude/skills/custom-paint/SKILL.md` | Ao desenhar formas, gráficos ou animações 2D com CustomPaint/CustomPainter |
| `guideline-apple` | `.claude/skills/guideline-apple/SKILL.md` | Ao revisar, preparar ou auditar o app para submissão na App Store |
| `implement-auth-token-flow` | `.claude/skills/implement-auth-token-flow/SKILL.md` | Ao implementar autenticação com Bearer token, login, refresh token ou logout |
| `implement-firebase-notifications` | `.claude/skills/implement-firebase-notifications/SKILL.md` | Ao implementar ou auditar push notifications via Firebase Cloud Messaging (iOS + Android) |
| `flutter-isolates` | `.claude/skills/flutter-isolates/SKILL.md` | Ao trabalhar com paralelismo, concorrência, performance de UI ou tarefas CPU-intensivas |
| `flutter-animating-apps` | `.claude/skills/flutter-animating-apps/SKILL.md` | Ao implementar animações, transições, hero animations ou efeitos visuais |
| `skill-creator` | `.claude/skills/skill-creator/SKILL.md` | Ao criar, modificar ou otimizar arquivos de skill |

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

## ⚡ Regras Globais (resumo)

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
4. Siga a estrutura de pastas descrita em `.claude/rules/architecture.instructions.md`

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

## Comandos Úteis

```bash
flutter pub get           # Instalar dependências
flutter run               # Executar o app
flutter build apk         # Build Android APK
flutter build ipa         # Build iOS IPA
flutter analyze           # Lint e análise estática
flutter test              # Executar testes
```

## Dependências Externas

| Categoria | Pacote | Versão |
|---|---|---|
| State Management | flutter_bloc | ^9.0.0 |
| DI | get_it | ^8.0.2 |
| Network | dio | ^5.9.0 |
| Functional | dartz | ^0.10.1 |
| Storage | shared_preferences | ^2.3.3 |
| Storage | path_provider | ^2.0.15 |
| i18n | flutter_localization | ^0.3.1 |
| i18n | localization | ^2.1.0 |
| i18n | intl | ^0.20.2 |
| Ads | google_mobile_ads | ^6.0.0 |
| Notifications | flutter_local_notifications | ^18.0.1 |
| IAP | in_app_purchase | ^3.2.3 |
| Charts | fl_chart | ^1.1.1 |
| Design System | as_design_system | git (main) |
| UI | flutter_masked_text2, cupertino_icons | vários |
| Utilities | uuid, path, share_plus, screenshot, package_info_plus, url_launcher, permission_handler | vários |
