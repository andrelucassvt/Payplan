import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:notes_app/src/features/home/cubit/home_cubit.dart';
import 'package:notes_app/src/features/nova_divida/view/nova_divida_view.dart';
import 'package:notes_app/src/util/entity/divida_entity.dart';
import 'package:notes_app/src/util/entity/user_entity.dart';
import 'package:notes_app/src/util/enum/meses_enum.dart';
import 'package:notes_app/src/util/extension/real_format_extension.dart';
import 'package:notes_app/src/util/service/ads/app_open_ad_service.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:uuid/uuid.dart';

class HomeCardDivida extends StatefulWidget {
  const HomeCardDivida({
    required this.dividaEntity,
    required this.homeCubit,
    super.key,
  });
  final DividaEntity dividaEntity;
  final HomeCubit homeCubit;

  @override
  State<HomeCardDivida> createState() => _HomeCardDividaState();
}

class _HomeCardDividaState extends State<HomeCardDivida> {
  HomeState get homeState => widget.homeCubit.state;

  double valorFatura = 0.0;
  bool _expandedSubDividas = false;
  late final MoneyMaskedTextController _faturaTextController;

  FaturaMensalEntity? get faturaAtual {
    final result = widget.dividaEntity.faturas
        .where(
          (element) =>
              element.ano == widget.homeCubit.state.anoAtual &&
              element.mes == widget.homeCubit.state.mesAtual.id,
        )
        .toList();

    if (result.isEmpty && !widget.dividaEntity.mensal) {
      return null;
    }
    if (widget.dividaEntity.faturas.isEmpty || result.isEmpty) {
      return FaturaMensalEntity(
        ano: widget.homeCubit.state.anoAtual,
        mes: widget.homeCubit.state.mesAtual.id,
        pago: false,
        valor: 0,
      );
    }

    valorFatura = result[0].valor;
    setState(() {});

    return result[0];
  }

  int? get _numeroParcela {
    if (widget.dividaEntity.mensal) return null;
    final faturas = widget.dividaEntity.faturas;
    final atual = faturaAtual;
    if (faturas.isEmpty || atual == null) return null;
    final sorted = [...faturas]..sort((a, b) {
        if (a.ano != b.ano) return a.ano.compareTo(b.ano);
        return a.mes.compareTo(b.mes);
      });
    final idx = sorted.indexWhere(
      (f) => f.ano == atual.ano && f.mes == atual.mes,
    );
    return idx == -1 ? null : idx + 1;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _faturaTextController = MoneyMaskedTextController(
          initialValue: valorFatura,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (faturaAtual == null) return const SizedBox.shrink();

    final tt = Theme.of(context).textTheme;
    final cor = widget.dividaEntity.cor;
    final onCor = ThemeData.estimateBrightnessForColor(cor) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final onCorSecundario = onCor.withValues(alpha: 0.72);
    final isPaid = faturaAtual!.pago;
    final numeroParcela = _numeroParcela;
    final subDividasDoMes = widget.dividaEntity.subDividas
        .where(
          (s) => s.aplicavelNoMes(
            homeState.anoAtual,
            homeState.mesAtual.id,
          ),
        )
        .toList();
    final totalDoMes = faturaAtual!.valor +
        widget.dividaEntity
            .totalSubDividasDoMes(homeState.anoAtual, homeState.mesAtual.id);
    final textButtonStyle = TextButton.styleFrom(foregroundColor: onCor);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.dividaEntity.nome,
                        style: tt.titleMedium?.copyWith(
                          color: onCor,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (numeroParcela != null)
                        Text(
                          AppStrings.parcelaNumero(
                            numeroParcela,
                            widget.dividaEntity.faturas.length,
                          ),
                          style: tt.bodySmall?.copyWith(
                            color: onCorSecundario,
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 6),
                  child: Text(
                    isPaid ? AppStrings.paga : AppStrings.naoPaga,
                    style: tt.labelMedium?.copyWith(
                      color: isPaid ? onCor : onCorSecundario,
                      fontWeight: isPaid ? FontWeight.w700 : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 10, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    totalDoMes.real,
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isPaid ? onCorSecundario : onCor,
                      decoration: isPaid ? TextDecoration.lineThrough : null,
                      decorationColor: onCorSecundario,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Switch(
                  value: isPaid,
                  activeThumbColor: cor,
                  activeTrackColor: onCor,
                  inactiveThumbColor: onCor,
                  inactiveTrackColor: onCor.withValues(alpha: 0.15),
                  trackOutlineColor: WidgetStatePropertyAll(onCor),
                  onChanged: (value) {
                    final updated = widget.dividaEntity.faturas.map(
                      (e) {
                        if (e.ano == faturaAtual!.ano &&
                            e.mes == faturaAtual!.mes) {
                          return faturaAtual!.copyWith(pago: value);
                        }
                        return e;
                      },
                    ).toList();
                    widget.homeCubit.atualizarDivida(
                      widget.dividaEntity.copyWith(faturas: updated),
                    );
                  },
                ),
              ],
            ),
          ),
          if (subDividasDoMes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [
                  ...(_expandedSubDividas
                          ? subDividasDoMes
                          : subDividasDoMes.take(3))
                      .map(
                    (s) => _SubDividaRow(
                      subDivida: s,
                      corTexto: onCor,
                      corTextoSecundario: onCorSecundario,
                    ),
                  ),
                  if (subDividasDoMes.length > 3)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        style: textButtonStyle.copyWith(
                          padding:
                              const WidgetStatePropertyAll(EdgeInsets.zero),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => setState(
                          () => _expandedSubDividas = !_expandedSubDividas,
                        ),
                        child: Text(
                          _expandedSubDividas
                              ? AppStrings.verMenos
                              : AppStrings.verMais(
                                  subDividasDoMes.length - 3,
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Divider(height: 1, color: onCor.withValues(alpha: 0.18)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ValueListenableBuilder(
              valueListenable: UserController.user,
              builder: (context, user, ___) {
                return Row(
                  children: [
                    TextButton(
                      style: textButtonStyle,
                      onPressed: () => _editarFaturaBottomSheet(user.isPlus),
                      child: Text(AppStrings.editarFatura),
                    ),
                    TextButton(
                      style: textButtonStyle,
                      onPressed: _gerenciarSubDividasBottomSheet,
                      child: Text(AppStrings.subDividas),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: AppStrings.editar,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: onCor,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NovaDividaView(
                              homeCubit: widget.homeCubit,
                              dividaEntity: widget.dividaEntity,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _gerenciarSubDividasBottomSheet() {
    final nomeController = TextEditingController();
    final valorController = MoneyMaskedTextController(initialValue: 0.0);
    bool isRecorrente = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final cs = Theme.of(sheetContext).colorScheme;
            final tt = Theme.of(sheetContext).textTheme;
            final subDividas = widget.dividaEntity.subDividas;
            return Padding(
              padding: MediaQuery.of(sheetContext).viewInsets,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.subDividas, style: tt.titleLarge),
                    const SizedBox(height: 12),
                    if (subDividas.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          AppStrings.nenhumSubItem,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: subDividas.length,
                          itemBuilder: (context, index) {
                            final s = subDividas[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(s.nome),
                              subtitle: Text(
                                s.recorrente
                                    ? AppStrings.recorrente
                                    : '${MesesEnum.values.firstWhere((e) => e.id == s.mes).nome}/${s.ano}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    s.valor.real,
                                    style: tt.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: AppStrings.editar,
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () => _editarSubDividaDialog(
                                      sheetContext,
                                      s,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                    ),
                                    color: cs.error,
                                    onPressed: () {
                                      widget.homeCubit.removerSubDivida(
                                        widget.dividaEntity,
                                        s.id,
                                      );
                                      Navigator.of(sheetContext).pop();
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    const Divider(height: 32),
                    Text(AppStrings.adicionarSubDivida, style: tt.titleSmall),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nomeController,
                      decoration: InputDecoration(
                        labelText: AppStrings.nomeSubDivida,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: valorController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppStrings.valor,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(AppStrings.recorrente),
                      subtitle: isRecorrente
                          ? null
                          : Text(
                              '${AppStrings.unicaNoMes}: '
                              '${homeState.mesAtual.nome}/${homeState.anoAtual}',
                            ),
                      value: isRecorrente,
                      onChanged: (v) => setSheetState(() => isRecorrente = v),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          final novoValor = valorController.numberValue;
                          if (nomeController.text.trim().isEmpty ||
                              novoValor == 0.0) {
                            return;
                          }
                          widget.homeCubit.adicionarSubDivida(
                            widget.dividaEntity,
                            SubDividaEntity(
                              id: const Uuid().v4(),
                              nome: nomeController.text.trim(),
                              valor: novoValor,
                              recorrente: isRecorrente,
                              mes: isRecorrente ? null : homeState.mesAtual.id,
                              ano: isRecorrente ? null : homeState.anoAtual,
                            ),
                          );
                          Navigator.of(sheetContext).pop();
                        },
                        child: Text(AppStrings.salvar),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editarSubDividaDialog(
    BuildContext sheetContext,
    SubDividaEntity subDivida,
  ) {
    final nomeController = TextEditingController(text: subDivida.nome);
    final valorController =
        MoneyMaskedTextController(initialValue: subDivida.valor);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppStrings.editar),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nomeController,
                decoration: InputDecoration(
                  labelText: AppStrings.nomeSubDivida,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: valorController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppStrings.valor,
                  border: const OutlineInputBorder(),
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
                widget.homeCubit.atualizarSubDivida(
                  widget.dividaEntity,
                  subDivida.copyWith(nome: nome, valor: novoValor),
                );
                Navigator.of(dialogContext).pop();
                Navigator.of(sheetContext).pop();
              },
              child: Text(AppStrings.salvar),
            ),
          ],
        );
      },
    );
  }

  void _editarFaturaBottomSheet(bool isPlus) {
    if (!isPlus) {
      AppOpenAdService.instance.show();
    }
    double valorModificado = 0;
    _faturaTextController.updateValue(faturaAtual!.valor);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final tt = Theme.of(context).textTheme;
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.editarFatura, style: tt.titleLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _faturaTextController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppStrings.valorParcela,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final filtro1 = value.replaceAll('.', '');
                      valorModificado =
                          double.parse(filtro1.replaceAll(',', '.'));
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final tratamentoFaturaListaFatura =
                          widget.dividaEntity.faturas.map(
                        (e) {
                          if (e.ano == faturaAtual!.ano &&
                              e.mes == faturaAtual!.mes) {
                            return faturaAtual!
                                .copyWith(valor: valorModificado);
                          }
                          return e;
                        },
                      ).toList();
                      if (tratamentoFaturaListaFatura.isEmpty) {
                        widget.homeCubit.atualizarDivida(
                          widget.dividaEntity.copyWith(
                            faturas: [
                              faturaAtual!.copyWith(valor: valorModificado),
                            ],
                          ),
                        );
                      } else {
                        final resultVerificacaoFatura =
                            tratamentoFaturaListaFatura
                                .where(
                                  (e) =>
                                      e.ano == faturaAtual!.ano &&
                                      e.mes == faturaAtual!.mes,
                                )
                                .toList();
                        widget.homeCubit.atualizarDivida(
                          widget.dividaEntity.copyWith(
                            faturas: [
                              ...tratamentoFaturaListaFatura,
                              if (resultVerificacaoFatura.isEmpty)
                                faturaAtual!.copyWith(valor: valorModificado),
                            ],
                          ),
                        );
                      }
                      Navigator.of(context).pop();
                    },
                    child: Text(AppStrings.salvar),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SubDividaRow extends StatelessWidget {
  const _SubDividaRow({
    required this.subDivida,
    required this.corTexto,
    required this.corTextoSecundario,
  });

  final SubDividaEntity subDivida;
  final Color corTexto;
  final Color corTextoSecundario;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              subDivida.nome,
              style: tt.bodySmall?.copyWith(color: corTextoSecundario),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            subDivida.valor.real,
            style: tt.bodySmall?.copyWith(
              color: corTexto,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
