import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:notes_app/src/features/home/cubit/home_cubit.dart';
import 'package:notes_app/src/features/nova_divida/content/nova_divida_form_content.dart';
import 'package:notes_app/src/util/entity/divida_entity.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:uuid/uuid.dart';

const _kAccent = Color(0xFF5C5FEF);

class NovaDividaView extends StatefulWidget {
  const NovaDividaView({
    required this.homeCubit,
    this.dividaEntity,
    super.key,
  });

  final HomeCubit homeCubit;
  final DividaEntity? dividaEntity;

  @override
  State<NovaDividaView> createState() => _NovaDividaViewState();
}

class _NovaDividaViewState extends State<NovaDividaView> {
  Color _corSelecionada = const Color(0xFFEF4444);
  String _nomeDivida = '';
  bool _isMensal = true;
  int _quantidadeParcelas = 1;
  double _valorParcela = 0.0;
  final _faturaTextController = MoneyMaskedTextController(initialValue: 0.0);

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

  int _calculoMes = 1;
  int _calculoAno = DateTime.now().year;

  int _calculoMeses(int index) {
    if (index == 0) {
      _calculoMes = DateTime.now().month;
      if (_calculoMes == 12) _calculoAno += 1;
      return _calculoMes;
    }
    _calculoMes++;
    if (_calculoMes == 12) _calculoAno += 1;
    if (_calculoMes > 12) _calculoMes = 1;
    return _calculoMes;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.dividaEntity != null) {
        setState(() {
          _nomeDivida = widget.dividaEntity!.nome;
          _corSelecionada = widget.dividaEntity!.cor;
        });
      }
    });
  }

  void _salvar() {
    if (_nomeDivida.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.digiteONomeDivida)),
      );
      return;
    }
    if (!_isMensal && _valorParcela == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.valorParcela)),
      );
      return;
    }

    if (widget.dividaEntity != null) {
      widget.homeCubit.atualizarDivida(
        widget.dividaEntity!.copyWith(
          cor: _corSelecionada,
          nome: _nomeDivida,
        ),
      );
    } else {
      widget.homeCubit.salvarDivida(
        DividaEntity(
          id: const Uuid().v4(),
          nome: _nomeDivida,
          mensal: _isMensal,
          cor: _corSelecionada,
          faturas: _isMensal
              ? []
              : List.generate(
                  _quantidadeParcelas,
                  (i) => FaturaMensalEntity(
                    ano: _calculoAno,
                    mes: _calculoMeses(i),
                    valor: _valorParcela,
                  ),
                ),
        ),
      );
    }

    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEditing = widget.dividaEntity != null;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          isEditing ? AppStrings.atualizarDivida : AppStrings.novaDivida,
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
                widget.homeCubit
                    .removerDivida(widget.dividaEntity!)
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
              NovaDividaPreviewCard(cor: _corSelecionada, nome: _nomeDivida),
              const SizedBox(height: 20),

              // ── Nome ──
              NovaDividaSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NovaDividaSectionLabel(label: AppStrings.nomeDaDivida),
                    const SizedBox(height: 12),
                    TextField(
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: AppStrings.digiteONomeDivida,
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
                      onChanged: (v) => setState(() => _nomeDivida = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Cor ──
              NovaDividaSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NovaDividaSectionLabel(label: AppStrings.corDaDivida),
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

              if (!isEditing) ...[
                const SizedBox(height: 16),

                // ── Warning ──
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFD97706),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppStrings.naoPodeModificar,
                          style: const TextStyle(
                            color: Color(0xFFD97706),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Tipo + valor ──
                NovaDividaSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NovaDividaSectionLabel(label: AppStrings.parcelada),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          NovaDividaTypeChip(
                            label: AppStrings.mensal,
                            icon: Icons.repeat_rounded,
                            selected: _isMensal,
                            onTap: () => setState(() => _isMensal = true),
                          ),
                          const SizedBox(width: 10),
                          NovaDividaTypeChip(
                            label: AppStrings.parcelada,
                            icon: Icons.view_week_outlined,
                            selected: !_isMensal,
                            onTap: () => setState(() => _isMensal = false),
                          ),
                          if (!_isMensal) ...[
                            const Spacer(),
                            NovaDividaParcelaSelector(
                              value: _quantidadeParcelas,
                              onChanged: (v) =>
                                  setState(() => _quantidadeParcelas = v),
                            ),
                          ],
                        ],
                      ),
                      if (!_isMensal) ...[
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        NovaDividaSectionLabel(
                          label: AppStrings.valorParcela,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _faturaTextController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            prefixText: 'R\$ ',
                            prefixStyle: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onChanged: (_) {
                            setState(() {
                              _valorParcela = _faturaTextController.numberValue;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
