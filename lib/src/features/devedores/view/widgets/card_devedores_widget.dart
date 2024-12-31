import 'package:flutter/material.dart';
import 'package:notes_app/src/features/devedores/cubit/devedores_cubit.dart';
import 'package:notes_app/src/util/entity/devedores_entity.dart';
import 'package:notes_app/src/util/extension/real_format_extension.dart';
import 'package:notes_app/src/util/service/notification_service.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
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
        bottom: 20,
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.devedoresEntity.nome,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      widget.devedoresEntity.valor.real,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Share.share(
                          '${AppStrings.dividasPendentes}\n\n${widget.devedoresEntity.nome}\n${AppStrings.valor}: ${widget.devedoresEntity.valor.real}\n\n${AppStrings.baixePayplan}',
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          AppStrings.cobrar,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.editarDevedor,
                      icon: Icon(
                        Icons.edit,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        widget.devedoresCubit.deletarDevedor(
                          widget.devedoresEntity.id,
                        );
                      },
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(3101),
              ).then((pickedDate) {
                if (pickedDate != null) {
                  widget.devedoresCubit.editarDevedor(
                    widget.devedoresEntity.copyWith(
                      notificar: pickedDate,
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
                      pickedDate,
                      tz.local,
                    ),
                  );
                }
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: 10,
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(.7),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.notificar,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  if (widget.devedoresEntity.notificar == null)
                    Icon(
                      Icons.calendar_month,
                      color: Colors.white,
                    ),
                  if (widget.devedoresEntity.notificar != null)
                    Text(
                      '${widget.devedoresEntity.notificar!.day}/${widget.devedoresEntity.notificar!.month}/${widget.devedoresEntity.notificar!.year}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
