import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:intl/intl.dart';
import 'package:notes_app/src/features/home/cubit/home_cubit.dart';
import 'package:notes_app/src/features/nova_divida/view/nova_divida_view.dart';
import 'package:notes_app/src/util/entity/divida_entity.dart';
import 'package:notes_app/src/util/entity/user_entity.dart';
import 'package:notes_app/src/util/enum/meses_enum.dart';
import 'package:notes_app/src/util/service/ads/app_open_ad_service.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:uuid/uuid.dart';

const _kAccent = Color(0xFF5C5FEF);

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
  final format = NumberFormat.currency(locale: "pt_BR", symbol: "");
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

    final cs = Theme.of(context).colorScheme;
    final cor = widget.dividaEntity.cor;
    final isPaid = faturaAtual!.pago;
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
                        widget.dividaEntity.nome.isNotEmpty
                            ? widget.dividaEntity.nome[0].toUpperCase()
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
                          widget.dividaEntity.nome,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!widget.dividaEntity.mensal &&
                            _numeroParcela != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              AppStrings.parcelaNumero(
                                _numeroParcela!,
                                widget.dividaEntity.faturas.length,
                              ),
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
                      color:
                          Colors.white.withValues(alpha: isPaid ? 0.28 : 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white
                            .withValues(alpha: isPaid ? 0.65 : 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPaid
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPaid ? AppStrings.paga : AppStrings.naoPaga,
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

            // ── Valor + Switch ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.valorDesseMes,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurfaceVariant,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'R\$ ${format.format(totalDoMes)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isPaid ? cs.onSurfaceVariant : cs.onSurface,
                            decoration:
                                isPaid ? TextDecoration.lineThrough : null,
                            decorationColor: cs.onSurfaceVariant,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    alignment: Alignment.centerRight,
                    scale: 0.9,
                    child: Switch(
                      value: isPaid,
                      activeColor: const Color(0xFF10B981),
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
                  ),
                ],
              ),
            ),

            // ── Sub-dívidas ──
            if (subDividasDoMes.isNotEmpty) ...[
              Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  children: [
                    ...(_expandedSubDividas
                            ? subDividasDoMes
                            : subDividasDoMes.take(3).toList())
                        .map(
                      (s) => _SubDividaRow(
                        subDivida: s,
                        mesAtual: homeState.mesAtual,
                      ),
                    ),
                    if (subDividasDoMes.length > 3) ...[
                      const Divider(height: 8, thickness: 0.5),
                      GestureDetector(
                        onTap: () => setState(
                          () => _expandedSubDividas = !_expandedSubDividas,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _expandedSubDividas
                                    ? 'Ver menos'
                                    : 'Ver mais (${subDividasDoMes.length - 3})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: cor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _expandedSubDividas
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
              child: ValueListenableBuilder(
                valueListenable: UserController.user,
                builder: (context, user, ___) {
                  return Row(
                    children: [
                      _ActionChip(
                        label: AppStrings.editarFatura,
                        cor: cor,
                        onTap: () => _editarFaturaBottomSheet(user.isPlus),
                      ),
                      const SizedBox(width: 8),
                      _ActionChip(
                        label: AppStrings.subDividas,
                        cor: cor,
                        onTap: _gerenciarSubDividasBottomSheet,
                      ),
                      const Spacer(),
                      _ActionChip(
                        icon: Icons.edit_outlined,
                        cor: cor,
                        onTap: () {
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
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final cs = Theme.of(sheetContext).colorScheme;
            final subDividas = widget.dividaEntity.subDividas;
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
                      if (subDividas.isEmpty)
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
                            itemCount: subDividas.length,
                            itemBuilder: (context, index) {
                              final s = subDividas[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  s.recorrente
                                      ? Icons.repeat
                                      : Icons.calendar_today_outlined,
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
                                subtitle: Text(
                                  s.recorrente
                                      ? AppStrings.recorrente
                                      : '${MesesEnum.values.firstWhere((e) => e.id == s.mes).nome}/${s.ano}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '\$${format.format(s.valor)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => _editarSubDividaDialog(
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
                                        widget.homeCubit.removerSubDivida(
                                          widget.dividaEntity,
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
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            AppStrings.recorrente,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: isRecorrente,
                            activeColor: _kAccent,
                            onChanged: (v) =>
                                setSheetState(() => isRecorrente = v),
                          ),
                        ],
                      ),
                      if (!isRecorrente)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${AppStrings.unicaNoMes}: '
                            '${homeState.mesAtual.nome}/${homeState.anoAtual}',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
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
                            widget.homeCubit.adicionarSubDivida(
                              widget.dividaEntity,
                              SubDividaEntity(
                                id: const Uuid().v4(),
                                nome: nomeController.text.trim(),
                                valor: novoValor,
                                recorrente: isRecorrente,
                                mes:
                                    isRecorrente ? null : homeState.mesAtual.id,
                                ano: isRecorrente ? null : homeState.anoAtual,
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
                widget.homeCubit.atualizarSubDivida(
                  widget.dividaEntity,
                  subDivida.copyWith(nome: nome, valor: novoValor),
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

  void _editarFaturaBottomSheet(bool isPlus) {
    if (!isPlus) {
      AppOpenAdService.instance.show();
    }
    double valorModificado = 0;
    _faturaTextController.updateValue(faturaAtual!.valor);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
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
                  AppStrings.editarFatura,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _faturaTextController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: AppStrings.valorParcela,
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
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final filtro1 = value.replaceAll('.', '');
                      valorModificado =
                          double.parse(filtro1.replaceAll(',', '.'));
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 24),
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
        );
      },
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip(
      {this.label, this.icon, required this.cor, required this.onTap});
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

class _SubDividaRow extends StatelessWidget {
  const _SubDividaRow({
    required this.subDivida,
    required this.mesAtual,
  });

  final SubDividaEntity subDivida;
  final MesesEnum mesAtual;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: '');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            subDivida.recorrente ? Icons.repeat : Icons.calendar_today_outlined,
            size: 12,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              subDivida.nome,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '\$${fmt.format(subDivida.valor)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
