---
generated_at: 2026-11-07
source_commit: 93ab5b5
source_state: dirty
verified_at: 2026-11-07
status: current
---

# Flow: Devedores

> **Resumo:** Na aba "Devedores" o usuário cadastra quem lhe deve (valor único ou parcelado em até 48x, com chave PIX e mensagem), marca parcelas como pagas, cobra pelo share sheet (`share_plus`), copia o PIX e agenda um lembrete local por devedor (`flutter_local_notifications` + `timezone`). Tudo é persistido na chave `'devedores'` do `SharedPreferences` e o total exibido é a soma do `valorPendente`.

## Visão Geral

`HomeBase` cria um único `DevedoresCubit` e o repassa para a `DevedoresView` (aba 1 do `IndexedStack`) e para a `GraficosView` (aba 3). A lista é carregada por `buscarDevedores()` em três momentos: no `initState` do `HomeBase`, no `initState` da `DevedoresView` (como o `IndexedStack` constrói todas as abas, as duas chamadas acontecem na inicialização) e sempre que o usuário seleciona as abas 1 ou 3 na `NavigationBar`.

O cadastro e a edição acontecem num bottom sheet montado por `showNovoDevedorModal()` em `lib/src/util/helpers/devedores_helper.dart`. Há três gatilhos: o FAB do `HomeBase` (aba 1), o botão "Novo devedor" do card de total ou do estado vazio da `DevedoresView` e o chip "Editar" de cada card, que passa a entidade existente. Na criação, o switch "Parcelar" gera N `ParcelaDevedorEntity` com o mesmo valor. Na edição, o switch fica oculto e, se o devedor já tem parcelas, o campo de valor fica somente leitura.

Cada operação do Cubit (`adicionar`, `editar`, `deletar`, `toggleParcelaPaga`) faz sempre o mesmo ciclo: emite `DevedoresLoading`, relê a lista inteira do `SharedPreferences`, aplica a mudança em memória, regrava a lista completa e chama `buscarDevedores()`. Esse método recalcula `totalValorDevedor` e emite `DevedoresSucesso`. Não existe Model para devedores: a serialização (`toMap`/`fromJson`) fica na própria `DevedoresEntity`.

O `CardDevedoresWidget` concentra os efeitos colaterais da tela. O chip "Cobrar" monta um texto com nome, valor pendente, PIX e mensagem e chama `Share.share`. Tocar no PIX copia a chave para o clipboard. O sino checa a permissão de notificação, abre o date/time picker, grava `notificar` via `editarDevedor` e agenda um `zonedSchedule` com `NotificationService.showLocalNotification`. Para usuários não-Plus (`UserController.user.isPlus == false`), um `AdmobBannerWidget` aparece logo abaixo do primeiro card da lista.

## Passo a Passo

### Carregamento da lista

1. **Shell** — `lib/src/features/home/view/home_base.dart` → `_HomeBaseState.initState()` (l. 46–57)
   Instancia `_devedoresCubit = DevedoresCubit()` (l. 33) e chama `buscarDevedores()` (l. 51). Também chama `_verificarPermissaoNotificacao()` (l. 58), que mostra um SnackBar azul com um link para `openAppSettings` quando a permissão está negada.
2. **View** — `lib/src/features/devedores/view/devedores_view.dart` → `_DevedoresViewState.initState()` (l. 35–38)
   Chama `buscarDevedores()` de novo. Ao trocar de aba, `onDestinationSelected` (home_base l. 147–155) refaz a busca para `index == 1` e `index == 3`.
3. **Cubit** — `lib/src/features/devedores/cubit/devedores_cubit.dart` → `buscarDevedores()` (l. 22–49)
   Emite `DevedoresLoading` com os dados atuais, lê `prefs.getStringList('devedores') ?? []`, aplica `json.decode` e `DevedoresEntity.fromJson` em cada item e soma `valorPendente` em `totalValorDevedor`. Por fim emite `DevedoresSucesso`.
4. **Entity** — `lib/src/util/entity/devedores_entity.dart` → `DevedoresEntity.fromJson()` (l. 96–112)
   Converte `notificar` de `millisecondsSinceEpoch` (int) para `DateTime`. Quando `parcelas` falta no JSON (registros antigos), usa `const []`. Cada parcela vira `ParcelaDevedorEntity.fromJson()` (l. 35–41), com `pago` default `false`.
5. **UI** — `devedores_view.dart` → `BlocBuilder<DevedoresCubit, DevedoresState>` (l. 71–204)
   Mostra `state.totalValorDevedor.real` no card de total. Com a lista vazia, mostra `_EmptyState`. Senão, monta um `ListView.builder` em que cada item fica dentro de um `ValueListenableBuilder(UserController.user)` e renderiza um `CardDevedoresWidget(index: index + 1, ...)`. Abaixo do primeiro item entra `AdmobBannerWidget(adUnitId: AdConfig.devedoresBanner)` quando `!user.isPlus` (l. 190–193).

### Criar devedor

1. **Gatilho** — o FAB em `home_base.dart` → `_buildFab()` (l. 210–218, ramo `else` com `_selectedIndex == 1`) ou o botão do card de total ou do `_EmptyState` em `devedores_view.dart` → `_openNovoDevedorModal()` (l. 40–50).
   Os dois chamam `showNovoDevedorModal(...)` sem `devedoresEntity`. Atenção: o `HomeBase` e a `DevedoresView` têm **cada um seu próprio conjunto** de `TextEditingController` (home_base l. 87–90 e view l. 29–32). O valor usa `MoneyMaskedTextController`.
2. **Helper (bottom sheet)** — `lib/src/util/helpers/devedores_helper.dart` → `showNovoDevedorModal()` (l. 10–337)
   Preenche os controllers (l. 29–32) e abre um `showModalBottomSheet` com `StatefulBuilder`. O `onChanged` do valor (l. 102–109) remove os `.`, troca `,` por `.` e aplica `double.tryParse` em `valorModificado`. Com "Parcelar" ligado (l. 112–250), aparecem o `PopupMenuButton` de 1 a 48x (l. 203–211) e a prévia do total `valorModificado * qtdParcelas`. Nesse modo o rótulo do campo vira `AppStrings.valorParcela`.
3. **Salvar** — `devedores_helper.dart` (l. 260–308)
   O botão fica desabilitado enquanto `nomeTextController.text.isEmpty`.
   - **Parcelado** (l. 278–295): gera `List.generate(qtdParcelas, ParcelaDevedorEntity(numero: i + 1, valor: valorModificado))` e chama `cubit.adicionarDevedor(...)` com `id: Uuid().v4()` e `valor: valorModificado * qtdParcelas`.
   - **À vista** (l. 296–305): chama `cubit.adicionarDevedor(...)` sem parcelas.
   - Em seguida faz `Navigator.pop(context)`. O `whenComplete` (l. 334–336) limpa só o `nomeTextController`.
4. **Cubit** — `devedores_cubit.dart` → `adicionarDevedor()` (l. 51–82)
   Emite Loading, relê a lista, faz `add`, aplica `json.encode(e.toMap())` em todos os itens, chama `prefs.setStringList('devedores', ...)` (sem `await`) e depois `buscarDevedores()`.

### Editar devedor

1. **Gatilho** — `lib/src/features/devedores/view/widgets/card_devedores_widget.dart` → chip "Editar" (l. 276–281) → `widget.editarDevedor`, que a view liga a `_openNovoDevedorModal(state.devedores[index])` (devedores_view l. 185–188).
2. **Helper** — `showNovoDevedorModal(devedoresEntity: ...)`
   Com `isEditing = true`, o switch "Parcelar" some. Se `hasExistingParcelas`, o campo de valor fica `readOnly` (l. 101). Ao salvar (l. 264–277), monta uma nova `DevedoresEntity` com o mesmo `id`, `nome`, `pix` e `message`, e copia `notificar` e `parcelas` da original. O `valor` só muda se não houver parcelas.
3. **Cubit** — `devedores_cubit.dart` → `editarDevedor()` (l. 84–122)
   Relê a lista, troca o item de mesmo `id` com `map`, regrava e chama `buscarDevedores()`.

### Deletar devedor

1. **Card** — `card_devedores_widget.dart` → chip "Deletar" (l. 283–288) → `devedoresCubit.deletarDevedor(entity.id)`. Não há diálogo de confirmação.
2. **Cubit** — `devedores_cubit.dart` → `deletarDevedor()` (l. 124–157)
   Faz `removeWhere(id)`, regrava e chama `buscarDevedores()`. Nenhuma notificação agendada é cancelada.

### Marcar parcela como paga

1. **Card** — `card_devedores_widget.dart` (l. 195–258)
   Lista as parcelas com `_ParcelaRow` (l. 371–430), um `Switch` por parcela. Por padrão mostra só as 3 primeiras; `AppStrings.verMais(n)`/`AppStrings.verMenos` alterna o estado local `_expandedParcelas`.
2. **Cubit** — `devedores_cubit.dart` → `toggleParcelaPaga(devedorId, numeroParcela, pago)` (l. 159–192)
   Localiza o devedor pelo `id` e a parcela pelo `numero`, aplica `copyWith(pago:)` na parcela e `copyWith(parcelas:)` no devedor, regrava e chama `buscarDevedores()`. O total da tela cai porque `valorPendente` ignora as parcelas pagas.
3. **UI derivada** — `card_devedores_widget.dart` (l. 77–103)
   O valor exibido é `entity.valorPendente`. Quando todas as parcelas estão pagas, valor e rótulo ficam verdes (`0xFF10B981`) e o rótulo mostra `AppStrings.quitado`. Nos outros casos o rótulo mostra `"x/N quitadas"`.

### Cobrar (compartilhar) e copiar PIX

1. **Cobrar** — `card_devedores_widget.dart` → chip `AppStrings.cobrar` (l. 264–274)
   Chama `Share.share(...)` com `AppStrings.dividasPendentes`, o nome, `"${AppStrings.valor}: ${valorPendente.real}"`, `"Chave PIX: ..."` (só se `pix != null`) e a `message` (ou `''`).
2. **Copiar PIX** — `card_devedores_widget.dart` (l. 126–171)
   Aparece só se `pix != null`. Chama `Clipboard.setData` e mostra o SnackBar verde "PIX copiado!".

### Agendar lembrete (notificação)

1. **Card** — `card_devedores_widget.dart` → `_handleNotificacao()` (l. 296–366), disparado pelo ícone de sino (l. 107–122). O sino fica preenchido e com a cor de destaque quando `notificar != null`.
2. **Permissão** — `lib/src/util/service/notification_service.dart` → `verificarPermissaoNotificacao()` (l. 72–76)
   Retorna `!(isPermanentlyDenied == isDenied)`, que na prática é `true` para negado ou negado permanentemente. Nesse caso o card mostra um SnackBar com `AppStrings.permitirNotificacoes` cujo toque chama `openAppSettings` (`permission_handler`), e o fluxo termina sem pedir a permissão de novo.
3. **Pickers** — `showDatePicker` (de `DateTime.now()` até `DateTime(3101)`) seguido de `showTimePicker` em modo input. Cancelar qualquer um dos dois aborta o fluxo.
4. **Persistência + agendamento** — `card_devedores_widget.dart` (l. 345–354)
   Chama `devedoresCubit.editarDevedor(entity.copyWith(notificar: scheduledDate))` e depois `NotificationService().showLocalNotification(title: AppStrings.dividasPendentes, body: AppStrings.mensagemDivida(nome, entity.valor.real), id: widget.index, scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local))`.
5. **Serviço** — `notification_service.dart` → `showLocalNotification()` (l. 31–70)
   Reinicializa o plugin (`_initializeNotifications`, ícone `@mipmap/launcher_icon`) e consulta `pendingNotificationRequests()`. Como o `id` do card nunca é 0, chama `zonedSchedule(id, ...)` com o canal Android `'0'/'general'`, `AndroidScheduleMode.inexact` e `absoluteTime`. O `zonedSchedule` não leva `await`.
6. **Bootstrap** — `lib/main.dart` → `_setupConfigs()` (l. 16–19)
   Roda `tz.initializeTimeZones()` e `NotificationService().setup()`, que pede `Permission.notification` na primeira execução. `_setupConfigs()` é chamado sem `await` antes do `runApp`.

### Caminhos alternativos

- **Permissão de notificação negada:** o SnackBar com o atalho para os ajustes aparece no `_handleNotificacao` do card (l. 300–320) e na abertura do app (`_verificarPermissaoNotificacao` do `HomeBase`, l. 58–84). Nada é agendado nem gravado.
- **Picker cancelado:** `pickedDate == null` ou `pickedTime == null` → `return` sem efeito (card l. 328 e 335).
- **Exceção ao agendar:** o `try/catch` (card l. 345–365) mostra o SnackBar vermelho "Erro ao agendar notificação". As duas chamadas dentro dele não levam `await`, então o `catch` só pega erros síncronos.
- **Nome vazio:** o botão Salvar do bottom sheet fica desabilitado (`onPressed: null`, helper l. 261).
- **Lista vazia:** a `DevedoresView` mostra `_EmptyState` com um CTA de "Novo devedor" (view l. 169–170, 212–271).

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Shell / Navegação | `lib/src/features/home/view/home_base.dart` | Cria o `DevedoresCubit`, dispara `buscarDevedores()` (init e abas 1/3), abre o modal pelo FAB na aba 1, alerta sobre a permissão de notificação e repassa `devedores` à `GraficosView` |
| Apresentação | `lib/src/features/devedores/view/devedores_view.dart` | Card de total, lista/estado vazio, banner AdMob condicionado a `isPlus` e controllers do modal disparado pela própria tela |
| Apresentação | `lib/src/features/devedores/view/widgets/card_devedores_widget.dart` | Card do devedor: valor pendente, parcelas com switch, cobrança via `Share.share`, cópia do PIX, agendamento de lembrete, editar e deletar |
| Apresentação (modal) | `lib/src/util/helpers/devedores_helper.dart` | `showNovoDevedorModal()`: formulário de criar/editar, parcelamento de 1 a 48x e montagem da `DevedoresEntity` |
| Estado | `lib/src/features/devedores/cubit/devedores_cubit.dart` | CRUD + `toggleParcelaPaga` com leitura e escrita direta em `SharedPreferences['devedores']`, cálculo de `totalValorDevedor` e `temDevedores()` (usado no screenshot dos gráficos) |
| Estado | `lib/src/features/devedores/cubit/devedores_state.dart` | `sealed DevedoresState` (`Initial`/`Loading`/`Sucesso`/`Error`) com `devedores` e `totalValorDevedor` |
| Entidade + serialização | `lib/src/util/entity/devedores_entity.dart` | `DevedoresEntity` (com `valorPendente`, `toMap`, `fromJson`, `copyWith`) e `ParcelaDevedorEntity`. Não há Model em `util/model/` |
| Serviço | `lib/src/util/service/notification_service.dart` | Setup e pedido de permissão, checagem de negação e `zonedSchedule` da notificação local |
| Configuração | `lib/main.dart` | `tz.initializeTimeZones()` e `NotificationService().setup()` no bootstrap |
| Configuração | `lib/src/util/service/ads/ad_config.dart` | `AdConfig.devedoresBanner` (ad unit IDs Android/iOS) |
| Estado global | `lib/src/util/entity/user_entity.dart` | `UserController.user` (`ValueNotifier<UserEntity>`) com o `isPlus` que esconde o banner |
| Consumidor | `lib/src/features/grafico/view/grafico_view.dart` | Usa `valorPendente` para o total e para a pizza de devedores (só os com `valorPendente > 0`) |
| Testes | — | Nenhum teste cobre devedores. O único teste do projeto é `test/util/entity/orcamento_entity_test.dart` |

## Regras de Negócio Relevantes

- **Valor pendente define o total** — `devedores_entity.dart` → `valorPendente` (l. 77–82): sem parcelas vale `valor`; com parcelas é a soma das parcelas não pagas. Esse valor alimenta `totalValorDevedor` (Cubit), o card, o texto de cobrança e os gráficos.
- **Parcelamento só na criação, de 1 a 48x, com parcelas iguais** — `devedores_helper.dart` (l. 112, 203–211, 279–290): todas as parcelas recebem `valorModificado` e o `valor` total gravado é `valorModificado * qtdParcelas`. Na edição não dá para parcelar nem desparcelar.
- **Valor travado quando há parcelas** — `devedores_helper.dart` (l. 101, 269–271): na edição de um devedor parcelado, o campo de valor fica somente leitura e o `valor` original é mantido. As parcelas e o `notificar` também são preservados.
- **Devedor quitado** — `card_devedores_widget.dart` (l. 82–101): todas as parcelas pagas → destaque verde e rótulo `AppStrings.quitado`. Um devedor sem parcelas nunca aparece como quitado.
- **Mensagem de cobrança** — `card_devedores_widget.dart` (l. 268–273): usa o valor **pendente** e inclui o PIX apenas se ele existir.
- **Lembrete só em data futura** — `card_devedores_widget.dart` (l. 322–327): `firstDate: DateTime.now()`.
- **Anúncio só para não-Plus** — `devedores_view.dart` (l. 190–193): um banner após o primeiro card quando `!user.isPlus`.

## Dependências Externas

- `shared_preferences` — persistência da chave `'devedores'` (`List<String>` de JSON).
- `uuid ^4.1.0` — `Uuid().v4()` gera o `id` do devedor.
- `flutter_masked_text2 ^0.9.1` — `MoneyMaskedTextController` no campo de valor.
- `share_plus ^12.0.0` — `Share.share` no chip "Cobrar".
- `flutter_local_notifications ^18.0.1` — `zonedSchedule` do lembrete.
- `timezone` (transitiva, 0.10.1 no `pubspec.lock`) — `tz.TZDateTime.from(..., tz.local)` e `initializeTimeZones()`.
- `permission_handler ^12.0.1` — `Permission.notification` e `openAppSettings`.
- `google_mobile_ads` (via `AdmobBannerWidget`) — banner `AdConfig.devedoresBanner`.

## Observações

- **ID de notificação instável:** o `id` do `zonedSchedule` é `widget.index`, a posição na lista + 1 (devedores_view l. 182), e não algo derivado do `DevedoresEntity.id`. Deletar um devedor muda as posições, e um novo agendamento pode **sobrescrever** o lembrete de outro devedor. Não existe `cancel` em lugar nenhum: deletar ou editar não remove nem reagenda a notificação, e `notificar` continua com a data mesmo depois que ela passa.
- **Corpo da notificação usa `entity.valor` (total), não `valorPendente`** (card l. 351), ao contrário do texto de cobrança. Num devedor parcelado com parcelas pagas, o lembrete mostra o valor cheio.
- **`notificar` não pode voltar a `null`:** `copyWith` usa `??`, e não há UI para remover um lembrete.
- **`DevedoresError` nunca é emitido** e o Cubit não tem `try/catch`. Um JSON corrompido na chave `'devedores'` lança exceção em `fromJson` e deixa o estado preso em `DevedoresLoading`. `setStringList` também não leva `await`; o fluxo funciona porque o `SharedPreferences` atualiza o cache em memória de forma síncrona.
- **`DevedoresEntity` foge da convenção das entities:** não tem `@immutable`, `const`, `==` nem `hashCode` (só a `ParcelaDevedorEntity` tem), e a serialização fica na própria entity em vez de um Model em `util/model/`.
- **Pedido de permissão só no bootstrap:** se o usuário negar, o sino só oferece `openAppSettings` e nunca chama `Permission.notification.request()` de novo. `_setupConfigs()` roda sem `await` em `main.dart`, e `tz.setLocalLocation` nunca é chamado (`tz.local` fica no default do pacote). O instante agendado continua correto porque `TZDateTime.from` preserva o instante absoluto.
- **Busca duplicada na inicialização:** `HomeBase.initState` e `DevedoresView.initState` chamam `buscarDevedores()`.
- **Modal com dois conjuntos de controllers** (HomeBase e DevedoresView), e `whenComplete` limpa apenas o nome. O título do bottom sheet é sempre `AppStrings.novoDevedor`, inclusive na edição.
- **Deletar sem confirmação:** um toque no chip "Deletar" apaga o devedor na hora.
- **Strings hardcoded em português** (contrariam a regra de i18n): "Nenhum devedor cadastrado", "Adicione quem te deve…", "PIX copiado!", "Editar", "Deletar", "x/N quitadas", "Chave PIX" (no modal e no texto de cobrança), "Erro ao agendar notificação".
- **Formato monetário:** a extensão `.real` (`real_format_extension.dart`) formata com locale `pt_BR`, mas usa o prefixo `$`, e não `R$`.
