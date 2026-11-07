---
generated_at: 2026-11-07
source_commit: 93ab5b5
source_state: dirty
verified_at: 2026-11-07
status: current
---

# Flow: Nova Dívida (cadastro e edição de dívida)

> **Resumo:** Tela `NovaDividaView` que cria uma dívida mensal ou parcelada (1–48 parcelas, faturas geradas mês a mês a partir do mês atual) ou edita/exclui uma existente, alterando só nome e cor. Grava na chave `'dividas'` do `SharedPreferences` via `HomeCubit.salvarDivida`/`atualizarDivida`/`removerDivida` e recarrega a Home com `buscarDividas()`.

## Visão Geral

Há dois pontos de entrada, e ambos usam a mesma tela. Para **cadastrar**, o usuário toca no FAB da aba 0 (Home) em `HomeBase`, que abre `NovaDividaView` passando só o `HomeCubit`. Para **editar**, o usuário toca no chip de lápis (`Icons.edit_outlined`) de um card da lista (`HomeCardDivida`), que abre a mesma tela com `dividaEntity` preenchido. A feature `nova_divida` não tem Cubit próprio: usa o `HomeCubit` criado em `HomeBase` e recebido pelo construtor.

No cadastro, o formulário tem nome, cor (12 cores fixas) e tipo: **Mensal** (padrão) ou **Parcelada**. Uma dívida mensal é salva sem faturas (`faturas: []`). O valor de cada mês é informado depois, pelo botão "Editar fatura" do card na Home. Uma dívida parcelada pede a quantidade (1x a 48x) e o valor da parcela. A View gera uma `FaturaMensalEntity` por parcela, todas com o mesmo valor, a partir do mês/ano corrente (`DateTime.now()`) e virando o ano depois de dezembro. Um aviso informa que o tipo e as parcelas não podem ser alterados depois.

Na edição, a seção de tipo e valor fica escondida. Só nome e cor são aplicados, via `copyWith` sobre a entidade original, o que preserva `id`, `mensal`, `faturas` e `subDividas`. A AppBar mostra o botão "Deletar", que remove a dívida sem confirmação.

Toda escrita segue o mesmo padrão no `HomeCubit`: emite `HomeDividasLoading`, lê a lista inteira de `'dividas'` (JSON por item), aplica a mudança, regrava a lista com `DividaModel.toJson()` e chama `buscarDividas()`. Esse método relê a lista, recalcula `totalGastos` do mês selecionado e emite `HomeDividasSucesso`. A `HomeView` é redesenhada pelo `BlocConsumer`. A listagem e os totais têm flow próprio (`docs/flow/home.md`).

## Passo a Passo

### Cadastro

1. **Shell / gatilho** — `lib/src/features/home/view/home_base.dart` → `_buildFab()` (l. 194–201)
   Com `_selectedIndex == 0`, faz `Navigator.push(MaterialPageRoute(builder: (_) => NovaDividaView(homeCubit: _homeCubit)))`, sem `dividaEntity`.
2. **View (estado local)** — `lib/src/features/nova_divida/view/nova_divida_view.dart` → `_NovaDividaViewState`
   Estado inicial: `_corSelecionada = 0xFFEF4444`, `_nomeDivida = ''`, `_isMensal = true`, `_quantidadeParcelas = 1`, `_valorParcela = 0.0` e `_faturaTextController` (`MoneyMaskedTextController`). Tudo vive em `setState`: o `HomeCubit` não é tocado até o salvar.
3. **Formulário** — `nova_divida_view.dart` → `build()` + widgets de `lib/src/features/nova_divida/content/nova_divida_form_content.dart`
   - `NovaDividaPreviewCard`: prévia ao vivo com a cor e o nome digitado.
   - `TextField` do nome (`onChanged` → `_nomeDivida`) e grade de cores (`_listColors`, 12 cores).
   - Bloco exibido só quando `!isEditing` (l. 285–390): aviso `AppStrings.naoPodeModificar`, chips `NovaDividaTypeChip` (Mensal/Parcelada) e, se parcelada, `NovaDividaParcelaSelector` (`PopupMenuButton` de 1x a 48x) e o campo "Valor da parcela" com prefixo fixo `R$ ` (`_valorParcela = _faturaTextController.numberValue`).
4. **Salvar (validação)** — `nova_divida_view.dart` → `_salvar()` (l. 76–88)
   Nome vazio mostra o SnackBar `AppStrings.digiteONomeDivida` e aborta. Parcelada com `_valorParcela == 0.0` mostra o SnackBar `AppStrings.valorParcela` e aborta.
5. **Montagem da entidade** — `_salvar()` (l. 97–116)
   Cria `DividaEntity(id: Uuid().v4(), nome, mensal: _isMensal, cor, faturas: ...)`. Mensal recebe `[]`. Parcelada recebe `List.generate(_quantidadeParcelas, ...)` com `FaturaMensalEntity(ano: _calculoAno, mes: _calculoMeses(i), valor: _valorParcela)`. `_calculoMeses` (l. 51–61) começa em `DateTime.now().month` e incrementa a cada parcela. Ao chegar em 12, soma 1 em `_calculoAno` (que só vale para a parcela seguinte, porque `ano:` é lido antes de `mes:`). Acima de 12, volta para 1.
6. **Cubit (persistência)** — `lib/src/features/home/cubit/home_cubit.dart` → `salvarDivida()` (l. 128–147)
   Emite `HomeDividasLoading` copiando o estado. Lê `prefs.getStringList('dividas')`, acrescenta `json.encode(DividaModel.fromEntity(e).toJson())` e chama `prefs.setStringList(...)` sem `await`. Depois chama `buscarDividas()`.
7. **Serialização** — `lib/src/util/model/divida_model.dart` → `DividaModel.toJson()` (l. 110–121)
   Gera `{id, nome, mensal, cor: cor.toARGB32(), faturas: [{ano, mes, pago, valor}], 'sub-dividas': [...]}`. A chave de sub-dívidas usa hífen.
8. **Fechamento** — `_salvar()` (l. 118)
   `Navigator.of(context).pop()` roda logo após disparar o método do Cubit, sem aguardar o `Future`.
9. **Refresh** — `home_cubit.dart` → `buscarDividas()` (l. 149–183)
   Emite `HomeDividasLoading`, relê `'dividas'` via `DividaModel.fromJson` e soma `totalNaoPagoDoMes(state.anoAtual, state.mesAtual.id)` de cada dívida. Lê `'salario_fixo'` e emite `HomeDividasSucesso`. A `HomeView` (`BlocConsumer`, `home_view.dart` l. 56) reconstrói a lista de `HomeCardDivida`.

### Edição

1. **Gatilho** — `lib/src/features/home/widgets/home_card_divida.dart` → `_ActionChip(icon: Icons.edit_outlined)` (l. 385–398)
   Faz `Navigator.push` de `NovaDividaView(homeCubit: widget.homeCubit, dividaEntity: widget.dividaEntity)`.
2. **Pré-carregamento** — `nova_divida_view.dart` → `initState()` (l. 63–74)
   Num `addPostFrameCallback`, copia `nome` e `cor` da entidade para `_nomeDivida`/`_corSelecionada`. O `TextField` do nome não tem controller, então o campo aparece vazio (o nome só aparece no preview). Ver Observações.
3. **UI de edição** — `build()`
   O título vira `AppStrings.atualizarDivida`, o bloco de tipo/parcelas/valor some (`if (!isEditing)`) e a AppBar ganha o `TextButton.icon` "Deletar".
4. **Salvar** — `_salvar()` (l. 90–96)
   Passa pelas mesmas validações. Na edição a de parcela não se aplica, porque `_isMensal` continua `true` no estado local. Chama `homeCubit.atualizarDivida(dividaEntity.copyWith(cor, nome))` e faz `pop()`.
5. **Cubit** — `home_cubit.dart` → `atualizarDivida()` (l. 97–126)
   Emite Loading, desserializa a lista e troca o item de mesmo `id` por `DividaModel.fromEntity(nova)`. Regrava a lista (sem `await`) e chama `buscarDividas()`.

### Exclusão

1. **Gatilho** — `nova_divida_view.dart` → AppBar `actions` (l. 143–161), só em modo edição.
2. **Cubit** — `home_cubit.dart` → `removerDivida()` (l. 71–95)
   Emite Loading, desserializa a lista, faz `removeWhere(id == dividaEntity.id)`, regrava e chama `buscarDividas()`.
3. **Fechamento** — `.whenComplete(() => Navigator.pop())`: aqui a View espera o `Future` antes de fechar. Como `setStringList` não é aguardado e `buscarDividas` é `void`, o `Future` termina antes do refresh.

### Caminhos alternativos

- **Nome vazio:** SnackBar `digiteONomeDivida` ("Digite o nome da dívida..."). A tela continua aberta (`_salvar`, l. 77–82).
- **Parcelada sem valor:** SnackBar com o texto de `AppStrings.valorParcela` ("Valor da parcela") (`_salvar`, l. 83–88).
- **Sem tratamento de erro de persistência:** nenhum método de escrita do `HomeCubit` tem `try/catch` ou estado de erro. Uma exceção no `fromJson` ou no `SharedPreferences` vira erro não tratado com a tela já fechada.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Apresentação (entrada) | `lib/src/features/home/view/home_base.dart` | FAB da aba 0 abre o cadastro com o `_homeCubit` compartilhado |
| Apresentação (entrada) | `lib/src/features/home/widgets/home_card_divida.dart` | Chip de edição abre a tela com `dividaEntity` |
| Apresentação | `lib/src/features/nova_divida/view/nova_divida_view.dart` | Estado do formulário, validação, geração das parcelas, escolha entre salvar/atualizar/remover, `pop` |
| Apresentação | `lib/src/features/nova_divida/content/nova_divida_form_content.dart` | `NovaDividaPreviewCard`, `NovaDividaSectionCard`, `NovaDividaSectionLabel`, `NovaDividaTypeChip`, `NovaDividaParcelaSelector` (1–48) |
| Estado + persistência | `lib/src/features/home/cubit/home_cubit.dart` | `salvarDivida`, `atualizarDivida`, `removerDivida`, `buscarDividas`; lê e grava `'dividas'` |
| Estado | `lib/src/features/home/cubit/home_state.dart` | `HomeDividasLoading` / `HomeDividasSucesso` emitidos pelas escritas |
| Domínio | `lib/src/util/entity/divida_entity.dart` | `DividaEntity` (`copyWith`, `totalNaoPagoDoMes`), `FaturaMensalEntity`, `SubDividaEntity` |
| Dados | `lib/src/util/model/divida_model.dart` | `DividaModel` / `FaturaMensalModel` / `SubDividaModel`: `fromJson`, `toJson`, `fromEntity` |
| Configuração | `lib/src/util/strings/app_strings.dart` + `lib/i18n/*.json` | Textos da tela (`novaDivida`, `atualizarDivida`, `naoPodeModificar`, `valorParcela`, `parcelada`, `mensal`...) |
| Testes | — | Nenhum. `test/util/entity/orcamento_entity_test.dart` não cobre dívidas |

## Regras de Negócio Relevantes

- **Dois tipos de dívida no cadastro: Mensal ou Parcelada** — `nova_divida_view.dart` (`_isMensal`, padrão `true`). Mensal nasce com `faturas: []` e `mensal: true`. Parcelada nasce com N faturas e `mensal: false`.
- **Parcelamento de 1 a 48 vezes, todas com o mesmo valor** — `nova_divida_form_content.dart` → `NovaDividaParcelaSelector` (`List.generate(48, ...)`) e `nova_divida_view.dart` → `_salvar()` (`valor: _valorParcela` em todas).
- **A primeira parcela cai no mês atual** — `_calculoMeses(0)` usa `DateTime.now().month`, e as seguintes avançam um mês por vez, virando o ano depois de dezembro.
- **Parcelada exige valor da parcela diferente de zero** — `_salvar()`, l. 83. Mensal não pede valor no cadastro: ele é definido mês a mês no card da Home ("Editar fatura", que mostra App Open Ad para quem não é Plus — `home_card_divida.dart` → `_editarFaturaBottomSheet`).
- **Tipo, quantidade e valor de parcela não mudam depois do cadastro** — `nova_divida_view.dart` (bloco `if (!isEditing)` + aviso `naoPodeModificar`). A edição só altera `nome` e `cor`. Faturas, `pago` e sub-dívidas são preservados pelo `copyWith`.
- **Dívida parcelada sem fatura no mês não pesa no total** — `divida_entity.dart` → `totalNaoPagoDoMes` (`!mensal && fatura == null` → `0.0`). Mensal sem fatura soma só as sub-dívidas aplicáveis.
- **Identidade por UUID v4** — `_salvar()` gera `id` com `Uuid().v4()`. `atualizarDivida`/`removerDivida` localizam o item por `id`.
- **Exclusão sem confirmação** — `nova_divida_view.dart`, l. 145–150: o toque em "Deletar" remove na hora.

## Dependências Externas

- `shared_preferences`: chave `'dividas'` (`List<String>`, um JSON por dívida) e leitura de `'salario_fixo'` no refresh.
- `uuid`: geração do `id` da dívida.
- `flutter_masked_text2`: `MoneyMaskedTextController` do valor da parcela.

## Observações

- **Lista não esvazia ao excluir a última dívida:** `buscarDividas()` emite `dividas: dividas.isEmpty ? state.dividas : dividas` (`home_cubit.dart`, l. 178). Depois de `removerDivida` deixar `'dividas'` vazia, a Home continua mostrando a dívida removida, com `totalGastos` 0, até o app reiniciar e o estado inicial ser `[]`.
- **Campo de nome vazio na edição:** o `TextField` (l. 191–227) não tem `controller` nem `initialValue`, então o nome atual não aparece no campo. Salvar sem digitar mantém o nome antigo, e digitar começa do zero (não dá para corrigir só uma letra).
- **Escritas sem `await`:** `prefs.setStringList` não é aguardado em `salvarDivida`/`atualizarDivida`/`removerDivida`, `buscarDividas()` é `void async` e o cadastro/edição faz `pop()` sem esperar o `Future`. Hoje funciona porque o `SharedPreferences` atualiza o cache em memória na hora, mas a ordem dos eventos não é garantida e erros se perdem.
- **Geração de parcelas depende da ordem dos argumentos:** em `FaturaMensalEntity(ano: _calculoAno, mes: _calculoMeses(i), ...)`, o ano certo só sai porque `ano:` é avaliado antes de `_calculoMeses` incrementar `_calculoAno`. Inverter os argumentos nomeados põe a parcela de dezembro no ano seguinte. A lógica também muta campos do `State` (`_calculoMes`, `_calculoAno`) em vez de calcular a partir do índice.
- **Mensagem de validação genérica:** com parcelada e valor 0, o SnackBar mostra só "Valor da parcela" (o rótulo do campo), sem dizer que é um erro.
- **Preview sempre diz "Nova dívida":** `NovaDividaPreviewCard` usa `AppStrings.novaDivida` fixo no selo, inclusive em modo edição.
- **Prefixo de moeda fixo:** o campo de valor usa `prefixText: 'R$ '` hardcoded, que não acompanha o locale (en_US/es_ES).
- **Sub-dívidas não são criadas nesta tela:** são gerenciadas pelo card na Home (`adicionarSubDivida`/`atualizarSubDivida`/`removerSubDivida` no `HomeCubit`, que delegam a `atualizarDivida`). Esta tela só as preserva na edição.
