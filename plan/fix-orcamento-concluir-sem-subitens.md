# Fix — Orçamento concluído sem sub-itens não subtrai do total

> **Objetivo:** Garantir que marcar um orçamento como concluído subtraia seu valor do total geral, com ou sem sub-itens.

## Contexto

Na tab de **Orçamento**, ao clicar em "Concluir" em um orçamento **sem sub-itens**, o valor continua somando no total geral — comportamento errado. Quando o orçamento **tem sub-itens**, concluir funciona (o valor some do total). A causa é o getter `OrcamentoEntity.totalOrcamento`, que ignora a flag `concluido` no ramo sem sub-itens.

## Causa-raiz

`lib/src/util/entity/orcamento_entity.dart` (linhas 29–35):

```dart
double get totalOrcamento {
  if (subItens.isEmpty) return valor;   // ⬅️ ignora `concluido`
  return subItens.fold(
    0.0,
    (soma, s) => soma + (s.concluido ? 0.0 : s.valor),
  );
}
```

- **Sem sub-itens:** retorna `valor` sempre, mesmo com `concluido == true`.
- **Com sub-itens:** `toggleOrcamentoConcluido` (`orcamento_cubit.dart:163`) marca todos os sub-itens como concluídos → cada um vira `0.0` → total `0` → some do `totalGeral`.

O `totalGeral` é calculado em `OrcamentoCubit.buscarOrcamentos` somando `o.totalOrcamento` de cada orçamento (`orcamento_cubit.dart:36-39`). Corrigir o getter conserta o total exibido em `orcamento_total_widget.dart` e o valor mostrado no card.

## Arquitetura / Escopo

| Arquivo | Ação | Responsabilidade |
|---------|------|-----------------|
| `lib/src/util/entity/orcamento_entity.dart` | editar | Ajustar `totalOrcamento` para respeitar `concluido` quando `subItens` está vazio |
| `test/util/entity/orcamento_entity_test.dart` | criar | Primeiro teste unitário do projeto, cobrindo o contrato de `totalOrcamento` |
| `pubspec.yaml` | verificar/editar | Garantir `flutter_test` em `dev_dependencies` (provavelmente já presente) |

**Comportamento esperado de `totalOrcamento` após o fix:**

| Cenário | Esperado |
|---------|----------|
| Sem sub-itens, `concluido == false` | `valor` |
| Sem sub-itens, `concluido == true` | `0.0` |
| Com sub-itens, nenhum concluído | soma de todos os `valor` |
| Com sub-itens, alguns concluídos | soma apenas dos não concluídos |
| Com sub-itens, todos concluídos | `0.0` |

## Fases

### Fase 1 — Testes (contrato antes da implementação)

> Os testes do cenário "sem sub-itens + concluído" devem **falhar** inicialmente (retorna `valor` em vez de `0.0`). Isso confirma que o teste captura o bug.

- [ ] Verificar `pubspec.yaml`: `flutter_test` deve estar em `dev_dependencies` (sdk: flutter). Se não estiver, adicionar.
- [ ] Criar `test/util/entity/orcamento_entity_test.dart` com `group('OrcamentoEntity.totalOrcamento', ...)`.
- [ ] Teste: sem sub-itens e `concluido == false` → `totalOrcamento == valor`.
- [ ] Teste: sem sub-itens e `concluido == true` → `totalOrcamento == 0.0` (**falha esperada antes do fix**).
- [ ] Teste: com sub-itens, nenhum concluído → soma de todos os valores.
- [ ] Teste: com sub-itens, parte concluída → soma apenas dos não concluídos.
- [ ] Teste: com sub-itens, todos concluídos → `0.0`.
- [ ] Verificação: `flutter test test/util/entity/orcamento_entity_test.dart` roda; falha **apenas** no caso "sem sub-itens + concluído" (não por erro de import/sintaxe).

### Fase 2 — Implementação (fazer os testes passarem)

- [ ] Em `lib/src/util/entity/orcamento_entity.dart`, alterar o ramo sem sub-itens:
  ```dart
  if (subItens.isEmpty) return concluido ? 0.0 : valor;
  ```
- [ ] Atualizar o doc-comment do getter para refletir que orçamento concluído sem sub-itens vale `0.0`.
- [ ] Verificação: `flutter test test/util/entity/orcamento_entity_test.dart` → todos passam.
- [ ] Verificação: `flutter analyze` sem novos warnings/erros.

### Fase 3 — Validação manual na UI

- [ ] `flutter run`: criar um orçamento **sem sub-itens** com valor, observar o total geral em `orcamento_total_widget`.
- [ ] Clicar em "Concluir" → o valor deve sair do total geral e o card mostrar valor riscado (`lineThrough`).
- [ ] Clicar novamente (reabrir/`toggle`) → o valor deve voltar ao total geral.
- [ ] Repetir com orçamento **com sub-itens** para confirmar que o comportamento anterior continua correto (não houve regressão).

## Critérios de Sucesso

- [ ] Concluir orçamento sem sub-itens subtrai o valor do total geral.
- [ ] Reabrir (toggle off) restaura o valor no total geral.
- [ ] Orçamento com sub-itens continua funcionando como antes.
- [ ] Card exibe valor riscado quando concluído (já existente, sem regressão).
- [ ] Build sem erros (`flutter analyze` limpo).
- [ ] Todos os testes unitários passando (`flutter test`).

## Riscos e Mitigações

| Risco | Probabilidade | Mitigação |
|-------|--------------|-----------|
| Introduzir o diretório `test/` quebrar config de CI/build | Baixa | É só um diretório padrão Flutter; não afeta build de app. Rodar `flutter analyze` e `flutter build` localmente. |
| Outros consumidores de `totalOrcamento` dependerem do comportamento antigo | Baixa | Buscar usos do getter (`grep totalOrcamento`); hoje só `buscarOrcamentos` e `orcamento_card_widget`, ambos se beneficiam do fix. |
| Persistência: orçamentos já salvos com `concluido == true` sem sub-itens | Baixa | O fix recalcula on-the-fly a partir do estado persistido; ao recarregar, o total já fica correto sem migração. |

## Rollback

Reverter a linha alterada em `orcamento_entity.dart` para `if (subItens.isEmpty) return valor;` e remover o arquivo de teste. Sem migração de dados envolvida.

## Após a Implementação

> Perguntar ao usuário: "Deseja criar um flow dessa funcionalidade em `./flow/`? Ele documenta o caminho completo do fluxo (UI → Cubit → Repository → DataSource) e serve de referência para futuros planos e revisões."
