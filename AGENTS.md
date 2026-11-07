# Payplan (`notes_app`)

App Flutter de controle financeiro pessoal (dívidas/cartões, devedores, orçamentos, gráficos e plano Plus sem anúncios) para iOS (target 13.0) e Android (minSdk 24 / targetSdk 35 / compileSdk 36). Versão 3.0.4+90. i18n: pt_BR, en_US, es_ES.

## Antes de implementar (obrigatório)

Invoque a skill `brainstorming` antes de criar/alterar features, telas, widgets ou de refatorar — regra em `.claude/rules/brainstorming.instructions.md`. Não comece a implementar sem isso.

## Stack

- Flutter 3 / Dart `^3.5.4`, Material 3 (light/dark), somente retrato
- Estado: **Cubit** (`flutter_bloc ^9.0.0`) — State em `part`, `sealed class` + `final class`
- Persistência: **`shared_preferences`** — entidades como `List<String>` de JSON. Não há banco.
- `fl_chart` (gráficos) · `google_mobile_ads` · `in_app_purchase` · `flutter_local_notifications` + `timezone`
- `dio` só para checar nova versão (`version-app.json` via GitHub raw)

## Estrutura

- `lib/main.dart` — init de `AdService`, `ThemeController`, timezones e `NotificationService`
- `lib/src/app_widget.dart` — `MaterialApp`, temas, locales; `home: HomeBase`
- `lib/src/features/<feature>/` — `cubit/`, `view/`, `widgets/`, `content/`
  - `home` (também é o shell: `home/view/home_base.dart`), `nova_divida`, `devedores`, `orcamento`, `novo_orcamento`, `grafico`, `plus`
- `lib/src/util/` — `entity/`, `model/`, `enum/`, `extension/`, `helpers/`, `service/`, `widgets/`, `colors/`, `strings/`
- `lib/i18n/` — `pt_BR.json`, `en_US.json`, `es_ES.json`
- `test/` — hoje só `test/util/entity/orcamento_entity_test.dart`
- `ios/fastlane/` — lanes `prod` (TestFlight) e `release` (App Store)

## Comandos

- `flutter pub get` — dependências
- `flutter analyze` — análise estática (rodar antes de finalizar)
- `flutter test` — testes automatizados
- `flutter build ipa` / `flutter build apk` — builds
- `cd ios && fastlane prod` — build IPA + upload para TestFlight

## Convenções

- **Imports absolutos** `package:notes_app/...` — nunca relativos.
- **Cubit instanciado na View** (`final _cubit = XCubit();`) e repassado por construtor. `HomeBase` cria e compartilha `HomeCubit`, `DevedoresCubit` e `OrcamentoCubit` entre as abas. Sem DI por container.
- **Cubit assíncrono:** emita `Loading` copiando os campos do estado atual → `SharedPreferences` → `Sucesso`/`Erro`. Veja `HomeCubit`/`OrcamentoCubit`.
- **Persistência no Cubit:** chaves `'dividas'`, `'devedores'`, `'orcamentos'` (`List<String>`), `'salario_fixo'`, `'isPlus'`, `'themeMode'`. Serialização via Models (`util/model/`: `fromJson`/`toJson`/`fromEntity`); devedores serializam na própria entity (`toMap`/`fromJson`).
- **Entities** (`util/entity/`): `@immutable`, `const`, `final`, `copyWith()`, `==`, `hashCode`.
- **Premium:** `UserController` (`ValueNotifier<UserEntity>` em `util/entity/user_entity.dart`), lido com `ValueListenableBuilder`; ads só aparecem com `!isPlus`. Tema idem via `ThemeController`.
- **Navegação na View:** `Navigator.push` + `MaterialPageRoute` para formulários; abas via `IndexedStack` + `NavigationBar` em `home_base.dart`.
- **Formulários** (`nova_divida`, `novo_orcamento`) não têm Cubit próprio — recebem o Cubit da feature pai.
- **Textos de UI** via `localization` (`'chave'.i18n()`), expostos em `util/strings/app_strings.dart`; adicione a chave nos três JSON de `lib/i18n/`.
- **SafeArea** no conteúdo principal das Views.
- **Sem `Widget _buildXxx()` na View** — extraia para `widgets/` (reutilizável) ou `content/` (auxiliar da tela); dialog/bottomSheet são exceção.

## Gotchas

- `get_it`, `dartz` e `as_design_system` estão no `pubspec.yaml` mas **não são usados** em `lib/`. Erros são tratados com `try/catch` + estados de erro do Cubit (`HomeCubit` e `OrcamentoCubit` não têm estado de erro).
- `lib/objectbox-model.json` é órfão (sem `objectbox` no pubspec) — não confie nele.
- A skill `flutter-expert` descreve Clean Architecture + GetIt + GoRouter; neste projeto, quando divergir, prevalecem as convenções deste arquivo.
- `.github/copilot-instructions.md` está desatualizado (versão e arquitetura antigas); a fonte de verdade é este `AGENTS.md`.

## Não fazer

- Não introduzir GetIt, GoRouter, `Result<T>`/`Either`, camadas `domain`/`data` ou banco (ObjectBox/SQLite) sem alinhar antes.
- Não usar strings hardcoded na UI.
- Não criar arquivos `.md` para documentar mudanças de código (exceto os flows em `docs/flow/`).
- Não rodar `flutter pub upgrade` sem perguntar.

## Skills

Consulte a skill da tarefa antes de começar: `implement-admob`, `implement-in-app-purchase`, `flutter-testing`, `flutter-setup-localization`, `custom-paint`, `flutter-animating-apps`, `flutter-adaptive-ui`, `flutter-isolates`, `flutter-expert` (com a ressalva acima). Lista completa em `.claude/skills/`.

## 📖 Documentação de Flows

`./docs/flow/` documenta como cada feature funciona de ponta a ponta — arquivos, ordem de chamada e regras de negócio. `project-structure.md` é a visão geral do projeto.

- **Antes de implementar ou debugar:** leia a linha `**Resumo:**` de cada `.md` em `./docs/flow/` e abra por inteiro os relevantes para a tarefa.
- **Depois de alterar uma feature documentada:** atualize o flow dela no mesmo trabalho — arquivos, passo a passo, regras e frontmatter (`verified_at`, `source_commit`, `source_state`). Mudança de stack, estrutura ou comandos atualiza `project-structure.md`.
- **Feature nova ou sem flow:** invoque a skill `flow` para documentá-la.

## 🧪 Teste funcional

Após implementar, não execute o projeto para validar o resultado (rodar o app, emulador/simulador, dispositivo físico, servidor local, screenshots ou interação simulada). Teste funcional/visual é responsabilidade do usuário.

- Limite a verificação a análise estática, build/compile e testes automatizados
- Ao concluir, liste objetivamente o que o usuário deve testar manualmente
- Não pergunte se deve executar o projeto — só faça isso se o usuário pedir explicitamente
