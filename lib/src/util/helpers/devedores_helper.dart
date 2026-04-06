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
  String nome = devedoresEntity?.nome ?? '';
  String? pix = devedoresEntity?.pix;
  double valorModificado = devedoresEntity?.valor ?? 0;
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
                  label: AppStrings.valor,
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    if (v.isNotEmpty) {
                      final filtered = v.replaceAll('.', '');
                      valorModificado =
                          double.tryParse(filtered.replaceAll(',', '.')) ?? 0;
                      setModalState(() {});
                    }
                  },
                ),
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
                            if (devedoresEntity != null) {
                              cubit.editarDevedor(
                                DevedoresEntity(
                                  id: devedoresEntity.id,
                                  nome: nome,
                                  valor: valorModificado,
                                  pix: pix,
                                  message: mensagemTextController.text,
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
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
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
