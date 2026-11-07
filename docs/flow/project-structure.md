# Estrutura do Projeto: Payplan

> **Resumo:** App Flutter de controle financeiro pessoal (dívidas, devedores, orçamentos, gráficos e plano premium). Stack Flutter/Dart com gerenciamento de estado via Cubit (BLoC) e persistência 100% local em `SharedPreferences`. Pacote interno: `notes_app`.

## Stack e Tecnologias

| Elemento | Valor |
|----------|-------|
| Linguagem | Dart `^3.5.4` |
| Framework | Flutter 3 (Material 3) |
| Gerenciador de pacotes | pub |
| Versão do app | 3.0.4+90 |
| Plataformas | iOS (target 13.0) e Android (minSdk 24 / targetSdk 35 / compileSdk 36) |
| Principais dependências | `flutter_bloc`, `shared_preferences`, `fl_chart`, `google_mobile_ads`, `in_app_purchase`, `flutter_local_notifications`, `dio` |

## Arquitetura

O projeto é organizado em **feature-first**: cada funcionalidade tem sua própria pasta dentro de `lib/src/features/`, e o código compartilhado fica em `lib/src/util/`. O gerenciamento de estado usa **Cubit** (`flutter_bloc`): cada feature com lógica tem um `Cubit` + um arquivo `State` (declarado via `part`). As Views são `StatefulWidget` que **instanciam o próprio Cubit** e o repassam para os widgets filhos por construtor.

Não há camada de domínio/data formal nem injeção de dependência por container. Os Cubits acessam a persistência **diretamente** via `SharedPreferences`, serializando entidades para JSON através dos *Models* (`fromJson`/`toJson`/`fromEntity`). O estado global do usuário (plano premium) é mantido por um `ValueNotifier` estático (`UserController`).

```
View (StatefulWidget) → Cubit → SharedPreferences (JSON)
        ↓ BlocBuilder
     Widgets
```

### Regras de dependência

- Não há regra de camadas imposta (sem `domain`/`data` separados). Entidades e Models convivem em `lib/src/util/`.
- Imports são absolutos (`package:notes_app/...`).
- Navegação fica na View, nunca no Cubit (via `Navigator.push` + `MaterialPageRoute`).

## Features

| Feature | Caminho principal | Descrição resumida |
|---------|------------------|-------------------|
| Home | `lib/src/features/home/` | Tela principal — lista dívidas/contas do mês, salário fixo, troca de mês/ano, verificação de versão e shell de navegação (`home_base.dart`) |
| Devedores | `lib/src/features/devedores/` | CRUD de pessoas que devem ao usuário, controle de parcelas pagas e compartilhamento de cobrança |
| Orçamento | `lib/src/features/orcamento/` | CRUD de orçamentos com sub-itens, marcação de concluído e total geral |
| Gráfico | `lib/src/features/grafico/` | Visualização gráfica (fl_chart) de dívidas, devedores e orçamentos + screenshot/compartilhamento |
| Nova Dívida | `lib/src/features/nova_divida/` | Formulário de cadastro de dívida (sem Cubit próprio — usa o `HomeCubit` recebido) |
| Novo Orçamento | `lib/src/features/novo_orcamento/` | Formulário de cadastro de orçamento (usa o `OrcamentoCubit` recebido) |
| Plus | `lib/src/features/plus/` | Paywall / plano premium via `in_app_purchase` (loja, restauração e estado de assinatura) |

> A barra de navegação (`NavigationBar`) e o `IndexedStack` que reúnem Home, Devedores, Orçamento e Gráfico vivem em `home/view/home_base.dart`, que também é o widget raiz exibido pelo `AppWidget`.

## Camadas / Módulos Compartilhados

| Tipo | Caminho | Responsabilidade |
|------|---------|-----------------|
| Entities | `lib/src/util/entity/` | `divida_entity.dart`, `devedores_entity.dart`, `orcamento_entity.dart`, `user_entity.dart` (este também contém o `UserController`) — classes `@immutable` com `copyWith`/`==`/`hashCode` |
| Models | `lib/src/util/model/` | `divida_model.dart`, `orcamento_model.dart` — serialização JSON (`fromJson`/`toJson`/`fromEntity`) |
| Enums | `lib/src/util/enum/` | `meses_enum.dart` |
| Extensions | `lib/src/util/extension/` | `real_format_extension.dart` (formatação monetária) |
| Helpers | `lib/src/util/helpers/` | `devedores_helper.dart` (ex.: modal de novo devedor) |
| Services | `lib/src/util/service/` | Anúncios, notificações, compras in-app e tema (ver tabela de Configuração) |
| Widgets globais | `lib/src/util/widgets/` | Banners AdMob, `app_dialog.dart`, `glass_container_widget.dart` |
| Cores | `lib/src/util/colors/` | `app_colors.dart` |
| Strings | `lib/src/util/strings/` | `app_strings.dart` (constantes de texto) |
| i18n | `lib/i18n/` | `pt_BR.json`, `en_US.json`, `es_ES.json` (via `localization` / `LocalJsonLocalization`) |

## Configuração

| Componente | Arquivo | Responsabilidade |
|-----------|---------|-----------------|
| Entry point | `lib/main.dart` | Inicializa `AdService`, `ThemeController`, timezones e `NotificationService`; roda `AppWidget` |
| Widget raiz | `lib/src/app_widget.dart` | `MaterialApp`, temas light/dark (Material 3), locales suportados e `home: HomeBase` |
| Navegação | `lib/src/features/home/view/home_base.dart` | `NavigationBar` + `IndexedStack` (abas) e `Navigator.push`/`MaterialPageRoute` para telas de formulário |
| Estado do usuário | `lib/src/util/entity/user_entity.dart` | `UserController` (`ValueNotifier<UserEntity>`) para o status premium |
| Tema | `lib/src/util/service/theme_controller.dart` | `ThemeController` (`ValueNotifier<ThemeMode>`) persistido e observado no `AppWidget` |
| AdMob | `lib/src/util/service/ads/ad_config.dart`, `ad_service.dart`, `app_open_ad_service.dart` | IDs de unidades de anúncio, init do SDK e App Open Ad |
| Compras | `lib/src/util/service/in_app_purchase/in_app_purchase_service.dart` | Loja, stream de compras, restauração |
| Notificações | `lib/src/util/service/notification_service.dart` | Setup e permissão de notificações locais |

> **Error handling:** não há padrão `Result`/`Either` em uso. Os Cubits usam `try/catch` direto (alguns com `rethrow`) e emitem estados de erro específicos (ex.: `PlusPurchaseError`). A maioria das operações de `SharedPreferences` ocorre sem `try/catch`.

## Dependências Externas Principais

| Pacote / Biblioteca | Versão | Uso no projeto |
|--------------------|--------|---------------|
| flutter_bloc | ^9.0.0 | Gerenciamento de estado (Cubit) |
| shared_preferences | ^2.3.3 | Persistência local de todas as entidades (JSON) |
| fl_chart | ^1.1.1 | Gráficos financeiros |
| google_mobile_ads | ^6.0.0 | Banners, native ads e App Open Ad |
| in_app_purchase | ^3.2.3 | Plano premium / paywall |
| flutter_local_notifications | ^18.0.1 | Notificações locais (com `timezone`) |
| dio | ^5.9.0 | Verificação de nova versão (GitHub raw JSON) |
| localization / flutter_localization | ^2.1.0 / ^0.3.1 | i18n via JSON (pt_BR, en_US, es_ES) |
| screenshot + share_plus | ^3.0.0 / ^12.0.0 | Captura e compartilhamento das telas/gráficos |
| flutter_masked_text2 | ^0.9.1 | Máscara monetária em formulários |
| as_design_system | git (main) | Design system interno |

## Observações

- **Divergência entre `CLAUDE.md` e o código real (junho/2026):** o `CLAUDE.md` anterior descrevia Clean Architecture com `domain`/`data`, GetIt (`AppInjector`), GoRouter, `Result<T>` e ObjectBox. **Nada disso existe no código atual.** A persistência é `SharedPreferences`, não há DI por container (Cubits instanciados direto nas Views), a navegação é `Navigator.push` e o pacote `objectbox` não está no `pubspec.yaml`. Este documento reflete o código real.
- `dartz` está listado no `pubspec.yaml`, mas não foi encontrado uso de `Either`/`Result` nas features (dependência efetivamente morta).
- **Sem testes:** não há diretório `test/` com testes implementados.
- Os formulários (`nova_divida`, `novo_orcamento`) não têm Cubit próprio — reaproveitam o Cubit da feature pai recebido por construtor.
- **Arquivo órfão:** `lib/objectbox-model.json` (datado de jan/2025) ainda existe no repositório, mas o pacote `objectbox` **não está** no `pubspec.yaml` e nenhum código o usa — resquício de uma persistência ObjectBox removida. Candidato a remoção.
- O `CLAUDE.md` antigo mandava ler `.claude/rules/architecture.instructions.md`, mas **esse arquivo não existe** — só há `brainstorming.instructions.md`. O `CLAUDE.md` reescrito já corrige esse ponteiro morto.
