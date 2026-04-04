---
agent: agent
---

**IMPORTANTE: Antes de iniciar qualquer tarefa, você DEVE:**

1. Carregar a skill `analyze-view` (`.github/skills/analyze-view/SKILL.md`) e seguir seu escopo completo de análise.

2. Ler `.github/instructions/architecture.instructions.md` para entender a arquitetura geral do projeto (Clean Architecture + BLoC, padrões de nomenclatura, estrutura de pastas, convenções de código e anti-patterns).

3. Carregar as skills `.github/skills/implement-view/SKILL.md`, `.github/skills/implement-widget/SKILL.md` e `.github/skills/implement-view-model/SKILL.md` para as regras específicas de cada camada.

4. Após ler as instruções, execute a tarefa seguindo rigorosamente as diretrizes estabelecidas.

5. Sempre no final da tarefa, rode o comando "flutter gen-l10n" para garantir que todas as localizações estejam atualizadas.

---

## Tarefa

Analise a view fornecida (arquivo ou trecho) e verifique se ela esta conforme as instrucoes. Se nao estiver, liste as nao conformidades e apresente as correcoes necessarias.

### Escopo minimo da analise

#### Estrutura e Arquitetura
- Estrutura e pasta corretas para a view.
- Uso de `StatefulWidget` e ciclo de vida (`initState`, `dispose`).
- DI via `AppInjector`, `BlocProvider.value`, `BlocBuilder` (ou `BlocConsumer`/`BlocListener` quando aplicavel).
- Tratamento de todos os estados (Initial, Loading, Loaded, Error).
- Ausencia de logica de negocio, chamadas HTTP diretas e imports relativos.

#### Internacionalização
- Uso de `context.l10n` para textos visiveis (sem strings hardcoded).

#### Performance: Widgets Privados
- **Verificar ausência de métodos privados que retornam Widget** dentro da View:
  - ❌ `Widget _buildXxx(...)` → deve ser extraído para classe Widget em `widgets/`
  - ❌ `Widget _createXxx(...)` → deve ser extraído para classe Widget em `widgets/`
  - ❌ `List<Widget> _buildXxxItems(...)` → deve ser extraído para classe Widget em `widgets/`
  - ✅ `void _showXxxDialog()` → OK (abre dialog, não retorna widget na árvore)
  - ✅ `void _showXxxBottomSheet()` → OK (abre bottomSheet)
  - ✅ `void _onTapXxx()` / `void _handleXxx()` → OK (event handlers)

#### Layout: SafeArea
- **Verificar uso de `SafeArea`** para proteger conteúdo contra áreas do sistema (notch, barra de status, home indicator):
  - Scaffold **com** AppBar → `SafeArea` no `body` com `top: false` (AppBar já protege o topo)
  - Scaffold **sem** AppBar → `SafeArea` envolvendo o `body` completo
  - Tela fullscreen → `SafeArea` envolvendo conteúdo principal
  - Modal/BottomSheet → `SafeArea` no conteúdo (especialmente `bottom: true`)

### Saida esperada

Para cada arquivo analisado, reporte usando o formato:

```
### <nome_do_arquivo>.dart

#### Conformidades ✅
- [✅] StatefulWidget com ciclo de vida correto
- [✅] DI via AppInjector
- ...

#### Não Conformidades ❌
- [❌] Linha XX: `Widget _buildHeader(...)` → extrair para `widgets/feature_header.dart`
- [❌] Linha YY: body sem SafeArea
- ...
```

Ao final, apresente um resumo:
- Total de Views analisadas
- Total de não conformidades encontradas
- Total de Views 100% em conformidade

### Ação

Após o relatório, **corrija automaticamente** todas as não conformidades encontradas:
- Extraia widgets privados para a pasta `widgets/` da feature
- Adicione `SafeArea` onde necessário
- Corrija imports (sempre absolutos `package:base_app/...`)
- Corrija internacionalização (use `context.l10n`)
- Siga as regras das skills `implement-view` e `implement-widget`
