import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:notes_app/src/features/home/cubit/home_cubit.dart';
import 'package:notes_app/src/features/plus/view/plus_view.dart';
import 'package:notes_app/src/util/entity/user_entity.dart';
import 'package:notes_app/src/util/enum/meses_enum.dart';
import 'package:notes_app/src/util/extension/real_format_extension.dart';
import 'package:notes_app/src/util/service/theme_controller.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';

const _kAccent = Color(0xFF5C5FEF);

class HomeTotalWidget extends StatefulWidget {
  const HomeTotalWidget({
    required this.cubit,
    required this.state,
    required this.isCollapsed,
    super.key,
  });
  final HomeCubit cubit;
  final HomeState state;
  final bool isCollapsed;

  @override
  State<HomeTotalWidget> createState() => _HomeTotalWidgetState();
}

class _HomeTotalWidgetState extends State<HomeTotalWidget>
    with SingleTickerProviderStateMixin {
  HomeCubit get _cubit => widget.cubit;
  HomeState get state => widget.state;

  late final AnimationController _controller;
  late final CurvedAnimation _curvedAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _sizeAnim;
  late final Animation<double> _fontAnim;
  late final Animation<AlignmentGeometry> _alignAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _curvedAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(_curvedAnim);
    _sizeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(_curvedAnim);
    _fontAnim = Tween<double>(begin: 36.0, end: 24.0).animate(_curvedAnim);
    _alignAnim = AlignmentTween(
      begin: Alignment.centerLeft,
      end: Alignment.center,
    ).animate(_curvedAnim);
  }

  @override
  void didUpdateWidget(HomeTotalWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCollapsed != oldWidget.isCollapsed) {
      if (widget.isCollapsed) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _curvedAnim.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5C5FEF).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRect(
                child: SizeTransition(
                  sizeFactor: _sizeAnim,
                  axisAlignment: -1.0,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TopRow(cubit: _cubit, state: state),
                        const SizedBox(height: 20),
                        Text(
                          AppStrings.total,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurfaceVariant,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: _alignAnim.value,
                child: Text(
                  state.totalGastos.real,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: _fontAnim.value,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              ClipRect(
                child: SizeTransition(
                  sizeFactor: _sizeAnim,
                  axisAlignment: 1.0,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        if (state.salarioFixo > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.saldoRestante,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                (state.salarioFixo - state.totalGastos).real,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      (state.salarioFixo - state.totalGastos) >=
                                              0
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () =>
                                  _showModalDesconto(state.totalGastos),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.account_balance_wallet_outlined,
                                      size: 16,
                                      color: _kAccent,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      AppStrings.salario,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _kAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ValueListenableBuilder<ThemeMode>(
                              valueListenable: ThemeController.themeMode,
                              builder: (context, _, __) {
                                final isDark = ThemeController.isDark(context);
                                return GestureDetector(
                                  onTap: () => ThemeController.toggle(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isDark
                                          ? Icons.light_mode_outlined
                                          : Icons.dark_mode_outlined,
                                      size: 16,
                                      color: _kAccent,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showModalDesconto(double valorDesseMes) {
    final faturaTextController =
        MoneyMaskedTextController(initialValue: state.salarioFixo);
    double valorDigitado = state.salarioFixo;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final cs = Theme.of(context).colorScheme;
            final saldo = valorDigitado - valorDesseMes;
            final saldoPositivo = saldo >= 0;
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _kAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: _kAccent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.salarioFixo,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                AppStrings.configureSalarioDesc,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: faturaTextController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      decoration: InputDecoration(
                        labelText: AppStrings.salario,
                        labelStyle: TextStyle(color: cs.onSurfaceVariant),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _kAccent,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          final filtro1 = value.replaceAll('.', '');
                          valorDigitado =
                              double.tryParse(filtro1.replaceAll(',', '.')) ??
                                  0.0;
                        } else {
                          valorDigitado = 0.0;
                        }
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _PreviewRow(
                            label: AppStrings.salario,
                            value: valorDigitado.real,
                            valueColor: cs.onSurface,
                          ),
                          const SizedBox(height: 10),
                          _PreviewRow(
                            label: AppStrings.totalDividas,
                            value: '- ${valorDesseMes.real}',
                            valueColor: const Color(0xFFEF4444),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Divider(
                              color: cs.outlineVariant,
                              height: 1,
                            ),
                          ),
                          _PreviewRow(
                            label: AppStrings.saldoRestante,
                            value: saldo.real,
                            valueColor: saldoPositivo
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          _cubit.salvarSalario(valorDigitado);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          AppStrings.salvarSalario,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (state.salarioFixo > 0) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: TextButton(
                          onPressed: () {
                            _cubit.salvarSalario(0.0);
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            AppStrings.removerSalario,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 14 : 13,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            color: cs.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({required this.cubit, required this.state});
  final HomeCubit cubit;
  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => _showYearPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  state.anoAtual.toString(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            ValueListenableBuilder(
              valueListenable: UserController.user,
              builder: (context, user, __) {
                if (user.isPlus) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.8,
                      ),
                      builder: (_) => const PlusView(),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3F3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          AppStrings.semAnuncio,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.block,
                          size: 13,
                          color: Color(0xFFEF4444),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            PopupMenuButton<MesesEnum>(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 16,
                      color: _kAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.mesAtual.nome,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              itemBuilder: (_) => MesesEnum.values
                  .map(
                    (e) => PopupMenuItem<MesesEnum>(
                      value: e,
                      onTap: () => cubit.mudarMesAtual(e),
                      child: Text(e.nome),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ],
    );
  }

  void _showYearPicker(BuildContext context) {
    final scrollController = FixedExtentScrollController(
      initialItem: state.anoAtual - 2024,
    );
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 216,
        color: Theme.of(ctx).colorScheme.surface,
        child: CupertinoPicker(
          itemExtent: 50,
          scrollController: scrollController,
          onSelectedItemChanged: (index) => cubit.mudarAnoAtual(2024 + index),
          children: List.generate(
            100,
            (index) => Center(
              child: Text(
                (2024 + index).toString(),
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
