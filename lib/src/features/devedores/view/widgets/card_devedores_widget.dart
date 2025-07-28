import 'package:flutter/material.dart';
import 'package:notes_app/src/features/devedores/cubit/devedores_cubit.dart';
import 'package:notes_app/src/util/entity/devedores_entity.dart';
import 'package:notes_app/src/util/extension/real_format_extension.dart';
import 'package:notes_app/src/util/service/notification_service.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timezone/timezone.dart' as tz;

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
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: .3),
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.devedoresEntity.nome,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        widget.devedoresEntity.valor.real,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      if (widget.devedoresEntity.pix != null) ...[
                        const SizedBox(
                          height: 10,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meu PIX:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              widget.devedoresEntity.pix!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (widget.devedoresEntity.notificar != null) ...[
                        const SizedBox(
                          height: 10,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.notificar,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '${widget.devedoresEntity.notificar!.day}/${widget.devedoresEntity.notificar!.month}/${widget.devedoresEntity.notificar!.year}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    InkWell(
                      onTap: () async {
                        final result = await NotificationService()
                            .verificarPermissaoNotificacao();

                        if (context.mounted) {
                          if (result) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.blue,
                                content: InkWell(
                                  onTap: () {
                                    openAppSettings();
                                  },
                                  child: Center(
                                    child: Text(
                                      AppStrings.permitirNotificacoes,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          } else {
                            showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(3101),
                            ).then((pickedDate) async {
                              if (pickedDate != null) {
                                if (!context.mounted) return;
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                  initialEntryMode: TimePickerEntryMode.input,
                                );
                                if (pickedTime != null) {
                                  final scheduledDate = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                  try {
                                    widget.devedoresCubit.editarDevedor(
                                      widget.devedoresEntity.copyWith(
                                        notificar: scheduledDate,
                                      ),
                                    );
                                    NotificationService().showLocalNotification(
                                      title: AppStrings.dividasPendentes,
                                      body: AppStrings.mensagemDivida(
                                        widget.devedoresEntity.nome,
                                        widget.devedoresEntity.valor.real,
                                      ),
                                      id: widget.index,
                                      scheduledDate: tz.TZDateTime.from(
                                        scheduledDate,
                                        tz.local,
                                      ),
                                    );
                                  } catch (e, stackTrace) {
                                    debugPrintStack(
                                      label: e.toString(),
                                      stackTrace: stackTrace,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          backgroundColor: Colors.red,
                                          content: Center(
                                            child: Text(
                                              'Error',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              }
                            });
                          }
                        }
                      },
                      child: Icon(
                        widget.devedoresEntity.notificar == null
                            ? Icons.notifications_none_rounded
                            : Icons.notifications_active,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Share.share(
                      '${AppStrings.dividasPendentes}\n\n${widget.devedoresEntity.nome}\n${AppStrings.valor}: ${widget.devedoresEntity.valor.real}${widget.devedoresEntity.pix == null ? '' : '\n\nChave PIX: ${widget.devedoresEntity.pix}'}\n\n${widget.devedoresEntity.message ?? ''}',
                    );
                  },
                  icon: Icon(Icons.attach_money),
                  label: Text(AppStrings.cobrar),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: widget.editarDevedor,
                  icon: Icon(Icons.edit),
                  label: Text('Editar'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    widget.devedoresCubit.deletarDevedor(
                      widget.devedoresEntity.id,
                    );
                  },
                  icon: Icon(Icons.delete),
                  label: Text('Deletar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
