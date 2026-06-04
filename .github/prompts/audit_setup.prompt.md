---
agent: agent
description: Audita os arquivos de configuração do agente (CLAUDE.md, AGENTS.md, copilot-instructions.md, skills e roles) e entrega um relatório com score de assertividade, gaps críticos e plano de ação.
---

Você é um especialista em configuração de agentes de IA. Sua tarefa é auditar os arquivos de setup deste projeto e produzir um relatório completo de assertividade.

## Passo 1 — Mapear os arquivos existentes

Execute os comandos abaixo para inventariar tudo:

```bash
# CLAUDE.md raiz e subpastas
find . -name "CLAUDE.md" | sort

# AGENTS.md e copilot-instructions.md
find . -name "AGENTS.md" | sort
find . -path "*/.github/copilot-instructions.md" | sort

# Skills (todos os agentes)
ls .claude/skills/ 2>/dev/null
ls .agents/skills/ 2>/dev/null
ls .github/skills/ 2>/dev/null
ls /mnt/skills/user/ 2>/dev/null

# Roles
find . -name "*.role.md" -o -name "roles.md" 2>/dev/null
find .claude/ -type f -name "*.md" 2>/dev/null | grep -i role
```

## Passo 2 — Ler e avaliar cada arquivo

Leia cada arquivo encontrado e avalie contra os critérios abaixo.

### Critérios para CLAUDE.md

**Positivos (+1 cada):**
- Tem seção de contexto do projeto (o que é, stack, objetivo)
- Tem seção de convenções de código (naming, estrutura de pastas)
- Tem exemplos negativos explícitos ("nunca faça X", "evite Y")
- Tem seção de comandos frequentes (build, test, run)
- Usa headers `##` para organizar seções
- Tem menos de 400 linhas por arquivo
- Menciona estilo de output esperado (formato, idioma, tom)

**Negativos (alerta):**
- Apenas instruções positivas, sem contraexemplos
- Instruções vagas sem definição concreta
- Um único CLAUDE.md gigante sem hierarquia por pasta
- Instruções duplicadas que já existem em skills

### Critérios para AGENTS.md e copilot-instructions.md

**Positivos (+1 cada):**
- Alinhado com o CLAUDE.md raiz (sem contradições)
- Referencia as mesmas skills com paths corretos para cada agente
- Tem seção de contexto do projeto
- Tem tabela de skills atualizada
- Tem regras globais resumidas

**Negativos (alerta):**
- Ausente (outros agentes operam sem contexto)
- Desatualizado em relação ao CLAUDE.md
- Duplica verbatim o CLAUDE.md sem adaptar os paths

### Critérios para Skills

**Positivos (+1 cada):**
- Tem seção `## Input esperado`
- Tem seção `## O que fazer` (passo a passo)
- Tem seção `## Formato do output`
- Tem pelo menos 1 exemplo de uso concreto
- Tem exemplos negativos / seção "Nunca faça"
- O `description` no frontmatter tem MANDATORY TRIGGERS explícitos
- Uma skill = uma responsabilidade

**Negativos (alerta):**
- Skill sem frontmatter `name` / `description`
- Description vaga sem triggers explícitos
- Skill sem exemplo de uso
- Skill que mistura 2+ responsabilidades
- Ausência de checklist final

### Critérios para Roles

**Positivos (+1 cada):**
- Nome e objetivo claro na primeira linha
- Define tom e estilo de comunicação
- Define o que NÃO fazer dentro do contexto
- Tem trigger explícito de ativação
- Tem exemplos de comportamento esperado vs errado

**Negativos (alerta):**
- Apenas "seja um especialista em X" sem detalhar comportamento
- Sem exemplos de output
- Contradiz o CLAUDE.md raiz

## Passo 3 — Calcular score

```
Score CLAUDE.md            = (critérios positivos atendidos / 7) × 10
Score AGENTS.md/copilot    = média dos scores dos arquivos encontrados (⚪ se ausentes)
Score Skills               = média dos scores individuais de cada skill
Score Roles                = média dos scores individuais de cada role (⚪ se ausentes)

Fórmula (todos presentes):  (CLAUDE.md × 0.35) + (AGENTS × 0.15) + (Skills × 0.35) + (Roles × 0.15)
Fórmula (sem Roles):        (CLAUDE.md × 0.40) + (AGENTS × 0.20) + (Skills × 0.40)
Fórmula (sem AGENTS+Roles): (CLAUDE.md × 0.50) + (Skills × 0.50)
```

Use a fórmula correspondente ao que o projeto realmente tem — não penalize por ausência de componentes opcionais.

## Passo 4 — Gerar o relatório

Use exatamente este formato:

```markdown
# Auditoria de Setup — Agente de IA
Data: [data atual]
Projeto: [nome inferido]

## Score Geral: [X.X]/10

| Componente            | Score | Status |
|-----------------------|-------|--------|
| CLAUDE.md             | X/10  | 🟢/🟡/🔴    |
| AGENTS.md / Copilot   | X/10  | 🟢/🟡/🔴/⚪ |
| Skills                | X/10  | 🟢/🟡/🔴    |
| Roles                 | X/10  | 🟢/🟡/🔴/⚪ |

🟢 = 8–10 | 🟡 = 5–7 | 🔴 = 0–4 | ⚪ = Ausente (não penaliza)
Fórmula usada: [indicar qual das três]

---

## CLAUDE.md

### Arquivos encontrados
- `./CLAUDE.md` (X linhas)

### Pontos fortes
- ...

### Gaps críticos
- ...

### Anti-patterns encontrados
- ...

### Ações recomendadas
1. [ação] — Impacto: alto | Esforço: baixo

---

## AGENTS.md / copilot-instructions.md

### Arquivos encontrados
- ...

### Pontos fortes / Gaps / Ações
...

---

## Skills

### Skills encontradas
- `nome-da-skill` — [o que faz em 1 linha]

### Análise por skill

#### [nome-da-skill]
- Score: X/10
- Pontos fortes: ...
- Gaps: ...
- Ação: ...

---

## Roles
[Se ausentes, indicar ⚪ Ausente e passar para o próximo bloco]

---

## Plano de ação consolidado

### Esta semana (alto impacto, baixo esforço)
1. [ação concreta com arquivo e seção a editar]

### Próximas 2 semanas
1. ...

### Backlog
1. ...

---

## Exemplo de correção para o gap mais crítico

[Trecho concreto — before/after do ponto mais urgente]
```

## Regras obrigatórias

- **Não invente arquivos** — se não apareceu no mapeamento, não existe.
- **Não sugira reescrever tudo** — melhorias incrementais e cirúrgicas.
- **Todo gap crítico deve ter exemplo concreto** de como ficaria corrigido.
- **Score acima de 8** → aponte os 2 refinamentos mais sutis disponíveis.
- **Componentes ausentes** → marque ⚪, sinalize como oportunidade, não como falha.

## Checklist antes de entregar

- [ ] Todos os arquivos do Passo 1 foram lidos (não apenas listados)
- [ ] Todo componente ausente está marcado como ⚪ e não penaliza o score
- [ ] Cada gap crítico tem exemplo concreto de correção
- [ ] O plano de ação tem pelo menos 1 item "esta semana" com arquivo e seção específicos
- [ ] Ao final, perguntar: "Quer que eu aplique alguma das melhorias agora?"
