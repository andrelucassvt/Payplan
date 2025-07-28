import 'package:flutter/material.dart';
import 'package:notes_app/src/util/entity/devedores_entity.dart';
import 'package:notes_app/src/util/extension/real_format_extension.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:notes_app/src/util/widgets/glass_container_widget.dart';
import 'package:uuid/uuid.dart';
import 'package:notes_app/src/features/devedores/cubit/devedores_cubit.dart';

Future<void> showNovoDevedorModal({
  required BuildContext context,
  required DevedoresCubit cubit,
  required TextEditingController nomeTextController,
  required TextEditingController pixTextController,
  required TextEditingController faturaTextController,
  required TextEditingController mensagemTextController,
  DevedoresEntity? devedoresEntity,
}) async {
  String nome = devedoresEntity?.nome ?? '';
  String? pix = devedoresEntity?.pix;
  double valorModificado = devedoresEntity?.valor ?? 0;
  nomeTextController.text = nome;
  faturaTextController.text = valorModificado.real;
  pixTextController.text = devedoresEntity?.pix ?? '';
  mensagemTextController.text = devedoresEntity?.message ?? '';

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return GlassContainerWidget(
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.novoDevedor,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nomeTextController,
                  onChanged: (value) {
                    nome = value;
                    setModalState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: AppStrings.nomeDevedor,
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: pixTextController,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      pix = value;
                      setModalState(() {});
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Chave PIX',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: faturaTextController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final filtro1 = value.replaceAll('.', '');
                      valorModificado =
                          double.tryParse(filtro1.replaceAll(',', '.')) ?? 0;
                      setModalState(() {});
                    }
                  },
                  decoration: InputDecoration(
                    labelText: AppStrings.valor,
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: mensagemTextController,
                  onChanged: (value) {
                    setModalState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: AppStrings.mensagem,
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    if (nomeTextController.text.isEmpty) {
                      return;
                    }
                    if (devedoresEntity != null) {
                      cubit.editarDevedor(
                        DevedoresEntity(
                          id: devedoresEntity.id,
                          nome: nome,
                          valor: valorModificado,
                          pix: pix,
                          message: mensagemTextController.text,
                        ),
                      );
                    } else {
                      cubit.adicionarDevedor(
                        DevedoresEntity(
                          id: Uuid().v4(),
                          nome: nome,
                          valor: valorModificado,
                          pix: pix,
                          message: mensagemTextController.text,
                        ),
                      );
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: nomeTextController.text.isEmpty
                        ? Colors.grey
                        : Colors.deepPurple,
                  ),
                  child: Text(
                    AppStrings.salvar,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: 50),
              ],
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    nomeTextController.clear();
  });
}
