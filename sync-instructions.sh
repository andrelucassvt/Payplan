#!/usr/bin/env bash
# sync-instructions.sh
# Sincroniza as instruções de IA do repositório central para este projeto.
#
# Uso:
#   chmod +x sync-instructions.sh
#   ./sync-instructions.sh
#
# Coloque este script na raiz de cada projeto Flutter.
# Pode ser chamado manualmente ou via git hook / CI.

set -euo pipefail

# ============================================================
# CONFIGURAÇÃO — ajuste estas variáveis
# ============================================================

# URL do repositório de instruções (SSH ou HTTPS)
SOURCE_REPO="git@github.com:ANL-Software/flutter-instructions-ia.git"
# Branch de referência
SOURCE_BRANCH="main"

# ── Brain Flows (agentes) ──────────────────────────────────
BRAIN_SOURCE_REPO="${BRAIN_SOURCE_REPO:-https://github.com/andrelucassvt/brain-flows.git}"
BRAIN_SOURCE_BRANCH="${BRAIN_SOURCE_BRANCH:-main}"
BRAIN_SOURCE_AGENTS_PATH="${BRAIN_SOURCE_AGENTS_PATH:-.claude/agents}"
BRAIN_AGENTS=(brain-agent-loop brain-agent-loop-exec brain-goal)
BRAIN_NATIVE_AGENTS=(.opencode/agents/brain-goal.md .codex/agents/brain-goal.toml)

# ============================================================
# NÃO EDITE ABAIXO (a menos que saiba o que está fazendo)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR=$(mktemp -d)
BRAIN_TMP_DIR=$(mktemp -d)

cleanup() {
  rm -rf "$TMP_DIR" "$BRAIN_TMP_DIR"
}
trap cleanup EXIT

echo "⬇️  Clonando instruções mais recentes..."
git clone --depth 1 --branch "$SOURCE_BRANCH" "$SOURCE_REPO" "$TMP_DIR" --quiet

# ── Arquivos raiz ──────────────────────────────────────────
echo "📄 Sincronizando arquivos raiz..."

if [ ! -f "$SCRIPT_DIR/AGENTS.md" ]; then
  cp "$TMP_DIR/AGENTS.md" "$SCRIPT_DIR/AGENTS.md"
  echo "  ✅ AGENTS.md criado."
else
  echo "  ⏭️  AGENTS.md já existe. Pulando (rode setup-project-context para personalizar)."
fi

if [ ! -f "$SCRIPT_DIR/CLAUDE.md" ]; then
  cp "$TMP_DIR/CLAUDE.md" "$SCRIPT_DIR/CLAUDE.md"
  echo "  ✅ CLAUDE.md criado."
else
  echo "  ⏭️  CLAUDE.md já existe. Pulando (rode setup-project-context para personalizar)."
fi

if [ ! -f "$SCRIPT_DIR/.github/copilot-instructions.md" ]; then
  mkdir -p "$SCRIPT_DIR/.github"
  cp "$TMP_DIR/.github/copilot-instructions.md" "$SCRIPT_DIR/.github/copilot-instructions.md"
  echo "  ✅ .github/copilot-instructions.md criado."
else
  echo "  ⏭️  .github/copilot-instructions.md já existe. Pulando (rode setup-project-context para personalizar)."
fi

# ── SDK: Claude ────────────────────────────────────────────
if [ -d "$TMP_DIR/.claude/skills" ]; then
  echo "📁 Sincronizando .claude/skills/..."
  mkdir -p "$SCRIPT_DIR/.claude/skills"
  rsync -a --delete "$TMP_DIR/.claude/skills/" "$SCRIPT_DIR/.claude/skills/"
else
  echo "⏭️  .claude/skills/ não encontrado no repositório fonte. Pulando."
fi

# ── SDK: GitHub Copilot ────────────────────────────────────
if [ -d "$TMP_DIR/.claude/skills" ]; then
  echo "📁 Sincronizando .github/skills/..."
  mkdir -p "$SCRIPT_DIR/.github/skills"
  rsync -a --delete "$TMP_DIR/.claude/skills/" "$SCRIPT_DIR/.github/skills/"
else
  echo "⏭️  .claude/skills/ não encontrado. Pulando .github/skills/."
fi

# ── SDK: Codex / Agents ────────────────────────────────────
if [ -d "$TMP_DIR/.claude/skills" ]; then
  echo "📁 Sincronizando .agents/skills/..."
  mkdir -p "$SCRIPT_DIR/.agents/skills"
  rsync -a --delete "$TMP_DIR/.claude/skills/" "$SCRIPT_DIR/.agents/skills/"
else
  echo "⏭️  .claude/skills/ não encontrado. Pulando .agents/skills/."
fi

# ── Brain Flows Agents ─────────────────────────────────────
echo "🤖 Sincronizando agentes do Brain Flows..."
git clone --depth 1 --branch "$BRAIN_SOURCE_BRANCH" "$BRAIN_SOURCE_REPO" "$BRAIN_TMP_DIR" --quiet || {
  echo "  ⚠️  Falha ao clonar $BRAIN_SOURCE_REPO. Agentes do Brain Flows não foram sincronizados."
}
if [ -d "$BRAIN_TMP_DIR/$BRAIN_SOURCE_AGENTS_PATH" ]; then
  mkdir -p "$SCRIPT_DIR/.claude/agents"
  for agent in "${BRAIN_AGENTS[@]}"; do
    source_agent_file="$BRAIN_TMP_DIR/$BRAIN_SOURCE_AGENTS_PATH/$agent.md"
    if [ ! -f "$source_agent_file" ]; then
      echo "  ⚠️  Agente ausente no repositório fonte: $BRAIN_SOURCE_AGENTS_PATH/$agent.md" >&2
    else
      cp "$source_agent_file" "$SCRIPT_DIR/.claude/agents/$agent.md"
      echo "  ✅ $agent"
    fi
  done
else
  echo "  ⚠️  $BRAIN_SOURCE_AGENTS_PATH/ não encontrado no repositório fonte. Agentes não sincronizados."
fi

# ── Brain Flows Agentes Nativos ────────────────────────────
for native_agent in "${BRAIN_NATIVE_AGENTS[@]}"; do
  source_native_file="$BRAIN_TMP_DIR/$native_agent"
  if [ -f "$source_native_file" ]; then
    mkdir -p "$SCRIPT_DIR/$(dirname "$native_agent")"
    cp "$source_native_file" "$SCRIPT_DIR/$native_agent"
    echo "  ✅ $(basename "$native_agent")"
  fi
done

# ── Auto-update do próprio script ─────────────────────────
if [ -f "$TMP_DIR/sync-instructions.sh" ]; then
  echo "🔄 Atualizando sync-instructions.sh..."
  cp "$TMP_DIR/sync-instructions.sh" "$SCRIPT_DIR/sync-instructions.sh"
  chmod +x "$SCRIPT_DIR/sync-instructions.sh"
fi

echo ""
echo "✅ Instruções sincronizadas com sucesso!"
echo ""
echo "Arquivos atualizados:"
echo "  • .claude/skills/              (sempre sincronizado — fonte das skills)"
echo "  • .github/skills/              (espelho para GitHub Copilot)"
echo "  • .agents/skills/              (espelho para Codex / OpenAI Agents)"
echo "  • AGENTS.md / CLAUDE.md / .github/copilot-instructions.md"
echo "    (criados apenas se não existiam)"
echo ""
echo "💡 Para personalizar os arquivos de entrada (CLAUDE.md, AGENTS.md,"
echo "   copilot-instructions.md) com contexto específico deste projeto,"
echo "   execute o skill setup-project-context."

if [ -d "$SCRIPT_DIR/.claude/skills" ]; then
  echo "  • .claude/skills/        ($(find "$SCRIPT_DIR/.claude/skills/" -name "*.md" 2>/dev/null | wc -l | tr -d ' ') arquivos)"
fi

if [ -d "$SCRIPT_DIR/.github/skills" ]; then
  echo "  • .github/skills/        ($(find "$SCRIPT_DIR/.github/skills/" -name "*.md" 2>/dev/null | wc -l | tr -d ' ') arquivos)"
fi

if [ -d "$SCRIPT_DIR/.agents/skills" ]; then
  echo "  • .agents/skills/        ($(find "$SCRIPT_DIR/.agents/skills/" -name "*.md" 2>/dev/null | wc -l | tr -d ' ') arquivos)"
fi

if [ -d "$SCRIPT_DIR/.claude/agents" ]; then
  echo "  • .claude/agents/        ($(find "$SCRIPT_DIR/.claude/agents/" -name "*.md" 2>/dev/null | wc -l | tr -d ' ') agentes)"
fi

if [ -d "$SCRIPT_DIR/.opencode/agents" ] || [ -d "$SCRIPT_DIR/.codex/agents" ]; then
  echo "  • .opencode/agents/ e .codex/agents/ (agentes nativos)"
fi

migrate_root_dir_to_docs() {
  local name="$1"
  local old_dir="$SCRIPT_DIR/$name"
  local new_dir="$SCRIPT_DIR/docs/$name"

  if [ -d "$old_dir" ]; then
    mkdir -p "$new_dir"
    rsync -a "$old_dir/" "$new_dir/"
    rm -rf "$old_dir"
    echo "  ✅ $name/ → docs/$name/"
  fi
}

echo "🗂️  Verificando estrutura antiga (plan/ e flow/ na raiz)..."
migrate_root_dir_to_docs "plan"
migrate_root_dir_to_docs "flow"
