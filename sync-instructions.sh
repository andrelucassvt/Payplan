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

# ============================================================
# NÃO EDITE ABAIXO (a menos que saiba o que está fazendo)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR=$(mktemp -d)

cleanup() {
  rm -rf "$TMP_DIR"
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

# ── Rules: Claude → todas as plataformas ──────────────────
if [ -d "$TMP_DIR/.claude/rules" ]; then
  echo "📋 Sincronizando rules para todas as plataformas..."

  # Claude Code: copia direto
  mkdir -p "$SCRIPT_DIR/.claude/rules"
  rsync -a --delete "$TMP_DIR/.claude/rules/" "$SCRIPT_DIR/.claude/rules/"

  # Codex / Agents: copia sem transformação de frontmatter
  mkdir -p "$SCRIPT_DIR/.agents/instructions"
  rsync -a --delete "$TMP_DIR/.claude/rules/" "$SCRIPT_DIR/.agents/instructions/"
  # Ajusta referência de skill path nos arquivos copiados
  for f in "$SCRIPT_DIR/.agents/instructions/"*.md; do
    [ -f "$f" ] && sed -i '' 's|\.claude/skills/|.agents/skills/|g' "$f"
  done

  # GitHub Copilot: substitui frontmatter description → applyTo: '**'
  mkdir -p "$SCRIPT_DIR/.github/instructions"
  rsync -a --delete "$TMP_DIR/.claude/rules/" "$SCRIPT_DIR/.github/instructions/"
  for f in "$SCRIPT_DIR/.github/instructions/"*.md; do
    [ -f "$f" ] && sed -i '' \
      's|^description:.*|applyTo: '"'"'**'"'"'|g' \
      "$f"
    [ -f "$f" ] && sed -i '' 's|\.claude/skills/|.github/skills/|g' "$f"
  done
else
  echo "⏭️  .claude/rules/ não encontrado no repositório fonte. Pulando."
fi

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
echo "  • .claude/rules/               (regras obrigatórias — Claude Code)"
echo "  • .github/instructions/        (espelho para GitHub Copilot)"
echo "  • .agents/instructions/        (espelho para Codex / OpenAI Agents)"
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

if [ -d "$SCRIPT_DIR/.claude/rules" ]; then
  echo "  • .claude/rules/         ($(find "$SCRIPT_DIR/.claude/rules/" -name "*.md" 2>/dev/null | wc -l | tr -d ' ') arquivos)"
fi

if [ -d "$SCRIPT_DIR/.github/instructions" ]; then
  echo "  • .github/instructions/  ($(find "$SCRIPT_DIR/.github/instructions/" -name "*.md" 2>/dev/null | wc -l | tr -d ' ') arquivos)"
fi

if [ -d "$SCRIPT_DIR/.agents/instructions" ]; then
  echo "  • .agents/instructions/  ($(find "$SCRIPT_DIR/.agents/instructions/" -name "*.md" 2>/dev/null | wc -l | tr -d ' ') arquivos)"
fi
