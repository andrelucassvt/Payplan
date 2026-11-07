# Sugestões de Flows a Documentar

> Gerado em 2026-06-04. Execute `/flow <nome>` para criar qualquer um destes flows.

## Flows Sugeridos

### Home / Listagem de Dívidas
**Arquivo a criar:** `flow/home.md`
**Resumo:** Como a tela inicial carrega dívidas do mês a partir do `SharedPreferences`, calcula totais (gastos x salário fixo), troca mês/ano e verifica nova versão via GitHub. Cobre `HomeBase` → `HomeCubit` → `SharedPreferences` e o shell de navegação (`IndexedStack` + `NavigationBar`).

---

### Nova Dívida
**Arquivo a criar:** `flow/nova-divida.md`
**Resumo:** Fluxo do formulário de cadastro de dívida, do `Navigator.push` no FAB da Home até `HomeCubit.salvarDivida`, serialização via `DividaModel` e refresh da lista. Inclui sub-dívidas e faturas mensais.

---

### Devedores
**Arquivo a criar:** `flow/devedores.md`
**Resumo:** CRUD de devedores (adicionar/editar/deletar), toggle de parcelas pagas e compartilhamento de cobrança. Percorre `DevedoresView` → `DevedoresCubit` → `SharedPreferences` (`DevedoresEntity`).

---

### Orçamento
**Arquivo a criar:** `flow/orcamento.md`
**Resumo:** CRUD de orçamentos com sub-itens, marcação de concluído (item e orçamento inteiro) e cálculo do total geral. Cobre `OrcamentoView`/`NovoOrcamentoView` → `OrcamentoCubit` → `SharedPreferences`.

---

### Gráficos
**Arquivo a criar:** `flow/grafico.md`
**Resumo:** Como `GraficosView` combina dados de dívidas, devedores e orçamentos (via `BlocBuilder` aninhados em `HomeBase`) para renderizar com `fl_chart`, e o fluxo de screenshot + compartilhamento (`screenshot` + `share_plus`).

---

### Plano Premium (Plus)
**Arquivo a criar:** `flow/plus.md`
**Resumo:** Fluxo de compra in-app: carregamento de produtos, compra, restauração e atualização do `UserController` (status premium) via `PlusCubit` + `InAppPurchaseService` e o `purchaseStream`.

---

### Anúncios (AdMob)
**Arquivo a criar:** `flow/ads.md`
**Resumo:** Inicialização do SDK (`AdService`), App Open Ad (`AppOpenAdService`), IDs centralizados (`AdConfig`) e onde os banners/native ads são exibidos. Como o status premium do `UserController` afeta a exibição de anúncios.

## Já documentados

- `flow/project-structure.md` — Estrutura geral do projeto
