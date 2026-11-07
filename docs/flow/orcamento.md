# Flow: Orçamento

> **Resumo:** O usuário cria, visualiza, edita e conclui orçamentos financeiros (com ou sem sub-itens) na aba "Orçamentos". O total geral exibido reflete em tempo real a soma dos orçamentos ainda não concluídos.

---

## Visão Geral

O fluxo começa quando o app é iniciado: `HomeBase` instancia `OrcamentoCubit` e chama `buscarOrcamentos()` no `initState`, carregando os dados do `SharedPreferences`. A `OrcamentoView` (aba de índice 2 no `IndexedStack`) escuta o Cubit via `BlocBuilder` e renderiza o painel de total animado (`OrcamentoTotalWidget`) e a lista de cards (`OrcamentoCardWidget`).

Para criar um orçamento, o usuário toca no FAB enquanto está na aba 2. O `HomeBase` abre `NovoOrcamentoView` via `Navigator.push`, repassando o mesmo `OrcamentoCubit`. O usuário escolhe o tipo (valor fixo ou com sub-itens), preenche nome, cor e valor, e salva. O Cubit persiste no `SharedPreferences` e recarrega o estado.

Os orçamentos com sub-itens têm seu total calculado somando apenas os sub-itens não concluídos. Os sem sub-itens retornam o `valor` fixo (ou `0.0` se o orçamento estiver concluído). O total geral (`totalGeral`) é a soma de `totalOrcamento` de todos os orçamentos, recalculada a cada escrita no Cubit.

Marcar um orçamento como "Concluído" propaga a flag para todos os sub-itens e chama `atualizarOrcamento()`, fazendo o valor desaparecer do total geral. O toggle reverte o estado da mesma forma. Sub-itens também podem ser concluídos individualmente, reduzindo parcialmente o total.

---

## Passo a Passo

### Inicialização / Carregamento

1. **Shell de navegação** — `lib/src/features/home/view/home_base.dart` → `_HomeBaseState.initState()`
   Instancia `OrcamentoCubit` e chama `buscarOrcamentos()`. Também re-chama ao navegar para a aba 2 via `NavigationBar.onDestinationSelected`.

2. **Cubit** — `lib/src/features/orcamento/cubit/orcamento_cubit.dart` → `buscarOrcamentos()`
   Emite `OrcamentoLoading` (preservando estado atual), lê `prefs.getStringList('orcamentos')`, desserializa cada string JSON via `OrcamentoModel.fromJson()`, faz fold de `o.totalOrcamento` para calcular `totalGeral`, emite `OrcamentoSucesso`.

3. **Model** — `lib/src/util/model/orcamento_model.dart` → `OrcamentoModel.fromJson()`
   Converte `Map<String, dynamic>` em `OrcamentoModel` (extends `OrcamentoEntity`). Lê `sub-itens` (chave com hífen) como lista de `SubItemOrcamentoModel`.

4. **Entity** — `lib/src/util/entity/orcamento_entity.dart` → `OrcamentoEntity.totalOrcamento`
   Getter calculado: sem sub-itens → `concluido ? 0.0 : valor`; com sub-itens → soma dos `s.valor` onde `s.concluido == false`.

5. **View** — `lib/src/features/orcamento/view/orcamento_view.dart` → `BlocBuilder`
   Reconstrói ao receber novo estado. Renderiza `OrcamentoTotalWidget` + `ListView` de `OrcamentoCardWidget` (ou `_EmptyState`).

---

### Criar / Editar Orçamento

6. **Shell** — `home_base.dart` → `_buildFab()` (quando `_selectedIndex == 2`)
   Abre `NovoOrcamentoView(orcamentoCubit: _orcamentoCubit)` via `Navigator.push(MaterialPageRoute)`.
   - *Editar:* `OrcamentoCardWidget` também abre `NovoOrcamentoView(orcamentoCubit: ..., orcamento: widget.orcamento)`.

7. **Form View** — `lib/src/features/novo_orcamento/view/novo_orcamento_view.dart` → `_NovoOrcamentoViewState`
   Em `initState`, se `orcamento != null`, pré-preenche os campos com `WidgetsBinding.addPostFrameCallback`. Toggle "com sub-itens" esconde o campo de valor (salva `0.0` para orçamentos com sub-itens).

8. **Form View** → `_salvar()`
   Valida nome (SnackBar se vazio). Se criando: `cubit.salvarOrcamento(OrcamentoEntity(..., id: Uuid().v4()))`. Se editando: `cubit.atualizarOrcamento(orcamento.copyWith(...))`. Após: `Navigator.pop()`.

9. **Cubit** → `salvarOrcamento()` / `atualizarOrcamento()`
   Emite Loading → lê prefs → acrescenta/substitui JSON codificado via `OrcamentoModel.fromEntity(e).toJson()` → grava → chama `buscarOrcamentos()` para re-emitir estado atualizado.

---

### Concluir / Reabrir Orçamento

10. **Card** — `lib/src/features/orcamento/widgets/orcamento_card_widget.dart` → `_ActionChip` "Concluir"
    Chama `cubit.toggleOrcamentoConcluido(widget.orcamento)`.

11. **Cubit** → `toggleOrcamentoConcluido()`
    Inverte `concluido`. Mapeia todos os sub-itens para o mesmo valor de `concluido`. Chama `atualizarOrcamento()` com o entity atualizado.

12. **Entity** → `totalOrcamento` recalculado
    Orçamento sem sub-itens agora concluído retorna `0.0`; com sub-itens todos concluídos também `0.0`. O `totalGeral` do próximo `buscarOrcamentos()` refletirá a mudança.

---

### Sub-itens

13. **Card** → `_ActionChip` "Sub-itens"
    Abre `_gerenciarSubItensBottomSheet()` com `StatefulBuilder`.

14. **Bottom Sheet** → toggle individual
    Chama `cubit.toggleSubItemConcluido(orcamento, s.id)` → `atualizarOrcamento()` com o sub-item atualizado. O total do card é recalculado via `totalOrcamento`.

15. **Bottom Sheet** → adicionar sub-item
    Cria `SubItemOrcamentoEntity(id: Uuid().v4(), ...)`, chama `cubit.adicionarSubItem()` → `atualizarOrcamento(orcamento.copyWith(subItens: [..., novoSubItem]))`.

16. **Bottom Sheet** → editar sub-item
    Abre `_editarSubItemDialog()` → `cubit.atualizarSubItem()` → `atualizarOrcamento()`.

17. **Bottom Sheet** → remover sub-item
    `cubit.removerSubItem(orcamento, s.id)` → filtra a lista → `atualizarOrcamento()`.

---

### Remover Orçamento

18. **Card** → `_ActionChip` lixeira (ou botão "Deletar" em `NovoOrcamentoView`)
    Confirma em `AlertDialog` → `cubit.removerOrcamento(orcamento)`.

19. **Cubit** → `removerOrcamento()`
    Filtra a lista (`.removeWhere(e.id == orcamento.id)`) → grava → `buscarOrcamentos()`.

---

### Caminhos Alternativos

- **Nome vazio ao salvar:** `NovoOrcamentoView._salvar()` exibe `SnackBar` e retorna sem chamar o Cubit.
- **Valor zerado ao salvar sub-item:** `_gerenciarSubItensBottomSheet` verifica `novoValor == 0.0` e ignora.
- **Lista vazia:** `OrcamentoView` exibe `_EmptyState` (ícone + textos localizados).
- **Scroll:** `OrcamentoView` monitora `ScrollController`; ao passar de 60px, emite `_isCollapsed = true` para `OrcamentoTotalWidget`, que colapsa o header via `AnimationController`.

---

## Arquivos Envolvidos

| Camada | Arquivo | Responsabilidade |
|--------|---------|-----------------|
| Shell / Navegação | `lib/src/features/home/view/home_base.dart` | Instancia e repassa `OrcamentoCubit`; monta `OrcamentoView` no `IndexedStack`; abre `NovoOrcamentoView` no FAB |
| Apresentação | `lib/src/features/orcamento/view/orcamento_view.dart` | Tela principal da aba; `BlocBuilder` → lista de cards ou empty state |
| Apresentação | `lib/src/features/novo_orcamento/view/novo_orcamento_view.dart` | Formulário de criação/edição; sem Cubit próprio |
| Widget | `lib/src/features/orcamento/widgets/orcamento_card_widget.dart` | Card individual com actions (concluir, sub-itens, editar, deletar) |
| Widget | `lib/src/features/orcamento/widgets/orcamento_total_widget.dart` | Header animado com `totalGeral`; colapsa ao rolar |
| Content (form) | `lib/src/features/novo_orcamento/content/novo_orcamento_form_content.dart` | Sub-widgets do formulário: toggle de tipo, preview, hint de sub-itens, section card/label |
| Estado | `lib/src/features/orcamento/cubit/orcamento_cubit.dart` | Toda a lógica: buscar, salvar, atualizar, remover, toggle concluído, operações de sub-item |
| Estado | `lib/src/features/orcamento/cubit/orcamento_state.dart` | `OrcamentoInitial`, `OrcamentoLoading`, `OrcamentoSucesso` — todos com `orcamentos` e `totalGeral` |
| Domínio | `lib/src/util/entity/orcamento_entity.dart` | `OrcamentoEntity` + `SubItemOrcamentoEntity`; getter `totalOrcamento` com regra de negócio |
| Dados | `lib/src/util/model/orcamento_model.dart` | `OrcamentoModel` / `SubItemOrcamentoModel`; serialização JSON; `fromEntity()` / `fromJson()` / `toJson()` |
| Testes | `test/util/entity/orcamento_entity_test.dart` | Testes unitários do getter `totalOrcamento` (5 cenários) |

---

## Regras de Negócio Relevantes

- **`totalOrcamento` sem sub-itens** — `lib/src/util/entity/orcamento_entity.dart:30`: se `concluido == true`, retorna `0.0`; caso contrário retorna `valor`. (Corrigido: antes ignorava `concluido`.)
- **`totalOrcamento` com sub-itens** — `orcamento_entity.dart:31-35`: soma apenas sub-itens onde `concluido == false`; sub-itens concluídos valem `0.0`.
- **Concluir propaga para sub-itens** — `orcamento_cubit.dart:165-166`: `toggleOrcamentoConcluido()` aplica o novo valor de `concluido` a todos os sub-itens antes de salvar.
- **Orçamento com sub-itens salva `valor = 0.0`** — `novo_orcamento_view.dart:81`: `final valor = _comSubItens ? 0.0 : _valorTextController.numberValue`. O valor fixo não é usado quando há sub-itens.
- **Ads condicionais** — `orcamento_view.dart:99-108`: banners AdMob inseridos após os cards de índice 0 e 1 apenas para usuários não-premium (`!user.isPlus`).
- **Total geral** — `orcamento_cubit.dart:36-39`: `totalGeral` é recalculado a cada `buscarOrcamentos()` como fold de `o.totalOrcamento`; não é armazenado separadamente no `SharedPreferences`.

---

## Dependências Externas

- **`shared_preferences`**: chave `'orcamentos'` — `List<String>`, cada item é um `OrcamentoModel.toJson()` codificado em JSON.
- **`uuid`**: geração de IDs para novos orçamentos e sub-itens (`Uuid().v4()`).
- **`flutter_masked_text2`**: `MoneyMaskedTextController` para campo de valor.
- **`google_mobile_ads`** (via `AdmobBannerWidget`): banners exibidos entre cards para usuários free.
- **`UserController`** (`ValueNotifier<UserEntity>`): lido via `ValueListenableBuilder` para decidir exibição de ads.
- **`ThemeController`**: botão de toggle de tema no header `OrcamentoTotalWidget`.

---

## Observações

- **Chave JSON com hífen:** `OrcamentoModel` usa `'sub-itens'` (com hífen) como chave para a lista de sub-itens, não `'subItens'`. Isso é incomum em Dart e pode causar confusão ao estender a serialização.
- **Sem estado de erro:** `OrcamentoCubit` não emite estado de erro — qualquer falha no `SharedPreferences` lançaria exceção não tratada. A feature não tem `OrcamentoErro` state (diferente de outros Cubits do projeto que podem ter).
- **Cubit não é `dispose`d explicitamente na View:** `OrcamentoCubit` é criado em `_HomeBaseState` e vive enquanto o `HomeBase` estiver na árvore. `OrcamentoView` apenas recebe a instância por construtor.
- **`NovoOrcamentoView` usa `TextEditingController` criado inline:** `lib/src/features/novo_orcamento/view/novo_orcamento_view.dart:222` — o `TextEditingController` para o campo de nome é criado dentro do `build()` sem ser armazenado em estado, o que pode causar recriação desnecessária a cada rebuild.
