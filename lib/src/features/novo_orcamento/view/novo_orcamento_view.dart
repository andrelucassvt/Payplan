import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:notes_app/src/features/novo_orcamento/content/novo_orcamento_form_content.dart';
import 'package:notes_app/src/features/orcamento/cubit/orcamento_cubit.dart';
import 'package:notes_app/src/util/entity/orcamento_entity.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:uuid/uuid.dart';

const _kAccent = Color(0xFF5C5FEF);

class NovoOrcamentoView extends StatefulWidget {
  const NovoOrcamentoView({
    required this.orcamentoCubit,
    this.orcamento,
    super.key,
  });

  final OrcamentoCubit orcamentoCubit;
  final OrcamentoEntity? orcamento;

  @override
  State<NovoOrcamentoView> createState() => _NovoOrcamentoViewState();
}

class _NovoOrcamentoViewState extends State<NovoOrcamentoView> {
  Color _corSelecionada = const Color(0xFFEF4444);
  String _nomeOrcamento = '';
  double _valorOrcamento = 0.0;
  bool _comSubItens = false;
  late final MoneyMaskedTextController _valorTextController;

  final List<Color> _listColors = const [
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
    Color(0xFFA855F7),
    Color(0xFFF97316),
    Color(0xFFF59E0B),
    Color(0xFF78716C),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFF6366F1),
    Color(0xFF84CC16),
  ];

  @override
  void initState() {
    super.initState();
    _valorTextController = MoneyMaskedTextController(initialValue: 0.0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.orcamento != null) {
        final orcamento = widget.orcamento!;
        setState(() {
          _nomeOrcamento = orcamento.nome;
          _corSelecionada = orcamento.cor;
          _comSubItens = orcamento.subItens.isNotEmpty;
          _valorOrcamento = orcamento.valor;
          _valorTextController.updateValue(_valorOrcamento);
        });
      }
    });
  }

  @override
  void dispose() {
    _valorTextController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_nomeOrcamento.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.digiteONomeOrcamento)),
      );
      return;
    }

    final isEditing = widget.orcamento != null;

    final valor = _comSubItens ? 0.0 : _valorTextController.numberValue;

    if (isEditing) {
      widget.orcamentoCubit.atualizarOrcamento(
        widget.orcamento!.copyWith(
          nome: _nomeOrcamento,
          cor: _corSelecionada,
          valor: valor,
        ),
      );
    } else {
      widget.orcamentoCubit.salvarOrcamento(
        OrcamentoEntity(
          id: const Uuid().v4(),
          nome: _nomeOrcamento,
          cor: _corSelecionada,
          valor: valor,
        ),
      );
    }

    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEditing = widget.orcamento != null;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          isEditing ? AppStrings.atualizarOrcamento : AppStrings.novoOrcamento,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: cs.onSurface,
          ),
        ),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          if (isEditing)
            TextButton.icon(
              onPressed: () {
                widget.orcamentoCubit
                    .removerOrcamento(widget.orcamento!)
                    .whenComplete(() {
                  if (context.mounted) Navigator.of(context).pop();
                });
              },
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Color(0xFFEF4444),
              ),
              label: Text(
                AppStrings.deletar,
                style: const TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _salvar,
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.check_rounded),
        label: Text(
          AppStrings.salvar,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Preview ──
              NovoOrcamentoPreviewCard(
                cor: _corSelecionada,
                nome: _nomeOrcamento,
              ),
              const SizedBox(height: 16),

              // ── Tipo ──
              NovoOrcamentoTipoToggle(
                comSubItens: _comSubItens,
                onChanged: (v) => setState(() => _comSubItens = v),
              ),
              const SizedBox(height: 16),

              // ── Nome ──
              NovoOrcamentoSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NovoOrcamentoSectionLabel(
                      label: AppStrings.nomeOrcamento,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: AppStrings.digiteONomeOrcamento,
                        hintStyle: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w400,
                          fontSize: 20,
                        ),
                        filled: true,
                        fillColor:
                            cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: cs.outlineVariant,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _kAccent,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      controller: TextEditingController(text: _nomeOrcamento)
                        ..selection = TextSelection.fromPosition(
                          TextPosition(offset: _nomeOrcamento.length),
                        ),
                      onChanged: (v) => setState(() => _nomeOrcamento = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Cor ──
              NovoOrcamentoSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NovoOrcamentoSectionLabel(
                      label: AppStrings.corDoOrcamento,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _listColors.map((cor) {
                        final selected = _corSelecionada == cor;
                        return GestureDetector(
                          onTap: () => setState(() => _corSelecionada = cor),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: cor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: cor.withValues(alpha: 0.5),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: selected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Valor / Hint ──
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _comSubItens
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: NovoOrcamentoSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NovoOrcamentoSectionLabel(
                        label: AppStrings.valorDoOrcamento,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _valorTextController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          hintText: AppStrings.digiteOValorDoOrcamento,
                          hintStyle: TextStyle(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                          ),
                          filled: true,
                          fillColor:
                              cs.surfaceContainerHighest.withValues(alpha: 0.5),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: cs.outlineVariant,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: _kAccent,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: (_) => setState(
                          () => _valorOrcamento =
                              _valorTextController.numberValue,
                        ),
                      ),
                    ],
                  ),
                ),
                secondChild: const NovoOrcamentoSubItensHint(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
