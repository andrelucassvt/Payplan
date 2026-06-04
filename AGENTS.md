# Payplan (`notes_app`)

App Flutter de controle financeiro pessoal (dívidas, devedores, orçamentos, gráficos e plano premium). iOS (target 13.0) e Android (minSdk 24 / targetSdk 35 / compileSdk 36). Versão 3.0.4+90. i18n: pt_BR, en_US, es_ES.

## Antes de implementar (obrigatório)

**SEMPRE** invoque a skill `brainstorming` antes de criar/alterar features, telas, widgets ou de refatorar — regra em `.claude/rules/brainstorming.instructions.md`. Não comece a implementar sem isso.

## Stack

- Flutter 3 / Dart `^3.5.4`, Material 3 (light/dark)
- State management: **Cubit** (`flutter_bloc ^9.0.0`) — Cubit + State (via `part`)
- Persistência: **`shared_preferences`** — entidades serializadas como `List<String>` JSON. **Não há banco** (sem ObjectBox/SQLite).
- Gráficos: `fl_chart` · Ads: `google_mobile_ads` · IAP: `in_app_purchase` · Notificações: `flutter_local_notifications`
- HTTP: `dio` (usado só para checagem de versão via GitHub raw)
- Design system interno: `as_design_system` (git, branch main)

## Estrutura

- `lib/main.dart` — entry point; inicializa `AdService`, `ThemeController`, timezones e `NotificationService`
- `lib/src/app_widget.dart` — `MaterialApp`, temas e locales; `home: HomeBase`
- `lib/src/features/<feature>/` — feature-first: `cubit/`, `view/`, `widgets/`, `content/`
  - features: `home` (também é o shell de navegação), `devedores`, `orcamento`, `grafico`, `nova_divida`, `novo_orcamento`, `plus`
- `lib/src/util/` — compartilhado: `entity/`, `model/`, `enum/`, `extension/`, `helpers/`, `service/`, `widgets/`, `colors/`, `strings/`
- `lib/i18n/` — `pt_BR.json`, `en_US.json`, `es_ES.json`

## Comandos

- `flutter pub get` — dependências
- `flutter run` — executar
- `flutter analyze` — lint/análise estática (rodar antes de finalizar)
- `flutter build ipa` / `flutter build apk` — builds

## Convenções (como o código realmente é)

- **Imports sempre absolutos**: `package:notes_app/...` — nunca relativos.
- **Cubit instanciado na View**: o `StatefulWidget` cria o Cubit (`final _cubit = XCubit();`) e o repassa por construtor aos filhos. **Não há GetIt/DI por container.**
- **Cubit assíncrono**: emita um estado `Loading` (copiando os campos do estado atual) → acesse `SharedPreferences` → emita `Sucesso`/`Erro`. Veja `HomeCubit`/`OrcamentoCubit`.
- **Persistência no próprio Cubit**: lê/grava `prefs.getStringList(...)`, mapeia via Models (`fromJson`/`toJson`/`fromEntity`). Chaves usadas: `'dividas'`, `'devedores'`, `'orcamentos'`, `'salario_fixo'`, `'isPlus'`.
- **Entities** (`util/entity/`): `@immutable`, `const`, `final`, `copyWith()`, `==`, `hashCode`. **Models** (`util/model/`) cuidam da serialização JSON.
- **Estado do usuário (premium)**: `UserController` (`ValueNotifier<UserEntity>` em `util/entity/user_entity.dart`) — leia com `ValueListenableBuilder`. Tema idem via `ThemeController`.
- **Navegação na View**: `Navigator.push` + `MaterialPageRoute` para telas de formulário; abas via `IndexedStack` + `NavigationBar` em `home/view/home_base.dart`. **Não há GoRouter.**
- **Textos da UI**: localizados via `localization` (JSON em `lib/i18n/`). Constantes em `util/strings/app_strings.dart`.
- **SafeArea** no conteúdo principal das Views.
- **Sem `Widget _buildXxx()` reutilizável dentro da View** — extraia para `widgets/` (reutilizável) ou `content/` (auxiliar da tela); dialog/bottomSheet são exceção.

## Gotchas

- **CLAUDE.md antigo descrevia uma arquitetura que não existe** (Clean Arch com `domain`/`data`, GetIt, GoRouter, `Result<T>`, ObjectBox). Ignore essa descrição: o código real é o descrito aqui e em `flow/project-structure.md`.
- `dartz` está no `pubspec.yaml` mas **não é usado** (sem `Either`/`Result`). Tratamento de erro é `try/catch` direto + estados de erro do Cubit.
- **Arquivo órfão**: `lib/objectbox-model.json` ainda existe, mas `objectbox` não está no `pubspec.yaml` e nada o usa — resquício de persistência removida (candidato a remoção, não confie nele).
- **Sem testes**: não existe diretório `test/` com testes implementados.
- `nova_divida` e `novo_orcamento` **não têm Cubit próprio** — reusam o Cubit da feature pai recebido por construtor.

## Não fazer

- Não introduzir GetIt, GoRouter, `Result<T>`/`Either` ou um banco (ObjectBox/SQLite) sem alinhar antes — destoa de todo o código atual.
- Não usar strings hardcoded na UI — use a localização (`lib/i18n/`).
- Não criar arquivos `.md` para documentar mudanças de código.
- Não rodar `flutter pub upgrade` sem perguntar.

## 🛠️ Skills

Leia a skill correspondente antes da tarefa: `flutter-expert` (guia geral de implementação), `implement-admob`, `implement-in-app-purchase`, `implement-firebase-notifications`, `implement-auth-token-flow`, `custom-paint`, `flutter-animating-apps`, `flutter-adaptive-ui`, `flutter-isolates`. (Lista completa em `.claude/skills/`.)

## 📖 Documentação de Flows

Para qualquer feature ou fluxo, verifique a pasta `./flow/`: leia os títulos dos arquivos `.md` disponíveis e, se algum for relevante para a tarefa atual, leia-o antes de implementar ou debugar. Use `/flow <nome>` para criar ou atualizar flows individuais.
