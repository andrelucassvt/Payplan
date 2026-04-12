import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:intl/intl.dart';
import 'package:notes_app/src/features/novo_orcamento/view/novo_orcamento_view.dart';
import 'package:notes_app/src/features/orcamento/cubit/orcamento_cubit.dart';
import 'package:notes_app/src/util/entity/orcamento_entity.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:uuid/uuid.dart';

const _kAccent = Color(0xFF5C5FEF);

class OrcamentoCardWidget extends StatefulWidget {
  const OrcamentoCardWidget({
    required this.orcamento,
    required this.orcamentoCubit,
    super.key,
  });

  final OrcamentoEntity orcamento;
  final OrcamentoCubit orcamentoCubit;

  @override
  State<OrcamentoCardWidget> createState() => _OrcamentoCardWidgetState();
}

class _OrcamentoCardWidgetState extends State<OrcamentoCardWidget> {
  final format = NumberFormat.currency(locale: 'pt_BR', symbol: '');
  bool _expandedSubItens = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cor = widget.orcamento.cor;
    final total = widget.orcamento.totalOrcamento;
    final subItens = widget.orcamento.subItens;
    final visibleSubItens =
        _expandedSubItens ? subItens : subItens.take(3).toList();

    final isConcluido = widget.orcamento.concluido;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: cor.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header colorido ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cor, cor.withValues(alpha: 0.72)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.orcamento.nome.isNotEmpty
                            ? widget.orcamento.nome[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.orcamento.nome,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subItens.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${subItens.length}'
                              ' ${AppStrings.subDividas.toLowerCase()}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.80),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: isConcluido ? 0.28 : 0.15,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: isConcluido ? 0.65 : 0.35,
                        ),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isConcluido
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isConcluido
                              ? AppStrings.orcamentoConcluido
                              : AppStrings.emAndamento,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Valor total ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.valorTotal,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'R\$ ${format.format(total)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isConcluido ? cs.onSurfaceVariant : cs.onSurface,
                      decoration:
                          isConcluido ? TextDecoration.lineThrough : null,
                      decorationColor: cs.onSurfaceVariant,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),

            // ── Sub-items ──
            if (subItens.isNotEmpty) ...[
              Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  children: [
                    ...visibleSubItens.map(
                      (s) => _SubItemRow(
                        subItem: s,
                        cor: cor,
                        onToggle: () =>
                            widget.orcamentoCubit.toggleSubItemConcluido(
                          widget.orcamento,
                          s.id,
                        ),
                      ),
                    ),
                    if (subItens.length > 3) ...[
                      const Divider(height: 8, thickness: 0.5),
                      GestureDetector(
                        onTap: () => setState(
                          () => _expandedSubItens = !_expandedSubItens,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _expandedSubItens
                                    ? AppStrings.verMenos
                                    : AppStrings.verMais(
                                        subItens.length - 3,
                                      ),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: cor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _expandedSubItens
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: cor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // ── Ações ──
            Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  _ActionChip(
                    label: AppStrings.subDividas,
                    cor: cor,
                    onTap: _gerenciarSubItensBottomSheet,
                  ),
                  const SizedBox(width: 8),
                  _ActionChip(
                    label: isConcluido
                        ? AppStrings.orcamentoConcluido
                        : AppStrings.marcarComoConcluido,
                    cor: const Color(0xFF22C55E),
                    onTap: () => widget.orcamentoCubit
                        .toggleOrcamentoConcluido(widget.orcamento),
                  ),
                  const Spacer(),
                  _ActionChip(
                    icon: Icons.edit_outlined,
                    cor: cor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NovoOrcamentoView(
                          orcamentoCubit: widget.orcamentoCubit,
                          orcamento: widget.orcamento,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ActionChip(
                    icon: Icons.delete_outline_rounded,
                    cor: const Color(0xFFEF4444),
                    onTap: () => _confirmarDelecao(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editarSubItemDialog(
    BuildContext sheetContext,
    SubItemOrcamentoEntity subItem,
  ) {
    final nomeController = TextEditingController(text: subItem.nome);
    final valorController =
        MoneyMaskedTextController(initialValue: subItem.valor);

    showDialog(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            AppStrings.editar,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nomeController,
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                  labelText: AppStrings.nomeSubDivida,
                  labelStyle: TextStyle(color: cs.onSurfaceVariant),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kAccent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: valorController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                  labelText: AppStrings.valor,
                  labelStyle: TextStyle(color: cs.onSurfaceVariant),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kAccent, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppStrings.cancelar),
            ),
            TextButton(
              onPressed: () {
                final nome = nomeController.text.trim();
                final novoValor = valorController.numberValue;
                if (nome.isEmpty || novoValor == 0.0) return;
                widget.orcamentoCubit.atualizarSubItem(
                  widget.orcamento,
                  subItem.copyWith(nome: nome, valor: novoValor),
                );
                Navigator.of(dialogContext).pop();
                Navigator.of(sheetContext).pop();
              },
              child: Text(
                AppStrings.salvar,
                style: const TextStyle(
                  color: _kAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmarDelecao(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(AppStrings.atencao),
          content: Text(AppStrings.orcamentoSeraRemovido),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.cancelar),
            ),
            TextButton(
              onPressed: () {
                widget.orcamentoCubit.removerOrcamento(widget.orcamento);
                Navigator.pop(ctx);
              },
              child: Text(
                AppStrings.deletar,
                style: const TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _gerenciarSubItensBottomSheet() {
    final nomeController = TextEditingController();
    final valorController = MoneyMaskedTextController(initialValue: 0.0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final cs = Theme.of(sheetContext).colorScheme;
            final subItens = widget.orcamento.subItens;

            return Padding(
              padding: MediaQuery.of(sheetContext).viewInsets,
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: cs.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppStrings.subDividas,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (subItens.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            AppStrings.nenhumSubItem,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: subItens.length,
                            itemBuilder: (context, index) {
                              final s = subItens[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.label_outline_rounded,
                                  color: _kAccent,
                                  size: 18,
                                ),
                                title: Text(
                                  s.nome,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'R\$ ${format.format(s.valor)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => _editarSubItemDialog(
                                        sheetContext,
                                        s,
                                      ),
                                      child: const Icon(
                                        Icons.edit_outlined,
                                        color: _kAccent,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: () {
                                        widget.orcamentoCubit.removerSubItem(
                                          widget.orcamento,
                                          s.id,
                                        );
                                        Navigator.of(sheetContext).pop();
                                      },
                                      child: const Icon(
                                        Icons.delete_outline,
                                        color: Color(0xFFEF4444),
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      const Divider(height: 24),
                      Text(
                        AppStrings.adicionarSubDivida,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nomeController,
                        style: TextStyle(color: cs.onSurface),
                        decoration: InputDecoration(
                          labelText: AppStrings.nomeSubDivida,
                          labelStyle: TextStyle(color: cs.onSurfaceVariant),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: _kAccent,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: valorController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: cs.onSurface),
                        decoration: InputDecoration(
                          labelText: AppStrings.valor,
                          labelStyle: TextStyle(color: cs.onSurfaceVariant),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: _kAccent,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _kAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            final novoValor = valorController.numberValue;
                            if (nomeController.text.trim().isEmpty ||
                                novoValor == 0.0) {
                              return;
                            }
                            widget.orcamentoCubit.adicionarSubItem(
                              widget.orcamento,
                              SubItemOrcamentoEntity(
                                id: const Uuid().v4(),
                                nome: nomeController.text.trim(),
                                valor: novoValor,
                              ),
                            );
                            Navigator.of(sheetContext).pop();
                          },
                          child: Text(
                            AppStrings.salvar,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    this.label,
    this.icon,
    required this.cor,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final Color cor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: icon != null
            ? Icon(icon, size: 16, color: cor)
            : Text(
                label!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cor,
                ),
              ),
      ),
    );
  }
}

class _SubItemRow extends StatelessWidget {
  const _SubItemRow({
    required this.subItem,
    required this.cor,
    required this.onToggle,
  });

  final SubItemOrcamentoEntity subItem;
  final Color cor;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: '');
    final done = subItem.concluido;
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            // Animated checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: done ? cor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: done ? cor : cor.withValues(alpha: 0.40),
                  width: 1.5,
                ),
              ),
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Opacity(
                opacity: done ? 0.45 : 1.0,
                child: Text(
                  subItem.nome,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: cs.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Opacity(
              opacity: done ? 0.45 : 1.0,
              child: Text(
                'R\$ ${fmt.format(subItem.valor)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cor,
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: cor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
