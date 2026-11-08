import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:notes_app/src/features/home/cubit/home_cubit.dart';
import 'package:notes_app/src/features/nova_divida/content/nova_divida_form_content.dart';
import 'package:notes_app/src/util/entity/divida_entity.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:uuid/uuid.dart';

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
  final _nomeController = TextEditingController();

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
    final divida = widget.dividaEntity;
    if (divida != null) {
      _nomeDivida = divida.nome;
      _corSelecionada = divida.cor;
      _nomeController.text = divida.nome;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _faturaTextController.dispose();
    super.dispose();
  }

  String get _tipoLabel {
    final divida = widget.dividaEntity;
    if (divida != null) {
      return divida.mensal ? AppStrings.mensal : '${divida.faturas.length}x';
    }
    return _isMensal ? AppStrings.mensal : '${_quantidadeParcelas}x';
  }

  double? get _valorParcelaPreview {
    final divida = widget.dividaEntity;
    if (divida != null) {
      return divida.mensal || divida.faturas.isEmpty
          ? null
          : divida.faturas.first.valor;
    }
    return _isMensal ? null : _valorParcela;
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isEditing = widget.dividaEntity != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? AppStrings.atualizarDivida : AppStrings.novaDivida,
        ),
        actions: [
          if (isEditing)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: cs.error),
              onPressed: () {
                widget.homeCubit
                    .removerDivida(widget.dividaEntity!)
                    .whenComplete(() {
                  if (context.mounted) Navigator.of(context).pop();
                });
              },
              child: Text(AppStrings.deletar),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  NovaDividaCardPreview(
                    cor: _corSelecionada,
                    nome: _nomeDivida,
                    tipo: _tipoLabel,
                    valorParcela: _valorParcelaPreview,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nomeController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: AppStrings.nomeDaDivida,
                      hintText: AppStrings.digiteONomeDivida,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _nomeDivida = v),
                  ),
                  const SizedBox(height: 28),
                  NovaDividaSectionTitle(label: AppStrings.corDaDivida),
                  NovaDividaColorPicker(
                    colors: _listColors,
                    selected: _corSelecionada,
                    onChanged: (cor) => setState(() => _corSelecionada = cor),
                  ),
                  if (!isEditing) ...[
                    const SizedBox(height: 28),
                    NovaDividaSectionTitle(label: AppStrings.tipoDivida),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(
                            value: true,
                            label: Text(AppStrings.mensal),
                          ),
                          ButtonSegment(
                            value: false,
                            label: Text(AppStrings.parcelada),
                          ),
                        ],
                        selected: {_isMensal},
                        onSelectionChanged: (s) =>
                            setState(() => _isMensal = s.first),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.naoPodeModificar,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (!_isMensal) ...[
                      const SizedBox(height: 20),
                      DropdownButtonFormField<int>(
                        initialValue: _quantidadeParcelas,
                        menuMaxHeight: 300,
                        decoration: InputDecoration(
                          labelText: AppStrings.quantidadeParcelas,
                          border: const OutlineInputBorder(),
                        ),
                        items: List.generate(
                          48,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text('${i + 1}x'),
                          ),
                        ),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _quantidadeParcelas = v);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _faturaTextController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: AppStrings.valorParcela,
                          prefixText: 'R\$ ',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) {
                          setState(() {
                            _valorParcela = _faturaTextController.numberValue;
                          });
                        },
                      ),
                    ],
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                onPressed: _salvar,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(AppStrings.salvar),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
