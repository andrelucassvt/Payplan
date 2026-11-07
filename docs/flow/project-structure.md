---
generated_at: 2026-11-07
source_commit: 93ab5b5
source_state: dirty
verified_at: 2026-11-07
status: current
---

# Estrutura do Projeto: Payplan (`notes_app`)

> **Resumo:** App Flutter de controle financeiro pessoal (dívidas/cartões, devedores, orçamentos, gráficos e plano Plus sem anúncios), feature-first com Cubit instanciado na View e persistência 100% local em `SharedPreferences` (JSON), sem camada domain/data nem DI por container.

## Stack e Tecnologias

| Elemento | Valor |
|----------|-------|
| Linguagem | Dart `^3.5.4` |
| Framework | Flutter 3, Material 3 (light/dark, seed `0xFF5C5FEF`) |
| Gerenciador de pacotes | pub |
| Versão do app | `3.0.4+90` (`pubspec.yaml`) |
| Plataformas | iOS (deployment target 13.0) e Android (minSdk 24 / targetSdk 35 / compileSdk 36) |
| Orientação | Somente retrato (`SystemChrome.setPreferredOrientations` em `app_widget.dart`) |
| i18n | pt_BR, en_US, es_ES via `localization` (`LocalJsonLocalization`, JSON em `lib/i18n/`) |
| Principais dependências | `flutter_bloc`, `shared_preferences`, `fl_chart`, `google_mobile_ads`, `in_app_purchase`, `flutter_local_notifications`, `dio` |

## Arquitetura

Organização **feature-first**: cada funcionalidade vive em `lib/src/features/<feature>/` (`cubit/`, `view/`, `widgets/`, `content/`) e o código compartilhado em `lib/src/util/`. Estado via **Cubit** (`flutter_bloc`), com `State` declarado em `part` e hierarquia `sealed class` + `final class` (ex.: `OrcamentoInitial`/`OrcamentoLoading`/`OrcamentoSucesso`).

As Views são `StatefulWidget` que **instanciam o próprio Cubit** (`final _cubit = XCubit();`) e o repassam por construtor. `HomeBase` cria `HomeCubit`, `DevedoresCubit` e `OrcamentoCubit` e os compartilha entre as abas; `PlusView` cria o `PlusCubit`. Os Cubits leem/gravam `SharedPreferences` diretamente, serializando via Models (`fromJson`/`toJson`/`fromEntity`) ou via `toMap`/`fromJson` na própria entity (caso de devedores). Estado global: `UserController` (premium) e `ThemeController` (tema), ambos `ValueNotifier` estáticos.

```
main.dart → AppWidget (MaterialApp) → HomeBase (IndexedStack + NavigationBar)
                                          │
              View (StatefulWidget) ──instancia──▶ Cubit ──▶ SharedPreferences (JSON)
                    │ BlocBuilder                     │
                    ▼                                 ▼
               widgets/ · content/          Entity ⇄ Model (util/)
```

### Regras de dependência

- Sem camadas `domain`/`data`: Entities e Models ficam em `lib/src/util/` e são importados diretamente pelos Cubits.
- Imports sempre absolutos (`package:notes_app/...`) — nenhum import relativo em `lib/`.
- Navegação fica na View (`Navigator.push` + `MaterialPageRoute`), nunca no Cubit.
- Formulários (`nova_divida`, `novo_orcamento`) não têm Cubit próprio: recebem o Cubit da feature pai.

## Features

| Feature | Caminho principal | Descrição resumida |
|---------|------------------|-------------------|
| Home | `lib/src/features/home/` | Shell de navegação (`view/home_base.dart`) + aba de dívidas/cartões do mês: troca de mês/ano, salário fixo, totais, verificação de nova versão |
| Nova Dívida | `lib/src/features/nova_divida/` | Formulário de criação/edição de dívida/cartão; usa o `HomeCubit` recebido |
| Devedores | `lib/src/features/devedores/` | CRUD de pessoas que devem ao usuário, parcelas pagas, cobrança compartilhada e lembretes por notificação local |
| Orçamento | `lib/src/features/orcamento/` | CRUD de orçamentos com sub-itens, conclusão e total geral |
| Novo Orçamento | `lib/src/features/novo_orcamento/` | Formulário de criação/edição de orçamento; usa o `OrcamentoCubit` recebido |
| Gráficos | `lib/src/features/grafico/` | Gráficos `fl_chart` de dívidas, devedores e orçamentos; captura e compartilhamento via FAB |
| Plus | `lib/src/features/plus/` | Paywall do Plus: compra única não consumível (`sem_anuncio`) via `in_app_purchase` que remove anúncios; aberto por `showModalBottomSheet` |

> Abas do `IndexedStack` em `home_base.dart`: 0 Home, 1 Devedores, 2 Orçamento, 3 Gráficos. O FAB muda por aba (nova dívida, novo devedor via `showNovoDevedorModal`, novo orçamento, compartilhar gráficos). `PlusView` é aberta via `showModalBottomSheet` em `home/widgets/home_total_widget.dart`.

## Camadas / Módulos Compartilhados

| Tipo | Caminho | Responsabilidade |
|------|---------|-----------------|
| Entities | `lib/src/util/entity/` | `divida_entity.dart` (`DividaEntity`, `FaturaMensalEntity`, `SubDividaEntity`), `devedores_entity.dart` (`DevedoresEntity`, `ParcelaDevedorEntity`, com `toMap`/`fromJson` próprios), `orcamento_entity.dart` (`OrcamentoEntity`, `SubItemOrcamentoEntity`, getter `totalOrcamento`), `user_entity.dart` (`UserEntity` + `UserController`) |
| Models | `lib/src/util/model/` | `divida_model.dart`, `orcamento_model.dart` — serialização JSON (`fromJson`/`toJson`/`fromEntity`) |
| Enums | `lib/src/util/enum/` | `meses_enum.dart` |
| Extensions | `lib/src/util/extension/` | `real_format_extension.dart` (formatação monetária) |
| Helpers | `lib/src/util/helpers/` | `devedores_helper.dart` (`showNovoDevedorModal`) |
| Services | `lib/src/util/service/` | AdMob (`ads/`), compras (`in_app_purchase/`), `notification_service.dart`, `theme_controller.dart`, `open_app_admob.dart` |
| Widgets globais | `lib/src/util/widgets/` | Banners AdMob (adaptive, banner, native), `app_dialog.dart`, `glass_container_widget.dart` |
| Cores | `lib/src/util/colors/` | `app_colors.dart` |
| Strings | `lib/src/util/strings/` | `app_strings.dart` — `AppStrings` com getters `'chave'.i18n()` |
| i18n | `lib/i18n/` | `pt_BR.json`, `en_US.json`, `es_ES.json` (declarados como asset no `pubspec.yaml`) |
| Testes | `test/util/entity/` | `orcamento_entity_test.dart` — único teste (getter `totalOrcamento`) |

## Configuração

| Componente | Arquivo | Responsabilidade |
|-----------|---------|-----------------|
| Bootstrap | `lib/main.dart` | `await AdService().initialize()`, `await ThemeController.init()`, depois `_setupConfigs()` (timezones + `NotificationService().setup()`, sem `await`) e `runApp(AppWidget())` |
| Widget raiz | `lib/src/app_widget.dart` | `MaterialApp` com temas M3, `supportedLocales`, `LocalJsonLocalization.delegate`, `textScaler` fixo em 1.0, `home: HomeBase` |
| Navegação | `lib/src/features/home/view/home_base.dart` | `NavigationBar` + `IndexedStack`; recarrega dados ao trocar de aba; FAB contextual |
| Persistência | Cubits de cada feature | Chaves `SharedPreferences`: `'dividas'`, `'devedores'`, `'orcamentos'` (`List<String>` JSON), `'salario_fixo'` (double), `'isPlus'` (bool), `'themeMode'` (string) |
| Estado do usuário | `lib/src/util/entity/user_entity.dart` | `UserController` (`ValueNotifier<UserEntity>`) — status premium, persiste `'isPlus'` |
| Tema | `lib/src/util/service/theme_controller.dart` | `ThemeController` (`ValueNotifier<ThemeMode>`) persistido em `'themeMode'` |
| AdMob | `lib/src/util/service/ads/` | `ad_config.dart` (IDs), `ad_service.dart` (init SDK), `app_open_ad_service.dart` (App Open Ad) |
| Compras | `lib/src/util/service/in_app_purchase/in_app_purchase_service.dart` | Produtos, stream de compras e restauração |
| Notificações | `lib/src/util/service/notification_service.dart` | Setup, notificações locais agendadas e checagem de permissão |
| Versão remota | `lib/src/features/home/cubit/home_cubit.dart` + `version-app.json` | `dio` lê `version-app.json` do GitHub raw e compara com `package_info_plus` |
| Release iOS | `ios/fastlane/Fastfile` | Lanes `prod` (`flutter build ipa --release` + TestFlight) e `release` (App Store) |
| Lint | `analysis_options.yaml` | `package:flutter_lints/flutter.yaml`; exclui `build/`, `android/`, `ios/` |

> **Error handling:** sem `Result`/`Either`. Cubits usam `try/catch` pontual e estados de erro específicos (`PlusPurchaseError`, `PlusStoreUnavailable`). `DevedoresError` é declarado mas nunca emitido; `HomeCubit` e `OrcamentoCubit` não têm estado de erro.

## Dependências Externas Principais

| Pacote | Versão | Uso no projeto |
|--------|--------|---------------|
| flutter_bloc | ^9.0.0 | Cubits de todas as features |
| shared_preferences | ^2.3.3 | Persistência local de todas as entidades e preferências |
| fl_chart | ^1.1.1 | Gráficos da aba Gráficos |
| google_mobile_ads | ^6.0.0 | Banners, native ads e App Open Ad (ocultos para Plus) |
| in_app_purchase | ^3.2.3 | Compra não consumível do Plus (`buyNonConsumable`) |
| flutter_local_notifications | ^18.0.1 | Lembretes locais (com `timezone`, transitivo) |
| permission_handler | ^12.0.1 | Permissão de notificação / abrir ajustes |
| dio + package_info_plus + url_launcher | ^5.9.0 / ^9.0.0 / ^6.3.1 | Checagem de nova versão e abertura de links da loja/termos |
| screenshot + share_plus + path_provider | ^3.0.0 / ^12.0.0 / ^2.0.15 | Captura dos gráficos e compartilhamento |
| flutter_masked_text2 | ^0.9.1 | `MoneyMaskedTextController` nos formulários |
| uuid | ^4.1.0 | IDs de entidades |
| localization / flutter_localization / intl | ^2.1.0 / ^0.3.1 / ^0.20.2 | i18n JSON e formatação |

## Observações

- **Dependências declaradas e não usadas em `lib/`:** `get_it`, `dartz` e `as_design_system` (git) estão no `pubspec.yaml`, mas nenhum arquivo os importa. `path` também não é importado. `build_runner` está em dev_dependencies sem geradores no projeto.
- **Arquivo órfão:** `lib/objectbox-model.json` permanece, mas `objectbox` não está no `pubspec.yaml` e nada o lê — resquício de persistência removida.
- **Testes:** existe `test/`, mas com um único arquivo (`test/util/entity/orcamento_entity_test.dart`); Cubits, Models e Views não têm cobertura.
- **Strings hardcoded pontuais** apesar da regra de i18n: `'Home'` (label da aba) e `'Captura de tela falhou.'` em `home_base.dart`, além de textos em `devedores/view/widgets/card_devedores_widget.dart`.
- **`Widget _buildFab()`** em `home_base.dart` é o único `_buildXxx` restante em View.
- **Credenciais versionadas:** `ios/fastlane/AB483SC484.p8` e `ios/fastlane/api_key.json` estão rastreados pelo Git, embora `api_key.json` conste no `.gitignore`.
- **Instruções legadas fora do `AGENTS.md`:** `.github/copilot-instructions.md` ainda descreve versão 2.5.5+70 e aponta para `architecture.instructions.md` (inexistente). `sync-instructions.sh` sincroniza skills/instruções de repositórios externos para `.claude/`, `.agents/` e `.github/`.
