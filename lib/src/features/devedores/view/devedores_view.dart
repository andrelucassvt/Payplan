import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:notes_app/src/features/devedores/cubit/devedores_cubit.dart';
import 'package:notes_app/src/features/devedores/view/widgets/card_devedores_widget.dart';
import 'package:notes_app/src/util/colors/app_colors.dart';
import 'package:notes_app/src/util/entity/devedores_entity.dart';
import 'package:notes_app/src/util/extension/real_format_extension.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';
import 'package:notes_app/src/util/widgets/admob_adaptive_banner.dart';
import 'package:uuid/uuid.dart';

class DevedoresView extends StatefulWidget {
  const DevedoresView({super.key});

  @override
  State<DevedoresView> createState() => _DevedoresViewState();
}

class _DevedoresViewState extends State<DevedoresView> {
  final _cubit = DevedoresCubit();

  @override
  void initState() {
    super.initState();
    _cubit.buscarDevedores();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          AppStrings.devedores,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      body: BlocBuilder<DevedoresCubit, DevedoresState>(
        bloc: _cubit,
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    AppStrings.total,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    state.totalValorDevedor.real,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  InkWell(
                    onTap: () {
                      novoDevedor();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.whiteOpacity,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          AppStrings.novoDevedor,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Divider(),
                  const SizedBox(
                    height: 10,
                  ),
                  ...List.generate(
                    state.devedores.length,
                    (index) {
                      return Column(
                        children: [
                          CardDevedoresWidget(
                            index: index + 1,
                            devedoresEntity: state.devedores[index],
                            devedoresCubit: _cubit,
                            editarDevedor: () {
                              novoDevedor(
                                devedoresEntity: state.devedores[index],
                              );
                            },
                          ),
                          if (index == 0) ...[
                            AdmobAdaptiveBanner(
                              bannerId: Platform.isAndroid
                                  ? 'ca-app-pub-3652623512305285/2185608422'
                                  : 'ca-app-pub-3652623512305285/9922591661',
                            ),
                          ],
                          if (index == 2) ...[
                            AdmobAdaptiveBanner(
                              bannerId: Platform.isAndroid
                                  ? 'ca-app-pub-3652623512305285/9872526753'
                                  : 'ca-app-pub-3652623512305285/4562453770',
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(
                    height: 150,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void novoDevedor({DevedoresEntity? devedoresEntity}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String nome = devedoresEntity?.nome ?? '';
        double valorModificado = devedoresEntity?.valor ?? 0;
        final faturaTextController = MoneyMaskedTextController(
          initialValue: valorModificado,
        );
        final nomeTextController = TextEditingController(text: nome);
        return Container(
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            border: Border.all(
              color: Colors.white,
            ),
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
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller: nomeTextController,
                onChanged: (value) {
                  nome = value;
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: AppStrings.nomeDevedor,
                  labelStyle: TextStyle(
                    color: Colors.white,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              TextField(
                controller: faturaTextController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    final filtro1 = value.replaceAll('.', '');
                    valorModificado =
                        double.parse(filtro1.replaceAll(',', '.'));

                    setState(() {});
                  }
                },
                decoration: InputDecoration(
                  labelText: AppStrings.valor,
                  labelStyle: TextStyle(
                    color: Colors.white,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: () {
                  if (devedoresEntity != null) {
                    _cubit.editarDevedor(
                      DevedoresEntity(
                        id: devedoresEntity.id,
                        nome: nome,
                        valor: valorModificado,
                      ),
                    );
                  } else {
                    _cubit.adicionarDevedor(
                      DevedoresEntity(
                        id: Uuid().v4(),
                        nome: nome,
                        valor: valorModificado,
                      ),
                    );
                  }

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
                child: Text(
                  AppStrings.salvar,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(
                height: 50,
              ),
            ],
          ),
        );
      },
    );
  }
}
