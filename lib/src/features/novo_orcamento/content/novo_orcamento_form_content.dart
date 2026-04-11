import 'package:flutter/material.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';

const _kAccent = Color(0xFF5C5FEF);

// ─── Tipo Toggle ──────────────────────────────────────────────────────────

class NovoOrcamentoTipoToggle extends StatelessWidget {
  const NovoOrcamentoTipoToggle({
    required this.comSubItens,
    required this.onChanged,
    super.key,
  });

  final bool comSubItens;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return NovoOrcamentoSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NovoOrcamentoSectionLabel(label: AppStrings.tipoOrcamento),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _TipoOption(
                  icon: Icons.attach_money_rounded,
                  label: AppStrings.orcamentoValorFixo,
                  selected: !comSubItens,
                  onTap: () => onChanged(false),
                ),
                _TipoOption(
                  icon: Icons.list_alt_rounded,
                  label: AppStrings.orcamentoComSubItens,
                  selected: comSubItens,
                  onTap: () => onChanged(true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipoOption extends StatelessWidget {
  const _TipoOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _kAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : cs.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SubItens Hint ────────────────────────────────────────────────────────

class NovoOrcamentoSubItensHint extends StatelessWidget {
  const NovoOrcamentoSubItensHint({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return NovoOrcamentoSectionCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: _kAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppStrings.orcamentoComSubItensDesc,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Preview Card ─────────────────────────────────────────────────────────

class NovoOrcamentoPreviewCard extends StatelessWidget {
  const NovoOrcamentoPreviewCard({
    required this.cor,
    required this.nome,
    super.key,
  });

  final Color cor;
  final String nome;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cor.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AppStrings.novoOrcamento,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.nomeOrcamento,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              nome.isEmpty ? '—' : nome,
              key: ValueKey(nome),
              style: TextStyle(
                color:
                    Colors.white.withValues(alpha: nome.isEmpty ? 0.35 : 1.0),
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────

class NovoOrcamentoSectionCard extends StatelessWidget {
  const NovoOrcamentoSectionCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────

class NovoOrcamentoSectionLabel extends StatelessWidget {
  const NovoOrcamentoSectionLabel({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 1.0,
      ),
    );
  }
}
