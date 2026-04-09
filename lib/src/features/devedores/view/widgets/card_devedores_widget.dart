import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notes_app/src/features/devedores/cubit/devedores_cubit.dart';
import 'package:notes_app/src/util/entity/devedores_entity.dart';
import 'package:notes_app/src/util/extension/real_format_extension.dart';
import 'package:notes_app/src/util/service/notification_service.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timezone/timezone.dart' as tz;

const _kAccent = Color(0xFF5C5FEF);

class CardDevedoresWidget extends StatefulWidget {
  const CardDevedoresWidget({
    required this.devedoresEntity,
    required this.devedoresCubit,
    required this.editarDevedor,
    required this.index,
    super.key,
  });
  final DevedoresEntity devedoresEntity;
  final DevedoresCubit devedoresCubit;
  final VoidCallback editarDevedor;
  final int index;

  @override
  State<CardDevedoresWidget> createState() => _CardDevedoresWidgetState();
}

class _CardDevedoresWidgetState extends State<CardDevedoresWidget> {
  DevedoresEntity get entity => widget.devedoresEntity;
  bool _expandedParcelas = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // — Header row: name + notification icon —
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entity.nome,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entity.valorPendente.real,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: entity.parcelas.isNotEmpty &&
                                entity.parcelas.every((p) => p.pago)
                            ? const Color(0xFF10B981)
                            : _kAccent,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (entity.parcelas.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        entity.parcelas.every((p) => p.pago)
                            ? AppStrings.quitado
                            : '${entity.parcelas.where((p) => p.pago).length}/${entity.parcelas.length} quitadas',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: entity.parcelas.every((p) => p.pago)
                              ? const Color(0xFF10B981)
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              InkWell(
                onTap: () => _handleNotificacao(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    entity.notificar == null
                        ? Icons.notifications_none_rounded
                        : Icons.notifications_active_rounded,
                    size: 20,
                    color: entity.notificar == null
                        ? cs.onSurfaceVariant
                        : _kAccent,
                  ),
                ),
              ),
            ],
          ),
          // — PIX —
          if (entity.pix != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: entity.pix!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIX copiado!'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pix, size: 16, color: _kAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entity.pix!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.copy_outlined,
                          size: 16, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
          // — Notificar —
          if (entity.notificar != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 13, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${AppStrings.notificar}: '
                  '${entity.notificar!.day.toString().padLeft(2, '0')}/'
                  '${entity.notificar!.month.toString().padLeft(2, '0')}/'
                  '${entity.notificar!.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          // — Divider + action buttons —
          const SizedBox(height: 12),
          if (entity.parcelas.isNotEmpty) ...[
            Divider(
              color: Theme.of(context).colorScheme.outlineVariant,
              height: 1,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
              child: Column(
                children: [
                  ...(_expandedParcelas
                          ? entity.parcelas
                          : entity.parcelas.take(3).toList())
                      .map(
                    (parcela) => _ParcelaRow(
                      parcela: parcela,
                      total: entity.parcelas.length,
                      onToggle: (value) =>
                          widget.devedoresCubit.toggleParcelaPaga(
                        entity.id,
                        parcela.numero,
                        value,
                      ),
                    ),
                  ),
                  if (entity.parcelas.length > 3) ...[
                    const Divider(height: 8, thickness: 0.5),
                    GestureDetector(
                      onTap: () => setState(
                        () => _expandedParcelas = !_expandedParcelas,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _expandedParcelas
                                  ? AppStrings.verMenos
                                  : AppStrings.verMais(
                                      entity.parcelas.length - 3,
                                    ),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _kAccent,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _expandedParcelas
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: _kAccent,
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
          Divider(
              color: Theme.of(context).colorScheme.outlineVariant, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              _ActionChip(
                icon: Icons.attach_money_rounded,
                label: AppStrings.cobrar,
                color: const Color(0xFF10B981),
                onTap: () => Share.share(
                  '${AppStrings.dividasPendentes}\n\n${entity.nome}\n'
                  '${AppStrings.valor}: ${entity.valorPendente.real}'
                  '${entity.pix == null ? '' : '\n\nChave PIX: ${entity.pix}'}'
                  '\n\n${entity.message ?? ''}',
                ),
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.edit_outlined,
                label: 'Editar',
                color: _kAccent,
                onTap: widget.editarDevedor,
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.delete_outline_rounded,
                label: 'Deletar',
                color: const Color(0xFFEF4444),
                onTap: () => widget.devedoresCubit.deletarDevedor(entity.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleNotificacao(BuildContext context) async {
    final denied = await NotificationService().verificarPermissaoNotificacao();
    if (!context.mounted) return;

    if (denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.blue,
          content: InkWell(
            onTap: openAppSettings,
            child: Center(
              child: Text(
                AppStrings.permitirNotificacoes,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      );
      return;
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(3101),
    );
    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (pickedTime == null) return;

    final scheduledDate = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    try {
      widget.devedoresCubit.editarDevedor(
        entity.copyWith(notificar: scheduledDate),
      );
      NotificationService().showLocalNotification(
        title: AppStrings.dividasPendentes,
        body: AppStrings.mensagemDivida(entity.nome, entity.valor.real),
        id: widget.index,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      );
    } catch (error, stackTrace) {
      debugPrintStack(label: error.toString(), stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Center(child: Text('Erro ao agendar notificação')),
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------

class _ParcelaRow extends StatelessWidget {
  const _ParcelaRow({
    required this.parcela,
    required this.total,
    required this.onToggle,
  });

  final ParcelaDevedorEntity parcela;
  final int total;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.parcelaNumero(parcela.numero, total),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: parcela.pago ? cs.onSurfaceVariant : cs.onSurface,
                    decoration:
                        parcela.pago ? TextDecoration.lineThrough : null,
                    decorationColor: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  parcela.valor.real,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: parcela.pago ? cs.onSurfaceVariant : _kAccent,
                    decoration:
                        parcela.pago ? TextDecoration.lineThrough : null,
                    decorationColor: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: parcela.pago,
              activeColor: const Color(0xFF10B981),
              onChanged: onToggle,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
