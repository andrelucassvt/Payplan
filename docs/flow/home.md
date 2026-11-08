---
generated_at: 2026-11-07
source_commit: 2978aa2
source_state: dirty
verified_at: 2026-11-08
status: current
---

# Flow: Home (shell de navegação + aba de dívidas do mês)

> **Resumo:** Shell `HomeBase` (4 abas, FAB contextual, snackbar de permissão de notificação, pré-carga do AppOpenAd) e aba Home de dívidas/cartões filtrada por mês/ano: total não pago do mês vs. salário fixo (`'salario_fixo'`), marcar fatura do mês como paga, editar valor da fatura, sub-dívidas, entrada para editar/deletar dívida e para o `PlusView`, além do aviso de nova versão via GitHub raw.

## Visão Geral

O app abre em `HomeBase` (`home: HomeBase` em `app_widget.dart`). O `initState` do shell instancia os três Cubits das abas (`HomeCubit`, `DevedoresCubit`, `OrcamentoCubit`), dispara as cargas iniciais, a verificação de versão remota, o status do premium (`'isPlus'`), checa a permissão de notificação (só exibe snackbar, não pede) e, após o primeiro frame, pré-carrega um `AppOpenAd`. A navegação é um `IndexedStack` com `NavigationBar` (0 Home, 1 Devedores, 2 Orçamento, 3 Gráficos); trocar de aba recarrega os dados das abas 1, 2 e 3, nunca a 0.

A aba Home (`HomeView`) escuta o `HomeCubit` com `BlocConsumer`. O cabeçalho `HomeTotalWidget` mostra ano (picker Cupertino), mês (`PopupMenuButton`), botão "sem anúncio" (abre `PlusView` para não-Plus), botão de salário, toggle de tema e o **total não pago do mês**. Com salário fixo > 0 aparece o **saldo restante** (salário − total). A lista renderiza um `HomeCardDivida` por dívida, com banners AdMob após o 1º e 2º card para não-Plus.

Todo o estado da tela é mês/ano-dependente: `HomeCubit` guarda `mesAtual`/`anoAtual`, e cada card calcula a fatura do período em runtime. Trocar mês/ano emite `HomeMudarMesAtual` e recarrega tudo de `SharedPreferences` (`'dividas'`), recalculando `totalGastos`. As ações do card (switch pago, editar fatura, sub-dívidas) montam uma nova `DividaEntity` e chamam `HomeCubit.atualizarDivida`, que regrava a lista inteira e chama `buscarDividas()`.

Criação, edição de nome/cor e exclusão de dívida acontecem em `NovaDividaView` (flow próprio), que recebe o mesmo `HomeCubit` por construtor. Em paralelo, `verificarVersao()` baixa `version-app.json` do GitHub e, se a versão remota for maior, emite `HomeVersaoNova`, que abre um `AlertDialog` não dispensável com link para a loja.

## Passo a Passo

### Inicialização do shell

1. **Shell** — `lib/src/features/home/view/home_base.dart` → `_HomeBaseState` (l. 31–57)
   Cria `_homeCubit`, `_devedoresCubit`, `_orcamentoCubit`, 4 `ScrollController` (um por aba) e 3 `ScreenshotController` (gráficos). No `initState`, em ordem: `buscarDividas()`, `buscarIsPlus()`, `verificarVersao()`, `buscarDevedores()`, `buscarOrcamentos()`, `_verificarPermissaoNotificacao()` e, em `addPostFrameCallback`, `AppOpenAdService.instance.load()`. Nenhuma dessas chamadas é aguardada.
2. **Estado inicial** — `lib/src/features/home/cubit/home_cubit.dart` → construtor `HomeCubit` (l. 15–27)
   `HomeInitial` com `mesAtual` = `MesesEnum` do mês corrente, `anoAtual` = ano corrente, `dividas: []`, `totalGastos: 0`, `salarioFixo: 0`, `isDividas: true`.
3. **Carga de dívidas** — `home_cubit.dart` → `buscarDividas()` (l. 149–183)
   Emite `HomeDividasLoading` (copiando campos), lê `prefs.getStringList('dividas')`, desserializa com `DividaModel.fromJson`, soma `divida.totalNaoPagoDoMes(anoAtual, mesAtual.id)` em `totalGastos`, lê `prefs.getDouble('salario_fixo')` e emite `HomeDividasSucesso`.
4. **Premium** — `home_cubit.dart` → `buscarIsPlus()` (l. 226–232)
   Lê `prefs.getBool('isPlus')` e chama `UserController.setUser(UserEntity(isPlus: ...))` (`lib/src/util/entity/user_entity.dart`), que atualiza o `ValueNotifier` e regrava `'isPlus'`. Banners, botão "sem anúncio" e AppOpenAd no card reagem via `ValueListenableBuilder`.
5. **Versão remota** — `home_cubit.dart` → `verificarVersao()` (l. 35–69)
   `PackageInfo.fromPlatform()` + `Dio().get(...)` em `https://raw.githubusercontent.com/andrelucassvt/Payplan/refs/heads/main/version-app.json`. Faz `jsonDecode(response.data)`, remove os pontos das duas versões, converte para `int` e, se remota > local, emite `HomeVersaoNova` (mesmos campos do estado atual).
   - `HomeView` (`home_view.dart` l. 58–86, `listener` do `BlocConsumer`) abre `AlertDialog` com `barrierDismissible: false`; o botão `'atualizar'.i18n()` chama `launchUrlString` (Play Store `com.andre.notes_app` no Android, App Store `id6450763738` no iOS) e fecha o dialog.
6. **Permissão de notificação** — `home_base.dart` → `_verificarPermissaoNotificacao()` (l. 59–78)
   Chama `NotificationService().verificarPermissaoNotificacao()` (`lib/src/util/service/notification_service.dart` l. 72–76), que retorna `true` quando a permissão está `denied` ou `permanentlyDenied`. Nesse caso mostra um `SnackBar` (cores do tema) com `AppStrings.permitirNotificacoes`; tocar no texto chama `openAppSettings()`. O pedido de permissão em si acontece antes, em `NotificationService.setup()` chamado no `main.dart`.
7. **AppOpenAd** — `lib/src/util/service/ads/app_open_ad_service.dart` → `load()`
   Carrega um `AppOpenAd` (`AdConfig.appOpen`) e o guarda em `_appOpenAd`. Ele só é exibido depois, no card (passo 17).

### Navegação e FAB

8. **Troca de aba** — `home_base.dart` → `NavigationBar.onDestinationSelected` (l. 132–141)
   Índice 1 → `buscarDevedores()`; 2 → `buscarOrcamentos()`; 3 → recarrega devedores, dívidas e orçamentos; depois `setState(_selectedIndex)`. A aba 3 (`GraficosView`) é montada dentro de três `BlocBuilder` aninhados e recebe `state.dividas`, devedores, orçamentos e o `homeCubit`.
9. **FAB contextual** — `home_base.dart` → `_buildFab()` (l. 168–205)
   - Aba 0: `Navigator.push` → `NovaDividaView(homeCubit: _homeCubit)` (ver flow de nova dívida).
   - Aba 1: `showNovoDevedorModal(...)` de `lib/src/util/helpers/devedores_helper.dart`.
   - Aba 2: `Navigator.push` → `NovoOrcamentoView(orcamentoCubit: _orcamentoCubit)`.
   - Aba 3: ícone de share → `_shareScreenshots()` (l. 207–248): captura só as seções que têm dados (`_homeCubit.temDividas()`, `temDevedores()`, `temOrcamentos()`), grava `image.png`/`image2.png`/`image3.png` em `getApplicationDocumentsDirectory()` e chama `Share.shareXFiles(..., text: AppStrings.baixePayplan)`. Exceção → `SnackBar` com `AppStrings.capturaFalhou`.

### Aba Home: cabeçalho, mês/ano e salário

10. **View** — `lib/src/features/home/view/home_view.dart` → `_HomeViewState.build()` (l. 64–176)
    `SafeArea(bottom: false)` com um `Stack`: a lista ocupa a área inteira (`Positioned.fill`) e o `HomeTotalWidget` fica sobreposto no topo, com fundo `scaffoldBackgroundColor`. A lista reserva no `padding.top` a altura do cabeçalho **expandido** (`_alturaCabecalho`, reportada por `onAlturaExpandidaChanged`), então encolher o cabeçalho não muda a altura do viewport nem o `maxScrollExtent`, o que evita o scroll "pular" e o cabeçalho reexpandir sozinho. Um listener no `scrollController` (`_onScroll`, l. 48–55) colapsa com `offset > 60` e só expande de novo com `offset < 20` (histerese). Com `state.dividas` vazia mostra `_EmptyState` (l. 179–211); senão um `ListView.builder` cujo item 0 é o rótulo `AppStrings.dividas` e os demais são `HomeCardDivida`, intercalando `AdmobBannerWidget(AdConfig.homeBanner1)` após a 1ª dívida e `homeBanner2` após a 2ª quando `!user.isPlus`.
11. **Cabeçalho** — `lib/src/features/home/widgets/home_total_widget.dart` → `_HomeTotalWidgetState` / `_TopRow` (l. 377–459) / `_PeriodoSelector` (l. 461–496)
    - **Ano:** `_showYearPicker()` abre `CupertinoPicker` com anos 2024–2123; cada `onSelectedItemChanged` chama `cubit.mudarAnoAtual(2024 + index)`.
    - **Mês:** `PopupMenuButton<MesesEnum>` (l. 415) → `cubit.mudarMesAtual(e)`.
    - **Sem anúncio:** visível só se `!user.isPlus`; abre `showModalBottomSheet` com `const PlusView()` (l. 398–408), limitado a 80% da altura.
    - **Tema:** `ThemeController.toggle(context)`.
    - **Total:** `state.totalGastos.real` (extensão em `lib/src/util/extension/real_format_extension.dart`), com animação de fonte/alinhamento ao colapsar (`didUpdateWidget`). Sempre que a animação está em repouso expandida (`_controller.isDismissed`), mede a própria altura num post-frame e chama `onAlturaExpandidaChanged` se ela mudou (`_reportarAlturaExpandida`).
12. **Troca de período** — `home_cubit.dart` → `mudarMesAtual()` (l. 198–210) / `mudarAnoAtual()` (l. 212–224)
    Emite `HomeMudarMesAtual` com o novo mês/ano e chama `buscarDividas()`, que recalcula `totalGastos` para o novo período. Os cards leem `homeCubit.state` diretamente e recalculam a fatura do período no rebuild.
13. **Salário fixo** — `home_total_widget.dart` → `_showModalDesconto(state.totalGastos)` (l. 229–333)
    Bottom sheet (drag handle nativo do M3) com `MoneyMaskedTextController` iniciado em `salarioFixo` e prévia ao vivo (salário, `- totalDividas`, saldo; negativo em `colorScheme.error`). "Salvar salário" → `HomeCubit.salvarSalario(valorDigitado)`; "Remover salário" (só se `salarioFixo > 0`) → `salvarSalario(0.0)`.
    - `home_cubit.dart` → `salvarSalario()` (l. 271–284): `prefs.setDouble('salario_fixo', valor)` e emite `HomeDividasSucesso` com o novo `salarioFixo` (sem recarregar dívidas).

### Aba Home: card de dívida

14. **Fatura do período** — `lib/src/features/home/widgets/home_card_divida.dart` → getter `faturaAtual` (l. 33–58)
    Busca em `dividaEntity.faturas` a fatura com `ano == anoAtual && mes == mesAtual.id`.
    - Parcelada (`mensal == false`) sem fatura no mês → `null` → o card some (`SizedBox.shrink()`, l. 89).
    - Mensal sem fatura no mês → devolve uma `FaturaMensalEntity` sintética (`valor: 0`, `pago: false`) que **não** está na lista.
    - Encontrada → guarda `valorFatura` e retorna a fatura.
    `_numeroParcela` (l. 60–73) ordena as faturas por ano/mês e mostra "parcela N de total" (`AppStrings.parcelaNumero`) para parceladas.
15. **Valor exibido** — `home_card_divida.dart` → `build()` (l. 88–287)
    Card com fundo sólido na cor da dívida (sem gradiente nem sombra). A cor do texto, dos botões e do switch é escolhida por contraste (`ThemeData.estimateBrightnessForColor`): branco em cores escuras, `black87` em cores claras. `totalDoMes = faturaAtual.valor + dividaEntity.totalSubDividasDoMes(ano, mes)`, formatado com `.real`; se paga, o valor fica riscado e o rótulo de status mostra `AppStrings.paga`. As sub-dívidas do mês (`SubDividaEntity.aplicavelNoMes`) aparecem como `_SubDividaRow`, com `AppStrings.verMais(n)` / `verMenos` acima de 3.
16. **Marcar como paga** — `home_card_divida.dart` → `Switch.onChanged` (l. 188–202)
    Mapeia `faturas` trocando a do período por `faturaAtual.copyWith(pago: value)` e chama `homeCubit.atualizarDivida(dividaEntity.copyWith(faturas: updated))`.
17. **Editar fatura** — `home_card_divida.dart` → `_editarFaturaBottomSheet(user.isPlus)` (l. 506–599)
    Se `!isPlus`, chama `AppOpenAdService.instance.show()` antes de abrir o sheet. O `TextFormField` atualiza `valorModificado` no `onChanged` (l. 535–541). Em "Salvar": substitui a fatura do período na lista ou, se ela não existir (caso mensal sintético), **anexa** `faturaAtual.copyWith(valor: valorModificado)`; depois `atualizarDivida(...)` e fecha o sheet.
18. **Sub-dívidas** — `home_card_divida.dart` → `_gerenciarSubDividasBottomSheet()` (l. 290–445) e `_editarSubDividaDialog()` (l. 447–504)
    Lista as sub-dívidas com editar/excluir e um formulário de adicionar (nome, valor, `SwitchListTile` "recorrente"). Não-recorrente grava `mes`/`ano` do período atual; recorrente grava `null` e passa a valer em todos os meses. Chamadas: `HomeCubit.adicionarSubDivida` (l. 421, `id: Uuid().v4()`), `removerSubDivida` (l. 367), `atualizarSubDivida` (l. 491). As três (`home_cubit.dart` l. 234–269) só montam a nova lista via `copyWith(subDividas: ...)` e delegam para `atualizarDivida`.
19. **Editar/deletar dívida** — `home_card_divida.dart` → `IconButton` `edit_outlined` na barra de ações (l. 264–279)
    `Navigator.push` → `NovaDividaView(homeCubit, dividaEntity)`. Nessa tela, salvar chama `HomeCubit.atualizarDivida` (só nome e cor) e o botão "Deletar" do AppBar chama `HomeCubit.removerDivida(...).whenComplete(pop)` (`lib/src/features/nova_divida/view/nova_divida_view.dart` l. 90–96 e 143–150).

### Persistência das mutações

20. **Cubit** — `home_cubit.dart` → `atualizarDivida()` (l. 97–126) / `removerDivida()` (l. 71–95) / `salvarDivida()` (l. 128–147)
    Emitem `HomeDividasLoading`, releem `'dividas'`, substituem por `id` (`DividaModel.fromEntity`), removem por `id` ou anexam, regravam com `prefs.setStringList` (sem `await`) e chamam `buscarDividas()`, que emite o `HomeDividasSucesso` final com `totalGastos` recalculado.
21. **Model** — `lib/src/util/model/divida_model.dart` → `DividaModel.fromJson` / `toJson`
    Chaves `id`, `nome`, `mensal`, `cor` (int ARGB), `faturas` (`ano`, `mes`, `pago` com default `false`, `valor` como `num`) e `sub-dividas` (com hífen, opcional na leitura).

### Caminhos alternativos

- **Sem dívidas cadastradas:** `HomeView` mostra `_EmptyState` com `AppStrings.nenhumaDivida` / `adicioneUmaDivida`.
- **Versão remota não é maior:** nenhum estado é emitido; nada acontece na UI.
- **Falha na checagem de versão (offline, JSON inválido):** o `catch` de `verificarVersao()` faz `rethrow`; como o `initState` não aguarda o `Future`, o erro vira exceção assíncrona não tratada (sem impacto na UI).
- **AppOpenAd não carregado:** `AppOpenAdService.show()` só loga `'ad not ready'` e o sheet de editar fatura abre normalmente.
- **Permissão de notificação concedida:** nenhum snackbar.
- **Validação de sub-dívida:** nome vazio ou valor `0.0` → `onPressed` retorna sem salvar (adicionar e editar).
- **Falha no share dos gráficos:** `SnackBar` com `AppStrings.capturaFalhou` em `_shareScreenshots`.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Apresentação (shell) | `lib/src/features/home/view/home_base.dart` | Instancia os 3 Cubits, cargas iniciais, `IndexedStack` + `NavigationBar`, FAB por aba, snackbar de permissão, `AppOpenAd.load`, share dos gráficos |
| Apresentação | `lib/src/features/home/view/home_view.dart` | Aba Home: `BlocConsumer` (dialog de nova versão), cabeçalho colapsável, lista de cards, banners, empty state |
| Apresentação | `lib/src/features/home/widgets/home_total_widget.dart` | Total do mês, saldo vs. salário, sheet de salário, seletores de mês/ano, toggle de tema, entrada para `PlusView` |
| Apresentação | `lib/src/features/home/widgets/home_card_divida.dart` | Fatura do período, switch pago, editar fatura (+ AppOpenAd), sub-dívidas, navegação para edição |
| Estado | `lib/src/features/home/cubit/home_cubit.dart` | Leitura/escrita de `'dividas'`, `'salario_fixo'`, `'isPlus'`; cálculo de `totalGastos`; troca de período; versão remota |
| Estado | `lib/src/features/home/cubit/home_state.dart` | `sealed class HomeState` + `HomeInitial`, `HomeDividasLoading`, `HomeDividasSucesso`, `HomeMudarMesAtual`, `HomeVersaoNova`, `HomeMudarListagem` |
| Domínio | `lib/src/util/entity/divida_entity.dart` | `DividaEntity.totalNaoPagoDoMes`, `totalSubDividasDoMes`, `faturaDoMes`; `SubDividaEntity.aplicavelNoMes` |
| Domínio | `lib/src/util/entity/user_entity.dart` | `UserController` (`ValueNotifier<UserEntity>`) que persiste `'isPlus'` |
| Dados | `lib/src/util/model/divida_model.dart` | Serialização JSON de dívida, faturas e sub-dívidas |
| Serviços | `lib/src/util/service/ads/app_open_ad_service.dart` | Singleton que carrega (shell) e exibe (card) o AppOpenAd |
| Serviços | `lib/src/util/service/notification_service.dart` | `verificarPermissaoNotificacao()` usado pelo shell |
| Navegação para | `lib/src/features/nova_divida/view/nova_divida_view.dart` | Criar/editar/deletar dívida usando o `HomeCubit` recebido (flow próprio) |
| Navegação para | `lib/src/features/plus/view/plus_view.dart` | Paywall aberto em bottom sheet pelo cabeçalho |
| Configuração | `version-app.json` (raiz do repo) | Versão publicada lida pelo app via GitHub raw (hoje `"3.0.0"`) |

## Regras de Negócio Relevantes

- **Total do mês = só o que não foi pago** — `divida_entity.dart` → `totalNaoPagoDoMes`: fatura paga conta 0 (inclusive suas sub-dívidas); parcelada sem fatura no mês conta 0; mensal sem fatura conta só as sub-dívidas aplicáveis. O card, por outro lado, mostra fatura + sub-dívidas mesmo se paga (valor riscado).
- **Saldo restante só com salário configurado** — `home_total_widget.dart`: linha "saldo restante" aparece apenas com `salarioFixo > 0`; valor em `colorScheme.error` quando `salário − total < 0`, cor de texto normal caso contrário. Salvar `0.0` equivale a remover o salário.
- **Dívida parcelada só aparece nos meses com parcela** — `home_card_divida.dart` → `faturaAtual`; dívida mensal aparece em todos os meses.
- **Sub-dívida recorrente vale para todos os meses; a não recorrente só para o mês/ano em que foi criada** — `divida_entity.dart` → `SubDividaEntity.aplicavelNoMes`; gravação em `home_card_divida.dart` l. 421–431.
- **Monetização na Home** — `home_view.dart` / `home_card_divida.dart` / `home_total_widget.dart`: usuários não-Plus veem 2 banners (após o 1º e o 2º card), um AppOpenAd ao abrir "Editar fatura" e o botão "sem anúncio" que abre o `PlusView`; para Plus, tudo isso some.
- **Atualização obrigatória "soft"** — `home_cubit.dart` + `home_view.dart`: versão remota maior abre dialog não dispensável por toque fora, mas o botão só abre a loja e fecha o dialog; o app continua utilizável.
- **Seletor de ano limitado a 2024–2123** — `home_total_widget.dart` → `_showYearPicker`.

## Dependências Externas

- `shared_preferences` — chaves `'dividas'`, `'salario_fixo'`, `'isPlus'`.
- `dio` + `package_info_plus` — checagem de versão em `raw.githubusercontent.com/andrelucassvt/Payplan/.../version-app.json`.
- `url_launcher` (`launchUrlString`) — links da Play Store / App Store.
- `google_mobile_ads` — `AppOpenAd` (`AdConfig.appOpen`) e banners (`AdConfig.homeBanner1`/`homeBanner2`).
- `permission_handler` — status da permissão de notificação e `openAppSettings()`.
- `screenshot`, `path_provider`, `share_plus` — share da aba Gráficos pelo FAB do shell.

## Observações

- **Excluir a última dívida não limpa a lista em memória:** `buscarDividas()` emite `dividas: dividas.isEmpty ? state.dividas : dividas` (`home_cubit.dart` l. 178). Com a lista persistida vazia, o card excluído continua na tela (e no `GraficosView`) até reiniciar o app, embora `totalGastos` vá a 0.
- **Switch "paga" não funciona em dívida mensal sem fatura no mês:** a fatura sintética de `faturaAtual` não está em `faturas`, e o `onChanged` (l. 188–202) só mapeia a lista existente, sem anexar. Nada muda até o usuário usar "Editar fatura", que anexa a fatura.
- **"Editar fatura" salva 0 se o campo não for tocado:** `valorModificado` começa em `0` (l. 510) e só muda no `onChanged`, então "Salvar" sem digitar zera o valor da fatura.
- **AppOpenAd é carregado uma única vez por sessão:** `load()` só é chamado no `initState` do shell e `show()` zera `_appOpenAd`, então só o primeiro "Editar fatura" de cada sessão mostra anúncio. O ad também é carregado para usuários Plus (só o `show` é condicionado).
- **Comparação de versão frágil:** remover os pontos e comparar como inteiro dá resultado errado entre versões com dígitos diferentes (ex.: `3.0.10` → 3010 > `3.1.0` → 310). `jsonDecode(response.data)` também depende de o GitHub raw responder `text/plain`; se o Dio receber JSON já decodificado, a chamada lança exceção.
- **`faturaAtual` chama `setState()` dentro do getter** (l. 54–55), usado várias vezes durante o `build()`: efeito colateral no build.
- **Escritas sem `await`:** `prefs.setStringList(...)` em `salvar/atualizar/removerDivida` não é aguardado antes de `buscarDividas()`. Funciona porque o `SharedPreferences` atualiza o cache em memória de forma síncrona.
- **Código morto:** `mudarListagem()`, o campo `isDividas` e `HomeMudarListagem` não têm uso fora do Cubit. `mudarListagem()` ainda emite `HomeMudarMesAtual` em vez de `HomeMudarListagem`.
- **Troca para a aba 0 não recarrega dívidas** (só as abas 1–3 recarregam em `onDestinationSelected`).
- **Visual da Home usa só o `ColorScheme`/`TextTheme` do tema:** sem cores fixas, sombras ou gradientes nos widgets da feature; a única cor por item é o fundo sólido do card (`dividaEntity.cor`), com texto em contraste automático. Valores monetários usam `.real` (prefixo `$`, `NumberFormat` `pt_BR` fixo).
- **Testes:** nenhum teste cobre este fluxo. O único teste do projeto é `test/util/entity/orcamento_entity_test.dart`.
