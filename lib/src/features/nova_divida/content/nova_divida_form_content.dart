import 'package:flutter/material.dart';
import 'package:notes_app/src/util/extension/real_format_extension.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';

class NovaDividaCardPreview extends StatelessWidget {
  const NovaDividaCardPreview({
    required this.cor,
    required this.nome,
    required this.tipo,
    this.valorParcela,
    super.key,
  });

  final Color cor;
  final String nome;
  final String tipo;
  final double? valorParcela;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final onCor = ThemeData.estimateBrightnessForColor(cor) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final onCorSecundario = onCor.withValues(alpha: 0.72);
    final valor = valorParcela;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: AspectRatio(
          aspectRatio: 1.586,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 30,
                      decoration: BoxDecoration(
                        color: onCor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.contactless_outlined, color: onCorSecundario),
                  ],
                ),
                const Spacer(),
                Text(
                  '••••  ••••  ••••  ••••',
                  style: tt.titleMedium?.copyWith(
                    color: onCorSecundario,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        nome.isEmpty ? AppStrings.nomeDaDivida : nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleLarge?.copyWith(
                          color: nome.isEmpty ? onCorSecundario : onCor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tipo,
                          style: tt.labelMedium?.copyWith(
                            color: onCorSecundario,
                          ),
                        ),
                        if (valor != null && valor > 0)
                          Text(
                            valor.real,
                            style: tt.titleSmall?.copyWith(color: onCor),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NovaDividaSectionTitle extends StatelessWidget {
  const NovaDividaSectionTitle({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class NovaDividaColorPicker extends StatelessWidget {
  const NovaDividaColorPicker({
    required this.colors,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((cor) {
        final isSelected = cor == selected;
        return Semantics(
          button: true,
          selected: isSelected,
          child: GestureDetector(
            onTap: () => onChanged(cor),
            child: Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? cs.onSurface : Colors.transparent,
                  width: 2,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
