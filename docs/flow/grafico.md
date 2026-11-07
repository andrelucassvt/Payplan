---
generated_at: 2026-11-07
source_commit: 93ab5b5
source_state: dirty
verified_at: 2026-11-07
status: current
---

# Flow: Gráficos

> **Resumo:** A aba 3 ("Gráficos") monta até três gráficos de pizza (`fl_chart`): dívidas do mês/ano selecionado no `HomeCubit`, devedores com valor pendente e orçamentos ativos. Ela não tem Cubit nem persistência próprios e só lê os estados de `HomeCubit`, `DevedoresCubit` e `OrcamentoCubit`. Cada card pode ser compartilhado sozinho como PNG, e o FAB compartilha todos de uma vez (`screenshot` + `path_provider` + `share_plus`).

## Visão Geral

A feature `grafico` tem um único arquivo, `GraficosView`. A pasta `widgets/` existe, mas está vazia. A tela não tem Cubit: o `HomeBase` a monta como 4º filho do `IndexedStack`, dentro de três `BlocBuilder` aninhados (`DevedoresCubit` → `HomeCubit` → `OrcamentoCubit`). Ela recebe as listas `dividas`, `devedores` e `orcamentos`, a instância do `HomeCubit` e três `ScreenshotController` criados no próprio `HomeBase`. Qualquer emissão de um dos três Cubits reconstrói a tela.

Quando o usuário toca na aba 3 da `NavigationBar`, o `HomeBase` dispara `buscarDevedores()`, `buscarDividas()` e `buscarOrcamentos()` sem `await`. Cada um emite um `Loading` com os dados atuais e depois um `Sucesso` com o que leu do `SharedPreferences`. A tela recalcula tudo no `build`, por getters: não há cache nem estado de dados local. O único estado local é o índice da fatia tocada em cada gráfico e as animações de entrada.

A tela não tem filtro de mês/ano próprio. O gráfico de dívidas usa `homeCubit.state.mesAtual` e `anoAtual`, que o usuário escolhe na aba Home (`HomeTotalWidget` → `mudarMesAtual`/`mudarAnoAtual`). Os gráficos de devedores e de orçamentos não dependem de período. Cada card só aparece se o seu total for diferente de zero. Se os três totais forem zero, a tela mostra um estado vazio.

Há dois caminhos de compartilhamento. O ícone `ios_share` de cada card chama `_share` dentro da própria `GraficosView` e compartilha só aquele card. O FAB de share, que só aparece na aba 3, chama `_HomeBaseState._shareScreenshots`: captura os cards cujo Cubit tem itens, grava os PNGs no diretório de documentos do app e abre a share sheet do sistema com todos juntos. A feature não exibe anúncios. O único anúncio relacionado é o `AppOpenAdService.instance.load()` global, chamado no `initState` do `HomeBase`.

## Passo a Passo

1. **Shell / boot** — `lib/src/features/home/view/home_base.dart` → `_HomeBaseState` (linhas 32–57)
   Cria `_homeCubit`, `_devedoresCubit`, `_orcamentoCubit` e os três `ScreenshotController` (`screenshotDividasController`, `screenshotDevedoresController`, `screenshotOrcamentosController`). No `initState` já chama `buscarDividas()`, `buscarDevedores()` e `buscarOrcamentos()`, então os gráficos têm dados antes mesmo de a aba ser aberta.
2. **Montagem da aba** — `home_base.dart` → `build`, `BlocBuilder`s aninhados (linhas 111–137)
   O `IndexedStack` constrói a `GraficosView` junto com as outras abas. Por isso o `initState` dela (e a animação de entrada) roda na montagem do `HomeBase`, não a cada entrada na aba 3. Os builders repassam `state.dividas` (HomeCubit), `stateDevedores.devedores` e `stateOrcamento.orcamentos`.
3. **Entrada na aba 3** — `home_base.dart` → `NavigationBar.onDestinationSelected` (linhas 147–156)
   Com `index == 3`, recarrega os três Cubits (`buscarDevedores`, `buscarDividas`, `buscarOrcamentos`) e faz `setState(_selectedIndex = 3)`. O `_buildFab` (linhas 183–191) passa a mostrar o FAB com `Icons.share`.
4. **Leitura nos Cubits** — `HomeCubit.buscarDividas` (`home_cubit.dart` 149–183), `DevedoresCubit.buscarDevedores` (`devedores_cubit.dart` 22–49), `OrcamentoCubit.buscarOrcamentos` (`orcamento_cubit.dart` 23–47)
   Leem as chaves `'dividas'`, `'devedores'` e `'orcamentos'` do `SharedPreferences`, desserializam (`DividaModel.fromJson`, `DevedoresEntity.fromJson`, `OrcamentoModel.fromJson`) e emitem `*Sucesso`. Cada emissão reconstrói a `GraficosView` pelos `BlocBuilder`.
5. **Agregação** — `lib/src/features/grafico/view/grafico_view.dart` → getters (linhas 54–76)
   - `_valorFatura(divida)` = `faturaDoMes(anoAtual, mesAtual.id)?.valor ?? 0` + `totalSubDividasDoMes(anoAtual, mesAtual.id)`. O período vem de `widget.homeCubit.state` (getter `state`, linha 54).
   - `valorTotalFatura` soma `_valorFatura` de todas as dívidas.
   - `valorTotalDevedores` soma `DevedoresEntity.valorPendente`.
   - `orcamentosAtivos` são os orçamentos com `!concluido && totalOrcamento > 0`, e `valorTotalOrcamentos` soma o `totalOrcamento` deles.
6. **Decisão de layout** — `grafico_view.dart` → `build` (linhas 142–381)
   Se os três totais forem `0`, mostra `_EmptyState` (linhas 569–614). Senão, abre um `SafeArea` + `SingleChildScrollView` com até três `_ChartCard`, cada um só quando o seu total é `!= 0`:
   - **Dívidas** (170–235): título `"${AppStrings.dividas} · ${mesAtual.nome} ${anoAtual}"`. As fatias vêm de `dividasFiltered` (dívidas com `_valorFatura > 0`, linha 143) e usam a cor `DividaEntity.cor`.
   - **Devedores** (238–308): título `AppStrings.devedores`. As fatias são os devedores com `valorPendente > 0`, na cor `Colors.primaries[index % length]`.
   - **Orçamentos** (310–376): título `AppStrings.fluxoOrcamento`. As fatias são os `orcamentosAtivos`, na cor `OrcamentoEntity.cor`.
7. **Renderização do card** — `grafico_view.dart` → `_ChartCard.build` (399–498)
   Envolve o card em `Screenshot(controller: ...)`, que é a área capturada. Mostra o título, o ícone de share, o total animado por `TweenAnimationBuilder` (900 ms, formatado por `.real`), o `PieChart` (altura 220, `centerSpaceRadius: 40`) e a lista de `_LegendItem` (502–565).
8. **Interação de toque** — `PieTouchData.touchCallback` em cada `PieChart` (ex.: 189–203)
   Guarda `touchedSectionIndex` em `_touchedDividaIndex`, `_touchedDevedorIndex` ou `_touchedOrcamentoIndex` (ou `-1` quando não há interação). A fatia tocada passa de raio 80 para 96 e a legenda do mesmo índice fica em destaque. O índice é posicional na lista filtrada, e fatias e legenda usam a mesma lista.
9. **Compartilhar um card** — `grafico_view.dart` → `_share(ScreenshotController)` (384–394)
   Chama `controller.capture()` e retorna se o resultado for `null`. Grava em `${getApplicationDocumentsDirectory()}/image.png` e chama `Share.shareXFiles([XFile], text: AppStrings.baixePayplan)`.
10. **Compartilhar todos (FAB)** — `home_base.dart` → `_shareScreenshots` (228–271)
    - Captura cada card só se o Cubit dele tiver itens: `_homeCubit.temDividas()`, `_devedoresCubit.temDevedores()`, `_orcamentoCubit.temOrcamentos()`. Os três são `state.<lista>.isNotEmpty`.
    - Grava os resultados não nulos em `image.png`, `image2.png` e `image3.png` no diretório de documentos e chama `Share.shareXFiles(filesToShare, text: AppStrings.baixePayplan)` se a lista não estiver vazia.

### Caminhos alternativos

- **Sem dados para nenhum gráfico:** `GraficosView.build` mostra `_EmptyState` com textos fixos em pt-BR (`'Nenhum dado para exibir'`, `'Adicione dívidas ou devedores\npara ver os gráficos'`).
- **Cubit tem itens, mas o card não é renderizado** (ex.: há dívidas, mas nenhuma tem valor no mês): `temDividas()` dá `true`, mas o `Screenshot` daquele card não está na árvore. Aí `ScreenshotController.capture()` retorna `null` (no `screenshot 3.0.0`, `currentContext?.findRenderObject()` é nulo) e o arquivo é pulado.
- **Nenhuma imagem capturada no FAB:** se `filesToShare` ficar vazio, nada acontece e o usuário não recebe nenhum feedback.
- **Exceção na captura ou gravação pelo FAB:** o `catch` em `_shareScreenshots` mostra `SnackBar` vermelho com o texto fixo `'Captura de tela falhou.'` (se `context.mounted`).
- **Exceção no share de um card:** `_share` não tem `try/catch`, então o erro sobe sem tratamento.
- **`capture()` retorna `null` no share de um card:** `_share` retorna em silêncio.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Apresentação | `lib/src/features/grafico/view/grafico_view.dart` | `GraficosView`: agrega os valores, monta os 3 `PieChart`, cuida do toque, da animação de entrada, do estado vazio e do share por card (`_share`). Também contém os widgets privados `_ChartCard`, `_LegendItem` e `_EmptyState`. |
| Apresentação (shell) | `lib/src/features/home/view/home_base.dart` | Cria os Cubits e os `ScreenshotController`, monta a aba 3 com `BlocBuilder` aninhados, recarrega os dados ao entrar na aba e faz o share em lote pelo FAB (`_shareScreenshots`). |
| Estado | `lib/src/features/home/cubit/home_cubit.dart` | Fornece `dividas`, `mesAtual` e `anoAtual` (o período do gráfico de dívidas), `buscarDividas()` e `temDividas()`. |
| Estado | `lib/src/features/devedores/cubit/devedores_cubit.dart` | Fornece `devedores`, `buscarDevedores()` e `temDevedores()`. |
| Estado | `lib/src/features/orcamento/cubit/orcamento_cubit.dart` | Fornece `orcamentos`, `buscarOrcamentos()` e `temOrcamentos()`. |
| Domínio | `lib/src/util/entity/divida_entity.dart` | `faturaDoMes`, `totalSubDividasDoMes`, `SubDividaEntity.aplicavelNoMes` (recorrente vale para todo mês), `cor` e `nome`. |
| Domínio | `lib/src/util/entity/devedores_entity.dart` | `valorPendente`: o `valor` se não houver parcelas, senão a soma das parcelas com `!pago`. |
| Domínio | `lib/src/util/entity/orcamento_entity.dart` | `totalOrcamento`: soma dos sub-itens não concluídos, ou `valor` (`0` se `concluido`) quando não há sub-itens. Também `concluido`, `cor` e `nome`. |
| Utilitário | `lib/src/util/extension/real_format_extension.dart` | `double.real`: formatação monetária dos totais e das legendas. |
| Configuração | `lib/src/util/strings/app_strings.dart` + `lib/i18n/*.json` | `graficoGastos`, `dividas`, `devedores`, `fluxoOrcamento`, `baixePayplan`, `graficos`. |
| Testes | `test/util/entity/orcamento_entity_test.dart` | É o único teste do projeto. Cobre `OrcamentoEntity`, não a `GraficosView` nem o compartilhamento. |

## Regras de Negócio Relevantes

- **O gráfico de dívidas segue o mês/ano escolhido na Home** — `grafico_view.dart` (`_valorFatura`, linhas 56–61): usa `HomeCubit.state.mesAtual`/`anoAtual`. A aba Gráficos não tem seletor de período.
- **O valor da dívida no gráfico inclui o que já foi pago** — `grafico_view.dart` (`_valorFatura`): soma o valor da fatura do mês e as subdívidas aplicáveis sem olhar `FaturaMensalEntity.pago` nem `DividaEntity.mensal`. A Home usa outra conta: `totalGastos` vem de `DividaEntity.totalNaoPagoDoMes`, que zera as faturas pagas.
- **Subdívida recorrente entra em todo mês** — `divida_entity.dart` (`SubDividaEntity.aplicavelNoMes`): `recorrente` vale `true` em qualquer período. Sem isso, a subdívida só entra quando `ano`/`mes` batem com o período.
- **Devedores mostram só o valor pendente e sem período** — `grafico_view.dart` (linhas 66–68, 271–273) + `devedores_entity.dart` (`valorPendente`): parcelas pagas não entram, e devedores com pendente `0` ficam de fora.
- **Orçamentos concluídos ou zerados ficam de fora** — `grafico_view.dart` (`orcamentosAtivos`, linhas 70–72): filtra `!concluido && totalOrcamento > 0`.
- **Card só aparece com total diferente de zero; estado vazio só quando os três são zero** — `grafico_view.dart` (`build`, linhas 160–163, 170, 238, 310).
- **O share em lote só inclui as seções com dados no Cubit** — `home_base.dart` (`_shareScreenshots`): usa `temDividas`/`temDevedores`/`temOrcamentos` e sempre manda o texto promocional `AppStrings.baixePayplan`.

## Dependências Externas

- **`fl_chart` ^1.1.1**: `PieChart`, `PieChartData`, `PieChartSectionData`, `PieTouchData`.
- **`screenshot` ^3.0.0**: `Screenshot` (widget) e `ScreenshotController.capture()`, que gera PNG via `RenderRepaintBoundary.toImage`.
- **`path_provider` ^2.0.15**: `getApplicationDocumentsDirectory()`, onde os PNGs são gravados.
- **`share_plus` ^12.0.0**: `Share.shareXFiles` e `XFile`, que abrem a share sheet nativa.
- **`shared_preferences`**: lido indiretamente pelos três Cubits (chaves `'dividas'`, `'devedores'`, `'orcamentos'`).

## Observações

- **A última dívida apagada continua no gráfico:** `HomeCubit.buscarDividas` emite `dividas: dividas.isEmpty ? state.dividas : dividas` (`home_cubit.dart` linha 178). Ao remover a última dívida, a lista antiga fica no estado, e a fatia continua no gráfico (e `temDividas()` continua `true`) até o app reiniciar.
- **Gráfico e Home divergem no total de dívidas:** o total do gráfico inclui faturas pagas e subdívidas recorrentes de dívidas não mensais sem fatura no mês. Por isso ele pode diferir do `totalGastos` da Home para o mesmo período (ver Regras).
- **Arquivos de share sobrescritos:** `_share` (por card) e `_shareScreenshots` (FAB) gravam sempre nos mesmos nomes (`image.png`, `image2.png`, `image3.png`), sobrescrevendo os anteriores. Os arquivos nunca são apagados depois.
- **`tem*()` não é a condição de exibição:** `temDividas()`/`temDevedores()`/`temOrcamentos()` olham apenas se a lista está vazia, não se o card foi renderizado. A captura de um card ausente só não quebra porque `capture()` devolve `null`.
- **Strings fixas fora da i18n:** o `_EmptyState`, o SnackBar `'Captura de tela falhou.'` e os nomes de mês (`MesesEnum.nome`, em pt-BR, usados no título do card de dívidas) não são localizados. O texto do estado vazio não menciona orçamentos, embora o card de orçamentos exista.
- **Formato monetário:** `.real` (`real_format_extension.dart`) prefixa `$` em vez de `R$` e usa sempre `locale: "pt_BR"`, independente do idioma do app.
- **Cores dos devedores dependem da posição:** a cor vem do índice na lista filtrada (`Colors.primaries[i % length]`), não do devedor. Ela muda quando um devedor entra, sai ou zera o pendente.
- **Animação de entrada provavelmente invisível:** o `AnimationController` (1200 ms, cards escalonados) é disparado no `initState`, que roda quando o `IndexedStack` monta o `HomeBase`, e não ao abrir a aba 3. A animação tende a terminar antes de o usuário ver a tela. O total animado (`TweenAnimationBuilder`) também só anima quando o valor muda.
- **Recargas sem `await`:** ao entrar na aba, os três `buscar*` são chamados sem `await`. A tela é reconstruída até seis vezes (Loading + Sucesso de cada Cubit), mas os `Loading` copiam os dados atuais, então não há tela vazia intermediária.
- **Sem cobertura de testes** para a agregação dos gráficos e para o compartilhamento.
