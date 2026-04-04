---
agent: agent
---

## Tarefa

Analise as alterações do repositório git atual e gere uma mensagem de commit semântica seguindo o padrão **Conventional Commits**.

---

## Passo a Passo

1. Execute `git status` para listar os arquivos modificados, adicionados e removidos.
2. Execute `git diff` (e `git diff --cached` se houver staged) para entender o conteúdo das alterações.
3. Com base nas alterações, gere a mensagem de commit ideal.
4. Execute o commit com `git add -A && git commit -m "<mensagem>"`.

---

## Padrão de Commit (Conventional Commits)

```
<tipo>(<escopo opcional>): <descrição curta em minúsculas>

[corpo opcional — explica o "porquê", não o "o quê"]

[rodapé opcional — BREAKING CHANGE, Refs, etc.]
```

### Tipos disponíveis

| Tipo | Quando usar |
|---|---|
| `feat` | Nova funcionalidade ou tela adicionada |
| `fix` | Correção de bug ou comportamento incorreto |
| `refactor` | Reestruturação de código sem mudar comportamento |
| `style` | Formatação, espaçamento, trailing commas (sem lógica) |
| `chore` | Tarefas de manutenção (deps, configs, scripts) |
| `docs` | Adição ou atualização de documentação |
| `test` | Adição ou correção de testes |
| `perf` | Melhoria de performance |
| `ci` | Mudanças em pipelines de CI/CD |
| `build` | Mudanças no sistema de build ou dependências externas |
| `revert` | Reversão de commit anterior |
| `l10n` | Adição ou atualização de traduções (arb, l10n) |

### Escopo (opcional)

Use o nome da feature, camada ou módulo afetado. Exemplos:
- `feat(auth): add biometric login`
- `fix(home): fix loading state not disappearing`
- `refactor(data): extract datasource from repository`
- `chore(deps): upgrade flutter_bloc to 9.1.1`

### Regras obrigatórias

- ✅ Descrição em **inglês**, **minúsculas**, **imperativo** ("add", "fix", "remove" — não "added", "fixes")
- ✅ Máximo **72 caracteres** na linha de título
- ✅ Sem ponto final na descrição
- ✅ Se houver breaking change: adicione `!` após o tipo ou rodapé `BREAKING CHANGE:`
- ✅ Prefira **um commit por contexto** — não misture feat com fix no mesmo commit

---

## Exemplos de mensagens válidas

```
feat(splash): add animated logo on startup

fix(home): prevent double emit on load error

refactor(auth): extract token logic to AuthService

chore(deps): upgrade go_router to 16.2.4

l10n: add missing pt translations for settings screen

feat(profile)!: change user model structure

BREAKING CHANGE: UserEntity now requires `displayName` field
```

---

## Critérios de decisão

Ao analisar as alterações, use este guia para escolher o tipo:

```
As alterações adicionam uma nova tela, widget ou funcionalidade visível ao usuário?
  └─ SIM → feat

As alterações corrigem um comportamento incorreto ou bug?
  └─ SIM → fix

As alterações reorganizam ou simplificam código sem mudar comportamento?
  └─ SIM → refactor

As alterações afetam apenas formatação/estilo (sem lógica)?
  └─ SIM → style

As alterações são em arquivos .arb, l10n ou traduções?
  └─ SIM → l10n

As alterações são em testes?
  └─ SIM → test

As alterações são em pubspec, configs, scripts ou dependências?
  └─ SIM → chore

As alterações são em documentação?
  └─ SIM → docs
```

---

## Resultado esperado

Após analisar e executar o commit, informe:
- O comando executado
- A mensagem de commit gerada
- Os arquivos incluídos no commit

