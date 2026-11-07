---
generated_at: 2026-11-07
source_commit: 93ab5b5
source_state: dirty
verified_at: 2026-11-07
status: current
---

# Flow: Orçamento

> **Resumo:** Aba "Orçamentos" (índice 2) e formulário `novo_orcamento`: criar, editar, excluir e concluir orçamentos de valor fixo ou compostos por sub-itens marcáveis individualmente, com o total geral (soma do que ainda não foi concluído) recalculado pelo `OrcamentoCubit` a partir da chave `'orcamentos'` do `SharedPreferences`.

## Visão Geral

`HomeBase` cria um único `OrcamentoCubit`, chama `buscarOrcamentos()` no `initState` e de novo sempre que o usuário entra na aba 2 (ou na aba 3, Gráficos). O mesmo Cubit é repassado por construtor para `OrcamentoView`, para cada `OrcamentoCardWidget` e para `NovoOrcamentoView`, que não tem Cubit próprio. A `OrcamentoView` desenha o header animado `OrcamentoTotalWidget` (mostra `state.totalGeral`) e a lista de cards; para usuários não-Plus, intercala banners AdMob depois do 1º e do 2º card.

A criação começa pelo FAB da aba 2, que abre `NovoOrcamentoView` sem orçamento; a edição começa pelo ícone de lápis do card, que abre a mesma tela com `orcamento`. No formulário o usuário escolhe o tipo (valor fixo ou com sub-itens), nome, cor (12 cores fixas) e valor. Os sub-itens **não** são criados no formulário: são gerenciados depois no bottom sheet "Sub-itens" do card.

Toda escrita segue o mesmo padrão dentro do Cubit: emite `OrcamentoLoading`, lê a `List<String>` de `'orcamentos'`, decodifica cada JSON em `OrcamentoModel`, aplica a mudança, grava a lista inteira de volta e dispara `buscarOrcamentos()` (sem `await`), que emite `OrcamentoSucesso` com a lista e o `totalGeral`. As operações de sub-item e de conclusão montam um novo `OrcamentoEntity` via `copyWith` e delegam para `atualizarOrcamento()`.

O valor de cada orçamento vem do getter `OrcamentoEntity.totalOrcamento`: sem sub-itens, vale `valor` (ou `0.0` se concluído); com sub-itens, vale a soma dos sub-itens não concluídos, e o `valor` fixo é ignorado. "Concluir" um orçamento propaga a mesma flag para todos os sub-itens. A aba Gráficos consome a mesma lista do estado, mas aplica um filtro próprio (`!concluido && totalOrcamento > 0`).

## Passo a Passo

### Carregamento

1. **Shell** — `lib/src/features/home/view/home_base.dart` → `_HomeBaseState`
   Campo `final _orcamentoCubit = OrcamentoCubit()` (linha 34); `initState` chama `_orcamentoCubit.buscarOrcamentos()` (linha 52). `NavigationBar.onDestinationSelected` recarrega ao entrar na aba 2 (linha 149) e na aba 3 (linha 153). O `IndexedStack` monta `OrcamentoView(cubit:, scrollController: _scrollControllers[2])` (linhas 107-110).
2. **Cubit** — `lib/src/features/orcamento/cubit/orcamento_cubit.dart` → `buscarOrcamentos()` (linhas 23-47)
   Emite `OrcamentoLoading` copiando `orcamentos`/`totalGeral` atuais, lê `prefs.getStringList('orcamentos') ?? []`, decodifica com `OrcamentoModel.fromJson(json.decode(e))`, soma `o.totalOrcamento` em `fold` e emite `OrcamentoSucesso`. Não há `try/catch` nem estado de erro.
3. **Model** — `lib/src/util/model/orcamento_model.dart` → `OrcamentoModel.fromJson()` (linhas 50-61)
   `cor` vem de `int` (`Color(json['cor'])`), `concluido` tem default `false`, e a lista de sub-itens vem da chave com hífen `'sub-itens'` (default `[]`), cada uma via `SubItemOrcamentoModel.fromJson()`.
4. **Entity** — `lib/src/util/entity/orcamento_entity.dart` → getter `totalOrcamento` (linhas 29-35)
   Calcula o valor que entra no total geral e no card (regra detalhada abaixo).
5. **View** — `lib/src/features/orcamento/view/orcamento_view.dart` → `BlocBuilder<OrcamentoCubit, OrcamentoState>` (linhas 51-120)
   Reconstrói com qualquer estado (não diferencia `Loading` de `Sucesso`, então não há spinner). Mostra `OrcamentoTotalWidget`, um rótulo de seção e, se a lista estiver vazia, `_EmptyState`; senão, `ListView.builder` de `OrcamentoCardWidget` envolto em `ValueListenableBuilder(UserController.user)` para os anúncios.
6. **Header** — `lib/src/features/orcamento/widgets/orcamento_total_widget.dart` → `_OrcamentoTotalWidgetState`
   Exibe `state.totalGeral.real` e o botão de tema (`ThemeController.toggle`). Quando `OrcamentoView._onScroll` detecta `offset > 60`, `isCollapsed` muda e `didUpdateWidget` roda o `AnimationController` (300 ms) para esconder título/rótulo e reduzir a fonte de 36 para 24.
7. **Card** — `lib/src/features/orcamento/widgets/orcamento_card_widget.dart` → `_OrcamentoCardWidgetState.build()`
   Header em gradiente da `cor` com inicial do nome, contagem de sub-itens e selo "Em andamento"/"Orçamento concluído"; valor `totalOrcamento` (riscado se `concluido`); até 3 sub-itens (`_SubItemRow`) com "ver mais/ver menos" local (`_expandedSubItens`); linha de ações `_ActionChip` (Sub-itens, Concluir, editar, excluir).

### Criar / editar orçamento

8. **Entrada** — `home_base.dart` → `_buildFab()` (linhas 202-208) quando `_selectedIndex == 2`: `Navigator.push(MaterialPageRoute(NovoOrcamentoView(orcamentoCubit: _orcamentoCubit)))`.
   - *Editar:* `orcamento_card_widget.dart` linhas 293-305, ícone `edit_outlined` → `NovoOrcamentoView(orcamentoCubit:, orcamento: widget.orcamento)`.
9. **Form View** — `lib/src/features/novo_orcamento/view/novo_orcamento_view.dart` → `initState()` (linhas 48-63)
   Cria `_valorTextController` (`MoneyMaskedTextController`). Em edição, num `addPostFrameCallback`, preenche nome, cor, `valor` e define `_comSubItens = orcamento.subItens.isNotEmpty` — o tipo não é persistido, é inferido da lista.
10. **Form content** — `lib/src/features/novo_orcamento/content/novo_orcamento_form_content.dart`
    `NovoOrcamentoPreviewCard` (prévia com cor/nome), `NovoOrcamentoTipoToggle` (alterna `_comSubItens`), `NovoOrcamentoSectionCard`/`NovoOrcamentoSectionLabel` (moldura das seções) e `NovoOrcamentoSubItensHint` (texto exibido no lugar do campo de valor quando `_comSubItens`, via `AnimatedCrossFade`, linhas 289-348 da view).
11. **Form View** → `_salvar()` (linhas 71-103), acionado pelo FAB "Salvar"
    - Nome vazio → `SnackBar(AppStrings.digiteONomeOrcamento)` e retorna.
    - `valor = _comSubItens ? 0.0 : _valorTextController.numberValue`.
    - Edição → `atualizarOrcamento(orcamento.copyWith(nome:, cor:, valor:))` — preserva `subItens` e `concluido`.
    - Criação → `salvarOrcamento(OrcamentoEntity(id: Uuid().v4(), ...))` — nasce sem sub-itens e não concluído.
    - Faz `Navigator.pop()` logo em seguida, sem esperar o Cubit.
12. **Cubit** → `salvarOrcamento()` (linhas 49-63) acrescenta `json.encode(OrcamentoModel.fromEntity(e).toJson())` ao fim da lista; `atualizarOrcamento()` (linhas 65-90) decodifica tudo, substitui o item com o mesmo `id` (se não achar, regrava a lista sem mudança) e regrava. Ambos terminam em `buscarOrcamentos()`.

### Concluir / reabrir orçamento

13. **Card** — `_ActionChip` verde (linhas 284-291), rótulo "Concluir" ou "Orçamento concluído" → `toggleOrcamentoConcluido(widget.orcamento)`.
14. **Cubit** → `toggleOrcamentoConcluido()` (linhas 163-174)
    Inverte `concluido` e aplica o mesmo valor a todos os sub-itens; chama `atualizarOrcamento()`. O próximo `buscarOrcamentos()` já soma `0.0` para esse orçamento.

### Sub-itens

15. **Marcar sub-item (no card)** — `_SubItemRow.onToggle` (linhas 217-226) → `toggleSubItemConcluido(orcamento, s.id)` (cubit, linhas 150-161), que inverte só aquele sub-item e chama `atualizarOrcamento()`. O toque é direto na linha do sub-item, fora do bottom sheet.
16. **Abrir gerenciador** — `_ActionChip` "Sub-itens" → `_gerenciarSubItensBottomSheet()` (linhas 446-669)
    `showModalBottomSheet` com a lista (altura fixa de 200) de `widget.orcamento.subItens`, ícones de editar/remover e o formulário "Adicionar" (nome + `MoneyMaskedTextController`).
17. **Adicionar** — botão "Salvar" (linhas 635-650): se nome (trim) vazio ou valor `0.0`, ignora em silêncio; senão `adicionarSubItem(orcamento, SubItemOrcamentoEntity(id: Uuid().v4(), ...))` (cubit, linhas 115-124) e fecha o sheet.
18. **Editar** — ícone de lápis → `_editarSubItemDialog(sheetContext, s)` (linhas 321-413): `AlertDialog` pré-preenchido; mesma validação (linha 393); `atualizarSubItem(orcamento, subItem.copyWith(nome:, valor:))` (cubit, linhas 137-148) e fecha o dialog **e** o sheet.
19. **Remover** — ícone de lixeira (linhas 550-557): `removerSubItem(orcamento, s.id)` (cubit, linhas 126-135) sem confirmação e fecha o sheet.

### Excluir orçamento

20. **Pelo card** — `_confirmarDelecao()` (linhas 415-444): `AlertDialog` "Atenção / orcamentoSeraRemovido"; ao confirmar, `removerOrcamento(widget.orcamento)`.
21. **Pelo formulário (edição)** — action "Deletar" da `AppBar` (`novo_orcamento_view.dart` linhas 127-145): chama `removerOrcamento()` **sem confirmação** e faz `pop` no `whenComplete`.
22. **Cubit** → `removerOrcamento()` (linhas 92-113): decodifica, `removeWhere(e.id == orcamento.id)`, regrava e chama `buscarOrcamentos()`.

### Caminhos alternativos

- **Lista vazia:** `OrcamentoView` mostra `_EmptyState` (`nenhumOrcamento` + `adicioneUmOrcamento`), sem o `ListView` (logo, sem os banners).
- **Nome vazio no formulário:** `_salvar()` mostra `SnackBar` e não chama o Cubit.
- **Sub-item com nome vazio ou valor zero:** adicionar (linhas 636-640) e editar (linha 393) retornam sem feedback visual; o sheet/dialog permanece aberto.
- **Usuário Plus:** `if (!user.isPlus)` em `orcamento_view.dart` linha 99 suprime os banners.
- **Scroll da lista:** `_onScroll` (linhas 40-45) só chama `setState` quando o limiar de 60 px é cruzado, disparando o colapso do header.

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|------------------|
| Shell / Navegação | `lib/src/features/home/view/home_base.dart` | Cria o `OrcamentoCubit`, recarrega nas abas 2 e 3, monta `OrcamentoView` no `IndexedStack`, FAB da aba 2 abre `NovoOrcamentoView`; usa `temOrcamentos()` para o screenshot compartilhado |
| Apresentação | `lib/src/features/orcamento/view/orcamento_view.dart` | Aba de orçamentos: `BlocBuilder`, empty state, lista de cards, banners para não-Plus, detecção de scroll |
| Apresentação | `lib/src/features/orcamento/widgets/orcamento_total_widget.dart` | Header com `totalGeral`, botão de tema e animação de colapso |
| Apresentação | `lib/src/features/orcamento/widgets/orcamento_card_widget.dart` | Card do orçamento; toggle de sub-item inline, bottom sheet de sub-itens, dialog de edição de sub-item, confirmação de exclusão, botão de concluir e de editar |
| Apresentação | `lib/src/features/novo_orcamento/view/novo_orcamento_view.dart` | Formulário de criação/edição (tipo, nome, cor, valor), validação do nome, exclusão sem confirmação em modo edição |
| Apresentação | `lib/src/features/novo_orcamento/content/novo_orcamento_form_content.dart` | Peças do formulário: `NovoOrcamentoTipoToggle`, `NovoOrcamentoPreviewCard`, `NovoOrcamentoSubItensHint`, `NovoOrcamentoSectionCard`, `NovoOrcamentoSectionLabel` |
| Estado | `lib/src/features/orcamento/cubit/orcamento_cubit.dart` | Leitura/escrita da chave `'orcamentos'`, cálculo do `totalGeral`, CRUD de orçamento e de sub-item, conclusão |
| Estado | `lib/src/features/orcamento/cubit/orcamento_state.dart` | `sealed OrcamentoState` com `OrcamentoInitial`, `OrcamentoLoading`, `OrcamentoSucesso` (todos com `orcamentos` e `totalGeral`; sem estado de erro) |
| Entity | `lib/src/util/entity/orcamento_entity.dart` | `OrcamentoEntity` e `SubItemOrcamentoEntity` imutáveis; getter `totalOrcamento` |
| Model | `lib/src/util/model/orcamento_model.dart` | `OrcamentoModel` / `SubItemOrcamentoModel`: `fromJson`, `toJson`, `fromEntity` (cor como ARGB `int`, sub-itens em `'sub-itens'`) |
| Consumidor | `lib/src/features/grafico/view/grafico_view.dart` | Recebe `stateOrcamento.orcamentos` via `HomeBase` e filtra `orcamentosAtivos` (linhas 70-76) para o gráfico de orçamentos |
| Testes | `test/util/entity/orcamento_entity_test.dart` | 5 testes de `totalOrcamento` (sem sub-itens concluído/não concluído; com sub-itens nenhum/alguns/todos concluídos). Cubit, Model e UI não têm testes |

## Regras de Negócio Relevantes

- **Valor do orçamento sem sub-itens** — `orcamento_entity.dart:30`: retorna `valor`, ou `0.0` se `concluido`.
- **Valor do orçamento com sub-itens** — `orcamento_entity.dart:31-34`: soma só os sub-itens não concluídos; o `valor` fixo e a flag `concluido` do orçamento são ignorados nesse caso.
- **Total geral = soma dos `totalOrcamento`** — `orcamento_cubit.dart:36-39`: recalculado a cada `buscarOrcamentos()`; não é persistido.
- **Concluir propaga para os sub-itens** — `orcamento_cubit.dart:163-174`: a nova flag é copiada para todos os sub-itens, tanto ao concluir quanto ao reabrir.
- **Orçamento "com sub-itens" grava `valor = 0.0`** — `novo_orcamento_view.dart:81`.
- **Edição pelo formulário não mexe em sub-itens nem em `concluido`** — `novo_orcamento_view.dart:84-90`: `copyWith` só de `nome`, `cor`, `valor`.
- **Sub-item exige nome e valor diferente de zero** — `orcamento_card_widget.dart:636-640` (adicionar) e `:393` (editar).
- **Exclusão de orçamento pelo card pede confirmação; pelo formulário, não** — `orcamento_card_widget.dart:415-444` vs `novo_orcamento_view.dart:128-135`.
- **Banners para usuário free** — `orcamento_view.dart:99-108`: `AdmobBannerWidget` com `AdConfig.homeBanner1` após o card de índice 0 e `AdConfig.homeBanner2` após o de índice 1, somente se `!user.isPlus`.
- **Gráfico só mostra orçamentos ativos** — `grafico_view.dart:70-72`: `!e.concluido && e.totalOrcamento > 0`.

## Dependências Externas

- **`shared_preferences`** — chave `'orcamentos'` (`OrcamentoCubit._campoShared`): `List<String>`, cada item é `json.encode(OrcamentoModel.toJson())` com `id`, `nome`, `cor` (ARGB `int`), `valor`, `concluido`, `sub-itens`.
- **`uuid`** — `Uuid().v4()` para ids de orçamento (`novo_orcamento_view.dart:94`) e de sub-item (`orcamento_card_widget.dart:644`).
- **`flutter_masked_text2`** — `MoneyMaskedTextController` nos campos de valor (formulário, bottom sheet e dialog).
- **`intl`** — `NumberFormat.currency(locale: 'pt_BR', symbol: '')` no card e em `_SubItemRow`.
- **`google_mobile_ads`** — via `AdmobBannerWidget` (`lib/src/util/widgets/admob_banner_widget.dart`).

## Observações

- **Mudanças em relação à versão anterior deste doc:** o toggle de sub-item acontece direto no card (`_SubItemRow`), não dentro do bottom sheet; o bottom sheet fecha após cada adicionar/editar/remover; o "Deletar" da `NovoOrcamentoView` não tem `AlertDialog`; o consumo pela aba Gráficos (filtro próprio) foi incluído. A regra "concluído sem sub-itens vale `0.0`" entrou no commit `7fa6542`, junto com o teste da entity.
- **Tipo "com sub-itens" não é persistido:** criar com esse tipo salva `valor = 0.0` e lista vazia, então o card aparece com R$ 0,00 e, ao reabrir para edição, `_comSubItens` volta a `false` (`novo_orcamento_view.dart:57`), porque é inferido de `subItens.isNotEmpty`.
- **Trocar para "valor fixo" na edição não remove sub-itens:** o `valor` digitado é gravado, mas `totalOrcamento` continua somando os sub-itens e o valor fixo não aparece.
- **`concluido` do orçamento e dos sub-itens podem divergir:** marcar todos os sub-itens um a um não conclui o orçamento; desmarcar ou adicionar um sub-item num orçamento concluído deixa o card riscado como "Orçamento concluído" com valor > 0, contando no total geral, mas fora do gráfico (que filtra por `!concluido`).
- **Risco de update perdido:** `toggleSubItemConcluido`/`adicionarSubItem` partem do `widget.orcamento` em memória e `atualizarOrcamento` substitui o registro inteiro. Dois toques rápidos em sub-itens diferentes antes do rebuild podem fazer o segundo sobrescrever o primeiro. `buscarOrcamentos()` é disparado sem `await` em `salvar/atualizar/remover`.
- **Sem tratamento de erro:** nenhum `try/catch` no Cubit e nenhum estado `Erro`. JSON corrompido em `'orcamentos'` lança exceção em `fromJson` e deixa o estado em `OrcamentoLoading`.
- **Validação de nome inconsistente:** o formulário usa `_nomeOrcamento.isEmpty` sem `trim()` (um nome só com espaços é aceito); sub-itens usam `trim()`.
- **`TextEditingController` criado dentro do `build()`** — `novo_orcamento_view.dart:222`: recriado a cada `setState` (inclusive a cada tecla), com o cursor sempre reposicionado no fim. Os controllers do bottom sheet e do dialog de sub-item também não recebem `dispose`.
- **Rótulos reaproveitados:** o título da seção acima da lista usa `AppStrings.novoOrcamento` ("Novo orçamento", `orcamento_view.dart:70`); o chip e o título do sheet usam `AppStrings.subDividas` (chave `sub-dividas`, que em pt_BR vale "Sub-itens").
- **Moeda fixa no card:** card e `_SubItemRow` montam `'R$ '` + `NumberFormat` pt_BR, independentemente do locale; o header usa a extensão `.real`.
- **Cards sem `key`:** o `ListView.builder` não passa `key` ao `OrcamentoCardWidget`, então o estado local `_expandedSubItens` fica preso à posição, não ao orçamento, quando a lista muda.
- **Ciclo de vida do Cubit:** o `OrcamentoCubit` vive em `_HomeBaseState` e não recebe `close()`; `OrcamentoView` só recebe a instância.
