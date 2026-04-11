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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: flat cor + nome + valor pill ──
            Container(
              width: double.infinity,
              color: cor,
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nome
                        Text(
                          widget.orcamento.nome,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subItens.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${subItens.length} ${AppStrings.subDividas.toLowerCase()}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Valor pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'R\$ ${format.format(total)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Sub-items ──
            if (subItens.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    ...visibleSubItens
                        .map((s) => _SubItemRow(subItem: s, cor: cor)),
                    if (subItens.length > 3) ...[
                      const SizedBox(height: 4),
                      Divider(
                        height: 1,
                        color: cs.outlineVariant.withValues(alpha: 0.4),
                      ),
                      GestureDetector(
                        onTap: () => setState(
                          () => _expandedSubItens = !_expandedSubItens,
                        ),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
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
                              const SizedBox(width: 3),
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

            // ── Actions ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  _ActionButton(
                    label: AppStrings.subDividas,
                    icon: Icons.add_rounded,
                    cor: cor,
                    onTap: _gerenciarSubItensBottomSheet,
                  ),
                  const Spacer(),
                  _ActionButton(
                    label: AppStrings.editar,
                    icon: Icons.edit_outlined,
                    cor: cs.onSurfaceVariant,
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
                  _ActionButton(
                    label: AppStrings.deletar,
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
    final scrollController = ScrollController();

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
                          child: Scrollbar(
                            thumbVisibility: true,
                            controller: scrollController,
                            child: ListView.builder(
                              controller: scrollController,
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
                                      const SizedBox(width: 8),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.cor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color cor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: cor.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: cor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubItemRow extends StatelessWidget {
  const _SubItemRow({required this.subItem, required this.cor});

  final SubItemOrcamentoEntity subItem;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: '');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              subItem.nome,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'R\$ ${fmt.format(subItem.valor)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}
