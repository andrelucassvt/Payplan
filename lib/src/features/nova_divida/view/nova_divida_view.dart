import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:notes_app/src/features/home/cubit/home_cubit.dart';
import 'package:notes_app/src/util/colors/app_colors.dart';
import 'package:notes_app/src/util/entity/divida_entity.dart';
import 'package:notes_app/src/util/strings/app_strings.dart';

class NovaDividaView extends StatefulWidget {
  const NovaDividaView({
    required this.homeCubit,
    this.dividaEntity,
    super.key,
  });
  final HomeCubit homeCubit;
  final DividaEntity? dividaEntity;

  @override
  State<NovaDividaView> createState() => _NovaDividaViewState();
}

class _NovaDividaViewState extends State<NovaDividaView> {
  Color corSelecionada = Colors.red;
  String nomeDivida = '';
  bool isMensal = true;
  int quantidadeParcelas = 1;
  double valorParcela = 0.0;
  final _faturaTextController = MoneyMaskedTextController(initialValue: 0.00);
  //final format = NumberFormat.currency(locale: "pt_BR", symbol: "");
  final List<Color> _listColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.amber,
    Colors.brown,
    Colors.cyan,
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppStrings.novaDivida,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (nomeDivida.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppStrings.digiteONomeDivida,
                ),
              ),
            );
          } else if (!isMensal && valorParcela == 0.0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppStrings.valorParcela,
                ),
              ),
            );
          }
        },
        label: Text(
          AppStrings.salvar,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 20,
              ),
              Container(
                padding: EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: corSelecionada,
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 80,
                    ),
                    Text(
                      AppStrings.nomeDaDivida,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Text(
                      nomeDivida,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.whiteOpacity,
                  ),
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                ),
                child: TextFormField(
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: AppStrings.digiteONomeDivida,
                  ),
                  onChanged: (value) {
                    setState(() {
                      nomeDivida = value;
                    });
                  },
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                AppStrings.corDaDivida,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Wrap(
                runSpacing: 10,
                spacing: 10,
                children: _listColors
                    .map(
                      (e) => InkWell(
                        onTap: () {
                          setState(() {
                            corSelecionada = e;
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: e,
                          child: corSelecionada == e
                              ? Center(
                                  child: Icon(
                                    Icons.check,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                AppStrings.naoPodeModificar,
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CupertinoSegmentedControl<bool>(
                    groupValue: isMensal,
                    padding: EdgeInsets.zero,
                    children: <bool, Widget>{
                      true: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        child: Text(
                          AppStrings.mensal,
                        ),
                      ),
                      false: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Text(
                          AppStrings.parcelada,
                        ),
                      ),
                    },
                    onValueChanged: (value) {
                      setState(() {
                        isMensal = value;
                      });
                    },
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  if (!isMensal) ...[
                    PopupMenuButton<int>(
                      child: Text(
                        '${quantidadeParcelas}x',
                        style: TextStyle(
                          fontSize: 25,
                          color: Colors.white,
                        ),
                      ),
                      itemBuilder: (context) {
                        return List.generate(
                          48,
                          (index) {
                            return PopupMenuItem<int>(
                              value: index + 1,
                              child: Text(
                                (index + 1).toString(),
                              ),
                              onTap: () {
                                setState(() {
                                  quantidadeParcelas = index + 1;
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ],
              ),
              if (!isMensal) ...[
                const SizedBox(
                  height: 20,
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.whiteOpacity,
                    ),
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: TextFormField(
                    controller: _faturaTextController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration.collapsed(
                      hintText: AppStrings.valorParcela,
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value.isNotEmpty) {
                          final filtro1 = value.replaceAll('.', '');
                          valorParcela =
                              double.parse(filtro1.replaceAll(',', '.'));
                        }
                      });
                    },
                  ),
                ),
              ],
              const SizedBox(
                height: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
