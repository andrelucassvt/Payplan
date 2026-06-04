---
name: brainstorming
description: You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation.
---

# Brainstorming

## O que esta skill faz

Funciona como a camada de inteligência de contexto antes de qualquer implementação. Antes de criar features, modificar comportamentos ou adicionar funcionalidades:

1. **Explora a intenção** do usuário para garantir entendimento preciso do que precisa ser feito
2. **Lê os flows relevantes** em `./flow/` para entender como o sistema funciona hoje
3. **Detecta a skill `*-expert`** da stack do projeto (flutter-expert, spring-expert, etc.) e aponta as referências relevantes
4. **Produz um briefing de contexto** com o que é necessário saber para implementar com segurança
5. **Ao final do trabalho, garante que flows afetados sejam atualizados** se mudanças estruturais aconteceram

Esta skill é puramente de análise e contexto — não gera planos, não escreve código, não chama outras skills. Após o briefing, o próximo passo fica a critério do usuário.

---

## Fase 1 — Entender a intenção

Antes de buscar qualquer arquivo, fixe mentalmente:

- **O quê?** O que o usuário quer criar, mudar ou adicionar?
- **Por quê?** Qual problema ou objetivo isso resolve?
- **Onde?** Quais features, telas ou camadas são afetadas?
- **Impacto?** O que muda no comportamento existente? O que permanece igual?

Se o pedido for ambíguo ou tiver múltiplas interpretações possíveis, faça **uma única pergunta de clarificação** — a mais importante para desbloquear o entendimento. Não pergunte o que você pode inferir do código.

---

## Fase 2 — Carregar contexto dos flows

Verifique se existe documentação em `./flow/`:

```bash
ls ./flow/ 2>/dev/null
```

### Se não existir a pasta `./flow/` ou estiver vazia

Continue para o Fase 3 sem contexto documental. Mencione ao usuário no briefing que não há flows documentados e sugira `/flow-init` para criar uma base documental do projeto — mas não bloqueie o trabalho por isso.

### Se existir

Identifique quais flows são relevantes para o pedido do usuário:

- Mapeie as palavras-chave do pedido (ex: "login", "perfil", "pagamento", "notificação")
- Verifique os nomes dos arquivos em `./flow/` — prefira `project-structure.md` para contexto geral, e flows específicos para features afetadas
- Leia os flows relevantes **na íntegra** — não pule seções

**O que extrair de cada flow lido:**

| Informação | Para que serve |
|---|---|
| Arquivos envolvidos (tabela do flow) | Saber exatamente onde mexer |
| Passo a Passo (ordem de execução) | Não quebrar o fluxo existente |
| Regras de Negócio | Não violar contratos existentes |
| Observações / pontos frágeis | Evitar bugs conhecidos |
| Dependências Externas | Saber quais integrações são afetadas |

Se o pedido afeta múltiplas features e cada uma tem flow, leia todos.

---

## Fase 2.5 — Detectar skill de especialista da linguagem

Cada projeto pode ter uma skill `*-expert` (ex: `flutter-expert`, `spring-expert`, `react-expert`, `node-expert`) com as boas práticas e arquitetura de referência da stack. Antes do briefing, descubra se existe alguma:

```bash
ls -d .claude/skills/*-expert 2>/dev/null
```

### Se encontrar uma ou mais

- Leia o `SKILL.md` de cada uma encontrada (apenas o SKILL.md — **não** leia os arquivos em `references/`, isso é responsabilidade da fase de implementação)
- Extraia: qual é a stack, qual a arquitetura proposta, e a tabela de "quando ler cada referência" (se houver)
- No briefing, na seção **Boas Práticas Disponíveis**, liste o nome da skill e aponte quais arquivos de referência são relevantes para o pedido atual

### Se não encontrar nenhuma

Omita a seção **Boas Práticas Disponíveis** do briefing. Não bloqueie o trabalho — siga apenas com o `CLAUDE.md` e os flows.

### Regra de uso

A brainstorming **identifica e referencia** a skill expert — não invoca, não copia código, não duplica regras. A leitura das references da skill expert deve acontecer na fase de implementação (writing-plan, geração de código, etc.), guiada pelo briefing.

---

## Fase 3 — Briefing de contexto

Após entender a intenção e ler os flows, apresente ao usuário um briefing estruturado:

```
## Entendimento do Pedido
[Uma frase descrevendo o que você entendeu que precisa ser feito]

## Contexto Carregado
- Flows lidos: [lista dos arquivos lidos, ou "nenhum — ./flow/ não existe"]
- Features afetadas: [lista]
- Arquivos-chave envolvidos: [caminhos reais encontrados nos flows]

## Boas Práticas Disponíveis
[Omita esta seção inteira se nenhuma skill *-expert foi encontrada.
Caso contrário:]
- Skill: `<nome-expert>` — stack <linguagem/framework>
- Referências relevantes para este pedido:
  - `references/<arquivo>.md` — [motivo, ex: "criar View"]
  - `references/<arquivo>.md` — [motivo]
- Consulte esta skill antes de implementar para não violar a arquitetura de referência.

## O que já existe
[2–4 frases descrevendo como a feature funciona hoje, com base nos flows.
Se não houver flows, escreva "Nenhuma documentação disponível — análise baseada no código."]

## Pontos de Atenção
[Lista de conflitos, regras de negócio que podem ser afetadas, dependências surpresa,
ou avisos encontrados nas Observações dos flows.
Inclua aqui qualquer API, widget, pacote ou padrão deprecated que o pedido possa envolver —
informe o substituto correto e o motivo. Se não houver nada relevante, omita.]

## Flows a Revisitar Após Implementação
- `flow/<nome>.md` — revisitar se [quais seções podem mudar com as mudanças planejadas]
- (ou: "Nenhum — não há flows documentados para as features afetadas")

## Próximos Passos Sugeridos
[Sugestão breve do caminho natural: ex: "Use /writing-plan para montar o plano antes de implementar,
consultando `<nome-expert>` para os padrões da camada"
ou "Feature simples — pode implementar diretamente seguindo o CLAUDE.md e `<nome-expert>`"]
```

O briefing deve ser conciso. Não repita informações dos flows palavra por palavra — sintetize o que é relevante para o pedido atual.

---

## Fase 4 — Após a implementação: atualizar flows afetados

Esta fase acontece **depois que o trabalho for concluído**, antes de declarar a tarefa completa.

### Quando atualizar um flow

Atualize se qualquer um destes aconteceu:

- Novos arquivos foram criados em uma feature que já tem flow documentado
- Responsabilidade de uma camada mudou (ex: lógica movida do Cubit para um Service)
- Ordem de execução do fluxo mudou
- Novas regras de negócio foram adicionadas
- Arquivos foram movidos, renomeados ou removidos
- Novas dependências externas foram adicionadas ao fluxo

### Quando NÃO atualizar

Não atualize se:

- Mudança foi puramente interna sem impacto na estrutura (ex: renomear variável local, extrair método privado)
- Correção de bug que mantém exatamente o mesmo comportamento observável
- Mudança de UI sem impacto em estado, domínio ou dados

### Como atualizar

Use a skill `flow` para regenerar o flow completo, ou edite diretamente o `./flow/<feature>.md` seguindo o template e as regras de qualidade definidos nela. Não duplique a lógica de documentação aqui — a skill `flow` é a fonte de verdade sobre como escrever e atualizar flows.

### Informe o usuário

Ao final, mencione quais flows foram atualizados e o que mudou em cada um. Se nenhum flow precisou ser atualizado, não mencione esta etapa.

---

## Regras Gerais

**Seja preciso** — cite apenas arquivos que você encontrou nos flows ou no código. Não invente caminhos.

**Não bloqueie** — se não houver flows ou se os flows não cobrirem a feature pedida, o briefing ainda tem valor (entendimento da intenção + sugestão de próximo passo). Nunca impeça o trabalho por falta de documentação.

**Não duplique** — se a informação já está clara nos flows, referencie em vez de transcrever. O briefing é uma síntese, não uma cópia.

**Idioma** — use o mesmo idioma da conversa com o usuário.

**Nada deprecated** — durante o briefing e durante qualquer sugestão de implementação, nunca indique APIs, widgets, pacotes, padrões ou flags marcados como deprecated na versão atual da stack. Se o pedido do usuário envolver algo deprecated (ex: `withOpacity` em Flutter, `WillPopScope`, classes removidas de pacotes), aponte o substituto correto nos **Pontos de Atenção** antes de prosseguir. A mesma regra vale para versões de pacotes: não sugira versões antigas quando existe uma estável mais recente.
