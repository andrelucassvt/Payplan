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

class HomeTotalWidget extends StatefulWidget {
  const HomeTotalWidget({
    required this.cubit,
    required this.state,
    required this.isCollapsed,
    required this.onAlturaExpandidaChanged,
    super.key,
  });
  final HomeCubit cubit;
  final HomeState state;
  final bool isCollapsed;

  /// Informa a altura do widget quando totalmente expandido (inclui margens).
  final ValueChanged<double> onAlturaExpandidaChanged;

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
  double? _ultimaAlturaExpandida;

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
    _fontAnim = Tween<double>(begin: 34.0, end: 24.0).animate(_curvedAnim);
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

  void _reportarAlturaExpandida() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.isDismissed) return;
      final altura = context.size?.height;
      if (altura == null || altura == _ultimaAlturaExpandida) return;
      _ultimaAlturaExpandida = altura;
      widget.onAlturaExpandidaChanged(altura);
    });
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
    final tt = Theme.of(context).textTheme;
    final saldo = state.salarioFixo - state.totalGastos;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isDismissed) _reportarAlturaExpandida();
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
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
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.total,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
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
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                    letterSpacing: -0.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
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
                        if (state.salarioFixo > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.saldoRestante,
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                saldo.real,
                                style: tt.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: saldo >= 0 ? cs.onSurface : cs.error,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () =>
                                  _showModalDesconto(state.totalGastos),
                              icon: const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 18,
                              ),
                              label: Text(AppStrings.salario),
                            ),
                            const Spacer(),
                            ValueListenableBuilder<ThemeMode>(
                              valueListenable: ThemeController.themeMode,
                              builder: (context, _, __) {
                                final isDark = ThemeController.isDark(context);
                                return IconButton(
                                  visualDensity: VisualDensity.compact,
                                  color: cs.onSurfaceVariant,
                                  onPressed: () =>
                                      ThemeController.toggle(context),
                                  icon: Icon(
                                    isDark
                                        ? Icons.light_mode_outlined
                                        : Icons.dark_mode_outlined,
                                    size: 20,
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
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final cs = Theme.of(context).colorScheme;
            final tt = Theme.of(context).textTheme;
            final saldo = valorDigitado - valorDesseMes;
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppStrings.salarioFixo, style: tt.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.configureSalarioDesc,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: faturaTextController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: tt.titleLarge,
                      decoration: InputDecoration(
                        labelText: AppStrings.salario,
                        border: const OutlineInputBorder(),
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
                    _PreviewRow(
                      label: AppStrings.salario,
                      value: valorDigitado.real,
                    ),
                    const SizedBox(height: 8),
                    _PreviewRow(
                      label: AppStrings.totalDividas,
                      value: '- ${valorDesseMes.real}',
                    ),
                    const Divider(height: 24),
                    _PreviewRow(
                      label: AppStrings.saldoRestante,
                      value: saldo.real,
                      valueColor: saldo >= 0 ? null : cs.error,
                      bold: true,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          _cubit.salvarSalario(valorDigitado);
                          Navigator.pop(context);
                        },
                        child: Text(AppStrings.salvarSalario),
                      ),
                    ),
                    if (state.salarioFixo > 0) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: cs.error,
                          ),
                          onPressed: () {
                            _cubit.salvarSalario(0.0);
                            Navigator.pop(context);
                          },
                          child: Text(AppStrings.removerSalario),
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
    this.valueColor,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final weight = bold ? FontWeight.w600 : FontWeight.w400;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: tt.bodyMedium?.copyWith(
            color: bold ? cs.onSurface : cs.onSurfaceVariant,
            fontWeight: weight,
          ),
        ),
        Text(
          value,
          style: tt.bodyMedium?.copyWith(
            color: valueColor ?? cs.onSurface,
            fontWeight: weight,
            fontFeatures: const [FontFeature.tabularFigures()],
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
    return Row(
      children: [
        _PeriodoSelector(
          label: state.anoAtual.toString(),
          onTap: () => _showYearPicker(context),
        ),
        const Spacer(),
        ValueListenableBuilder(
          valueListenable: UserController.user,
          builder: (context, user, __) {
            if (user.isPlus) return const SizedBox.shrink();
            return TextButton(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () {
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
              child: Text(AppStrings.semAnuncio),
            );
          },
        ),
        const SizedBox(width: 4),
        PopupMenuButton<MesesEnum>(
          tooltip: '',
          position: PopupMenuPosition.under,
          itemBuilder: (_) => MesesEnum.values
              .map(
                (e) => PopupMenuItem<MesesEnum>(
                  value: e,
                  onTap: () => cubit.mudarMesAtual(e),
                  child: Text(e.nome),
                ),
              )
              .toList(),
          child: _PeriodoSelector(label: state.mesAtual.nome),
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
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodoSelector extends StatelessWidget {
  const _PeriodoSelector({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: cs.onSurface,
                ),
          ),
          Icon(
            Icons.arrow_drop_down,
            size: 20,
            color: cs.onSurfaceVariant,
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: content,
    );
  }
}
