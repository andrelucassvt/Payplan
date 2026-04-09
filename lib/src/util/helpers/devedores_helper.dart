import 'package:flutter/material.dart';
import 'package:notes_app/src/util/entity/devedores_entity.dart';
import 'package:notes_app/src/util/extension/real_format_extension.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:uuid/uuid.dart';
import 'package:notes_app/src/features/devedores/cubit/devedores_cubit.dart';

const _kAccent = Color(0xFF5C5FEF);

Future<void> showNovoDevedorModal({
  required BuildContext context,
  required DevedoresCubit cubit,
  required TextEditingController nomeTextController,
  required TextEditingController pixTextController,
  required TextEditingController faturaTextController,
  required TextEditingController mensagemTextController,
  DevedoresEntity? devedoresEntity,
}) async {
  final bool isEditing = devedoresEntity != null;
  final bool hasExistingParcelas =
      devedoresEntity?.parcelas.isNotEmpty ?? false;

  String nome = devedoresEntity?.nome ?? '';
  String? pix = devedoresEntity?.pix;
  double valorModificado = devedoresEntity?.valor ?? 0;
  bool parcelar = false;
  int qtdParcelas = 1;

  nomeTextController.text = nome;
  faturaTextController.text = valorModificado.real;
  pixTextController.text = devedoresEntity?.pix ?? '';
  mensagemTextController.text = devedoresEntity?.message ?? '';

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final cs = Theme.of(context).colorScheme;
          return Container(
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // — Drag handle —
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.novoDevedor,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _LightTextField(
                    controller: nomeTextController,
                    label: AppStrings.nomeDevedor,
                    onChanged: (v) {
                      nome = v;
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 14),
                  _LightTextField(
                    controller: pixTextController,
                    label: 'Chave PIX',
                    onChanged: (v) {
                      pix = v.isNotEmpty ? v : null;
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 14),
                  _LightTextField(
                    controller: faturaTextController,
                    label:
                        parcelar ? AppStrings.valorParcela : AppStrings.valor,
                    keyboardType: TextInputType.number,
                    readOnly: isEditing && hasExistingParcelas,
                    onChanged: (v) {
                      if (v.isNotEmpty) {
                        final filtered = v.replaceAll('.', '');
                        valorModificado =
                            double.tryParse(filtered.replaceAll(',', '.')) ?? 0;
                        setModalState(() {});
                      }
                    },
                  ),
                  // — Parcelar toggle (only on creation) —
                  if (!isEditing) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.view_week_outlined,
                            size: 16,
                            color: _kAccent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              AppStrings.parcelarDevedor,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          Switch(
                            value: parcelar,
                            activeColor: _kAccent,
                            onChanged: (v) => setModalState(() {
                              parcelar = v;
                              if (!v) qtdParcelas = 1;
                            }),
                          ),
                        ],
                      ),
                    ),
                    if (parcelar) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppStrings.quantidadeParcelas,
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          PopupMenuButton<int>(
                            constraints:
                                const BoxConstraints.tightFor(height: 300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _kAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _kAccent.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${qtdParcelas}x',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _kAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.expand_more_rounded,
                                    size: 16,
                                    color: _kAccent,
                                  ),
                                ],
                              ),
                            ),
                            itemBuilder: (_) => List.generate(
                              48,
                              (i) => PopupMenuItem<int>(
                                value: i + 1,
                                onTap: () =>
                                    setModalState(() => qtdParcelas = i + 1),
                                child: Text('${i + 1}x'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _kAccent.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _kAccent.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppStrings.total,
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              (valorModificado * qtdParcelas).real,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _kAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 14),
                  _LightTextField(
                    controller: mensagemTextController,
                    label: AppStrings.mensagem,
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: nomeTextController.text.isEmpty
                          ? null
                          : () {
                              if (isEditing) {
                                cubit.editarDevedor(
                                  DevedoresEntity(
                                    id: devedoresEntity.id,
                                    nome: nome,
                                    valor: hasExistingParcelas
                                        ? devedoresEntity.valor
                                        : valorModificado,
                                    pix: pix,
                                    message: mensagemTextController.text,
                                    notificar: devedoresEntity.notificar,
                                    parcelas: devedoresEntity.parcelas,
                                  ),
                                );
                              } else if (parcelar) {
                                final parcelas = List.generate(
                                  qtdParcelas,
                                  (i) => ParcelaDevedorEntity(
                                    numero: i + 1,
                                    valor: valorModificado,
                                  ),
                                );
                                cubit.adicionarDevedor(
                                  DevedoresEntity(
                                    id: const Uuid().v4(),
                                    nome: nome,
                                    valor: valorModificado * qtdParcelas,
                                    pix: pix,
                                    message: mensagemTextController.text,
                                    parcelas: parcelas,
                                  ),
                                );
                              } else {
                                cubit.adicionarDevedor(
                                  DevedoresEntity(
                                    id: const Uuid().v4(),
                                    nome: nome,
                                    valor: valorModificado,
                                    pix: pix,
                                    message: mensagemTextController.text,
                                  ),
                                );
                              }
                              Navigator.pop(context);
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: _kAccent,
                        disabledBackgroundColor: const Color(0xFFE5E7EB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        AppStrings.salvar,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    nomeTextController.clear();
  });
}

// ---------------------------------------------------------------------------

class _LightTextField extends StatelessWidget {
  const _LightTextField({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.keyboardType,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      readOnly: readOnly,
      style: TextStyle(fontSize: 15, color: cs.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kAccent, width: 1.5),
        ),
      ),
    );
  }
}
