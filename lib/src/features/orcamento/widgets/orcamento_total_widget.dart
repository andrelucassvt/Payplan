import 'package:flutter/material.dart';
import 'package:notes_app/src/features/orcamento/cubit/orcamento_cubit.dart';
import 'package:notes_app/src/util/extension/real_format_extension.dart';
import 'package:notes_app/src/util/service/theme_controller.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';

const _kAccent = Color(0xFF5C5FEF);

class OrcamentoTotalWidget extends StatefulWidget {
  const OrcamentoTotalWidget({
    required this.cubit,
    required this.state,
    required this.isCollapsed,
    super.key,
  });

  final OrcamentoCubit cubit;
  final OrcamentoState state;
  final bool isCollapsed;

  @override
  State<OrcamentoTotalWidget> createState() => _OrcamentoTotalWidgetState();
}

class _OrcamentoTotalWidgetState extends State<OrcamentoTotalWidget>
    with SingleTickerProviderStateMixin {
  OrcamentoState get state => widget.state;

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
  void didUpdateWidget(OrcamentoTotalWidget oldWidget) {
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
                        Row(
                          children: [
                            Text(
                              AppStrings.orcamentos,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            const Spacer(),
                            ValueListenableBuilder<ThemeMode>(
                              valueListenable: ThemeController.themeMode,
                              builder: (context, _, __) {
                                final isDark = ThemeController.isDark(context);
                                return GestureDetector(
                                  onTap: () => ThemeController.toggle(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(10),
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
                        const SizedBox(height: 20),
                        Text(
                          AppStrings.totalOrcamentos,
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
                  state.totalGeral.real,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: _fontAnim.value,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
