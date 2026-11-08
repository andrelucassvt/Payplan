# Payplan (`notes_app`)

App Flutter de controle financeiro pessoal — dívidas/cartões, devedores, orçamentos, gráficos e compra Plus (remove anúncios). iOS (deployment target 13.0) e Android (minSdk 24 · targetSdk 35 · compileSdk 36). Versão `3.0.4+90`. i18n: pt_BR, en_US, es_ES. Bundle iOS `com.andre.notesApp` · pacote Android `com.andre.notes_app`.

## Antes de implementar

- Leia a linha `**Resumo:**` de cada arquivo em `docs/flow/` e abra por inteiro os relevantes (ver seção Flows).
- Para features novas, telas ou mudanças de comportamento/dados: alinhe a proposta com o usuário antes de codar (`.claude/rules/brainstorming.instructions.md`).

## Stack

- Flutter 3 / Dart `^3.5.4`, Material 3 (light/dark, seed `0xFF5C5FEF`), somente retrato, `textScaler` fixo em 1.0
- Estado: **Cubit** (`flutter_bloc ^9.0.0`), State em `part` com `sealed class` + `final class`
- Persistência: **`shared_preferences`** — entidades como `List<String>` de JSON. Não há banco nem back-end.
- Textos: `localization` (`LocalJsonLocalization`, JSONs em `lib/i18n/`)
- `fl_chart` (pizza) · `google_mobile_ads` · `in_app_purchase` · `flutter_local_notifications` + `permission_handler`
- `screenshot` + `path_provider` + `share_plus` (compartilhar gráficos/cobranças) · `flutter_masked_text2` (valores)
- `dio` só para checar nova versão em `version-app.json` (GitHub raw, repo `andrelucassvt/Payplan`)

## Estrutura

```
lib/
├── main.dart                 # AdService().initialize → ThemeController.init → timezones + NotificationService → runApp
├── i18n/                     # pt_BR.json, en_US.json, es_ES.json
└── src/
    ├── app_widget.dart       # MaterialApp, temas, locales, home: HomeBase
    ├── features/
    │   ├── home/             # cubit/, view/ (home_base.dart = shell de abas, home_view.dart), widgets/
    │   ├── nova_divida/      # view/, content/  (formulário, usa HomeCubit)
    │   ├── devedores/        # cubit/, view/, view/widgets/
    │   ├── orcamento/        # cubit/, view/, widgets/
    │   ├── novo_orcamento/   # view/, content/  (formulário, usa OrcamentoCubit)
    │   ├── grafico/          # view/ apenas — sem Cubit, lê os estados dos outros
    │   └── plus/             # cubit/, view/, content/ (compra única "sem_anuncio")
    └── util/
        ├── entity/           # divida, devedores, orcamento, user (UserController)
        ├── model/            # divida_model, orcamento_model (fromJson/toJson/fromEntity)
        ├── enum/  extension/  colors/  strings/ (app_strings.dart)
        ├── helpers/          # devedores_helper.dart (showNovoDevedorModal)
        ├── service/          # ads/ (AdConfig, AdService, AppOpenAdService), in_app_purchase/,
        │                     # notification_service.dart, theme_controller.dart
        └── widgets/          # admob_banner_widget.dart (em uso) + widgets compartilhados
test/util/entity/orcamento_entity_test.dart   # único teste hoje
docs/flow/                                    # flows por feature + project-structure.md
ios/fastlane/  android/fastlane/              # deploy
```

## Comandos

- `flutter pub get` — dependências
- `flutter analyze` — análise estática (rodar antes de finalizar)
- `flutter test` — testes automatizados
- `flutter build ipa` / `flutter build appbundle` — builds de release
- `cd ios && fastlane prod` — build IPA + upload TestFlight · `fastlane release` — App Store
- `cd android && fastlane prod` — build AAB + upload Play Store (track `production`, status `draft`)

## Convenções

- **Imports absolutos** `package:notes_app/...` — nunca relativos.
- **Cubit instanciado na View** (`final _cubit = XCubit();`) e repassado por construtor; sem DI por container. `HomeBase` cria e compartilha `HomeCubit`, `DevedoresCubit` e `OrcamentoCubit` entre as abas. `PlusView` cria `PlusCubit(InAppPurchaseService())` e fecha no `dispose`.
- **Cubit assíncrono:** emita `Loading` copiando os campos do estado atual → `SharedPreferences` → `Sucesso`/`Erro`. Referência: `HomeCubit`/`OrcamentoCubit`.
- **Chaves do `SharedPreferences`:** `'dividas'`, `'devedores'`, `'orcamentos'` (`List<String>` de JSON), `'salario_fixo'` (double), `'isPlus'` (bool, via `UserController.setUser`), `'themeMode'` (via `ThemeController`).
- **Serialização:** dívidas e orçamentos via Models em `util/model/` (`fromJson`/`toJson`/`fromEntity`); devedores serializam na própria entity (`toMap`/`fromJson`).
- **Entities** (`util/entity/`): `@immutable`, construtor `const`, campos `final`, `copyWith()`, `==` e `hashCode`. (`UserEntity` ainda não segue o padrão.)
- **Premium:** `UserController.user` (`ValueNotifier<UserEntity>`) lido com `ValueListenableBuilder`; banners e App Open Ad só aparecem com `!isPlus`. Tema idem via `ThemeController.themeMode`.
- **Navegação:** `Navigator.push` + `MaterialPageRoute` para formulários; abas via `IndexedStack` + `NavigationBar` em `home_base.dart` (Home, Devedores, Orçamentos, Gráficos). Plus abre em `showModalBottomSheet` a partir do `home_total_widget.dart`.
- **Formulários** (`nova_divida`, `novo_orcamento`) não têm Cubit próprio — recebem o Cubit da feature pai.
- **Textos de UI** via `'chave'.i18n()`, expostos em `util/strings/app_strings.dart`; adicione a chave nos três JSON de `lib/i18n/`.
- **SafeArea** no conteúdo principal das Views.
- **Sem `Widget _buildXxx()` em Views novas** — extraia para `widgets/` (reutilizável) ou `content/` (auxiliar da tela); dialog/bottomSheet são exceção.

## Gotchas

- `get_it`, `dartz` e `as_design_system` estão no `pubspec.yaml` mas **não são usados** em `lib/`.
- `HomeCubit` e `OrcamentoCubit` não têm estado de erro; `DevedoresCubit` tem `DevedoresError`.
- `timezone` é importado em `main.dart` mas vem transitivo de `flutter_local_notifications` (não está no `pubspec.yaml`).
- Código sem uso em `lib/`: `util/service/open_app_admob.dart` (`AppOpenAdManager`, substituído por `AppOpenAdService`), `admob_adaptive_banner.dart`, `admob_native_banner.dart`, `glass_container_widget.dart`, `app_dialog.dart`, `util/colors/app_colors.dart`. Não use como referência sem confirmar.
- `lib/objectbox-model.json` é órfão (sem `objectbox` no pubspec) — não confie nele.
- IDs do AdMob em `AdConfig` são de produção; não há IDs de teste.
- `HomeBase` ainda tem `_buildFab` e strings hardcoded (`'Home'`, `'Captura de tela falhou.'`) — legado, não replique.
- A skill `flutter-expert` descreve Clean Architecture + GetIt + GoRouter; quando divergir, prevalecem as convenções deste arquivo.
- `.github/copilot-instructions.md` está desatualizado (versão 2.5.5 e arquitetura antiga); a fonte de verdade é este `AGENTS.md`.
- `sync-instructions.sh` sincroniza skills de um repositório central (`.claude/skills`, `.github/skills`, `.agents/skills`) e não sobrescreve `AGENTS.md`/`CLAUDE.md` existentes.

## Não fazer

- Não introduzir GetIt, GoRouter, `Result<T>`/`Either`, camadas `domain`/`data` ou banco (ObjectBox/SQLite) sem alinhar antes.
- Não usar strings hardcoded na UI.
- Não criar arquivos `.md` para documentar mudanças de código (exceto os flows em `docs/flow/`).
- Não rodar `flutter pub upgrade` sem perguntar.
- Não commitar/expor credenciais de `ios/fastlane/` e `android/fastlane/` (`*.p8`, `api_key.json`, `key.json`).

## Skills

Consulte a skill da tarefa antes de começar (em `.claude/skills/`): `implement-admob`, `implement-in-app-purchase`, `flutter-testing`, `flutter-setup-localization`, `custom-paint`, `flutter-animating-apps`, `flutter-adaptive-ui`, `flutter-isolates`, `flutter-expert` (com a ressalva acima), `flow`, `flow-init`. `implement-auth-token-flow` e `implement-firebase-notifications` não se aplicam hoje (sem back-end nem Firebase).

## 📖 Documentação de Flows

`docs/flow/` documenta cada feature de ponta a ponta — arquivos, ordem de chamada e regras de negócio: `home.md`, `nova-divida.md`, `devedores.md`, `orcamento.md`, `grafico.md`, `plus.md`, `ads.md` e `project-structure.md` (visão geral).

- **Antes de implementar ou debugar:** leia a linha `**Resumo:**` de cada `.md` e abra por inteiro os relevantes.
- **Depois de alterar uma feature documentada:** atualize o flow dela no mesmo trabalho — arquivos, passo a passo, regras e frontmatter (`verified_at`, `source_commit`, `source_state`). Mudança de stack, estrutura ou comandos atualiza `project-structure.md`.
- **Feature nova ou sem flow:** invoque a skill `flow` para documentá-la.

## 🧪 Teste funcional

Após implementar, não execute o projeto para validar o resultado (rodar o app, emulador/simulador, dispositivo físico, screenshots ou interação simulada). Teste funcional/visual é responsabilidade do usuário.

- Limite a verificação a análise estática, build/compile e testes automatizados.
- Ao concluir, liste objetivamente o que o usuário deve testar manualmente.
- Não pergunte se deve executar o projeto — só faça isso se o usuário pedir explicitamente.
