---
agent: agent
tools:
  - vscode/askQuestions
---

**IMPORTANTE: Siga este fluxo na ordem exata.**

---

## Detecção de argumento

Verifique se o usuário passou um argumento junto ao comando (ex: `/refactore home`, `/refactore profile`).

- **Se passou argumento** (ex: `home`): o argumento é o nome da feature. Pule a Etapa 1 e vá direto para a Etapa 2, tratando o argumento como o nome da feature a ser refatorada em `lib/presentation/<feature>/`.
- **Se não passou argumento**: execute normalmente a partir da Etapa 1.

---

## Etapa 1 — Perguntar ao usuário (somente se nenhum argumento foi fornecido)

Use a ferramenta `vscode_askQuestions` para perguntar ao usuário qual módulo ele quer refatorar.

Apresente as opções abaixo e peça que ele escolha **uma**:

---

**Qual fluxo você quer refatorar?**

| # | Módulo | Camada | Skill |
|---|---|---|---|
| 1 | **View** | Presentation | `analyze-view` + `implement-view` |
| 2 | **Cubit / State** | Presentation | `implement-view-model` |
| 3 | **Widget** (reutilizável) | Presentation | `implement-widget` |
| 4 | **Entity** | Domain | `implement-domain` |
| 5 | **Repository Interface** | Domain | `implement-domain` |
| 6 | **Model** | Data | `implement-data` |
| 7 | **DataSource** | Data | `implement-data` |
| 8 | **Repository Implementation** | Data | `implement-data` |
| 9 | **Injeção de Dependências (DI)** | Config | `configure-di` |
| 10 | **Navegação / Rotas** | Config | `configure-navigation` |
| 11 | **In-App Purchase** | Common/Services | `implement-in-app-purchase` |
| 12 | **Autenticação / Token Flow** | Common/Services | `implement-auth-token-flow` |
| 13 | **Push Notifications (Firebase)** | Common/Services | `implement-firebase-notifications` |
| 14 | **Outro / Não sei** | — | `architecture.instructions.md` |

> Informe o número ou o nome do módulo. Se quiser, já indique também o arquivo ou feature específica.

---

## Etapa 2 — Descobrir camadas presentes e carregar instruções

### Se o argumento é um nome de feature (ex: `home`)

1. Liste recursivamente o conteúdo de `lib/presentation/<feature>/` para descobrir quais sub-pastas existem.
2. Para cada sub-pasta encontrada, carregue os artefatos correspondentes **antes de tocar em qualquer arquivo**:

| Sub-pasta encontrada | Skills a carregar |
|---|---|
| `view/` | `.github/skills/analyze-view/SKILL.md` + `.github/skills/implement-view/SKILL.md` + `.github/instructions/architecture.instructions.md` |
| `view_model/` | `.github/skills/implement-view-model/SKILL.md` + `.github/instructions/architecture.instructions.md` |
| `widgets/` | `.github/skills/implement-widget/SKILL.md` + `.github/instructions/architecture.instructions.md` |
| `content/` | `.github/skills/implement-view/SKILL.md` + `.github/instructions/architecture.instructions.md` |

3. Verifique também se existem arquivos relacionados à feature nas camadas de domínio e dados:
   - `lib/domain/entities/<feature>*` → carregar `.github/skills/implement-domain/SKILL.md`
   - `lib/domain/interfaces/<feature>*` → carregar `.github/skills/implement-domain/SKILL.md`
   - `lib/data/models/<feature>*` ou `lib/data/datasources/<feature>*` ou `lib/data/repositories/<feature>*` → carregar `.github/skills/implement-data/SKILL.md`

### Se o argumento é um módulo específico (sem ser nome de feature)

Carregue os artefatos da tabela abaixo conforme o módulo escolhido:

| Módulo escolhido | Skills a carregar antes de refatorar |
|---|---|
| View | `.github/skills/analyze-view/SKILL.md` + `.github/skills/implement-view/SKILL.md` + `.github/instructions/architecture.instructions.md` |
| Cubit / State | `.github/skills/implement-view-model/SKILL.md` + `.github/instructions/architecture.instructions.md` |
| Widget | `.github/skills/implement-widget/SKILL.md` + `.github/instructions/architecture.instructions.md` |
| Entity | `.github/skills/implement-domain/SKILL.md` + `.github/instructions/architecture.instructions.md` |
| Repository Interface | `.github/skills/implement-domain/SKILL.md` + `.github/instructions/architecture.instructions.md` |
| Model | `.github/skills/implement-data/SKILL.md` + `.github/instructions/architecture.instructions.md` |
| DataSource | `.github/skills/implement-data/SKILL.md` + `.github/instructions/architecture.instructions.md` |
| Repository Implementation | `.github/skills/implement-data/SKILL.md` + `.github/instructions/architecture.instructions.md` |
| DI | `.github/skills/configure-di/SKILL.md` + `.github/instructions/architecture.instructions.md` |
| Navegação / Rotas | `.github/skills/configure-navigation/SKILL.md` + `.github/instructions/architecture.instructions.md` |
| In-App Purchase | `.github/skills/implement-in-app-purchase/SKILL.md` + `.github/instructions/architecture.instructions.md` |
| Autenticação / Token | `.github/skills/implement-auth-token-flow/SKILL.md` + `.github/instructions/architecture.instructions.md` |
| Push Notifications | `.github/skills/implement-firebase-notifications/SKILL.md` + `.github/instructions/architecture.instructions.md` |
| Outro | `.github/instructions/architecture.instructions.md` |

---

## Etapa 3 — Identificar o alvo da refatoração

Se o argumento foi passado (nome de feature), o alvo já está definido como todos os arquivos dentro de `lib/presentation/<feature>/` e os arquivos de domínio/data correlatos encontrados na Etapa 2. Não pergunte novamente.

Se o usuário não especificou arquivo ou feature exata, pergunte:

> "Qual é o arquivo ou feature que você quer refatorar? (ex: `lib/presentation/home/view/home_view.dart` ou feature `profile`)"

---

## Etapa 4 — Executar a refatoração

1. Leia **todos** os arquivos do escopo identificado antes de modificar qualquer coisa.
2. Quando o escopo é uma feature inteira, refatore as camadas nesta ordem: `domain` → `data` → `view_model` → `view` → `widgets` → `content`.
3. Aplique **apenas** as correções necessárias para conformidade com as instruções carregadas.
4. Não altere arquivos fora do escopo identificado (ex: não mexa no DI global a menos que seja estritamente necessário e o usuário peça).
5. Se a refatoração envolver textos visíveis ao usuário, garanta que estejam em `context.l10n` (nunca hardcoded).
6. Se a refatoração envolver View, rode ao final:
   ```
   flutter gen-l10n
   ```
7. Ao final, liste de forma concisa o que foi alterado e por quê, agrupado por arquivo.

---

## Regras Gerais (sempre aplicáveis)

- Imports SEMPRE absolutos: `package:base_app/...`
- NUNCA crie arquivos `.md` para documentar as mudanças
- NUNCA refatore além do escopo identificado
- SEMPRE aplique `const` onde possível
- SEMPRE use `Result<T>` em repositories
- NUNCA strings hardcoded na UI
