import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/src/util/entity/divida_entity.dart';
import 'package:notes_app/src/util/model/divida_model.dart';
import 'package:notes_app/src/util/entity/user_entity.dart';
import 'package:notes_app/src/util/enum/meses_enum.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit()
      : super(
          HomeInitial(
            mesAtual: MesesEnum.values.firstWhere(
              (element) => element.id == DateTime.now().month,
            ),
            anoAtual: DateTime.now().year,
            isDividas: true,
            dividas: [],
            totalGastos: 0,
            salarioFixo: 0,
          ),
        );

  bool temDividas() {
    return state.dividas.isNotEmpty;
  }

  String dividaCampoShared = 'dividas';

  Future<void> verificarVersao() async {
    const url =
        'https://raw.githubusercontent.com/andrelucassvt/Payplan/refs/heads/main/version-app.json';

    final dio = Dio();

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.data);

        final versionUrl =
            int.parse((data['version'] as String).replaceAll('.', ''));
        final versionCurrent =
            int.parse(packageInfo.version.replaceAll('.', ''));

        if (versionUrl > versionCurrent) {
          emit(
            HomeVersaoNova(
              mesAtual: state.mesAtual,
              anoAtual: state.anoAtual,
              isDividas: state.isDividas,
              dividas: state.dividas,
              totalGastos: state.totalGastos,
              salarioFixo: state.salarioFixo,
            ),
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removerDivida(DividaEntity dividaEntity) async {
    emit(
      HomeDividasLoading(
        mesAtual: state.mesAtual,
        anoAtual: state.anoAtual,
        isDividas: state.isDividas,
        dividas: state.dividas,
        totalGastos: state.totalGastos,
        salarioFixo: state.salarioFixo,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    final resultDividas = prefs.getStringList(dividaCampoShared) ?? [];

    final dividas = resultDividas
        .map((e) => DividaModel.fromJson(json.decode(e)))
        .toList()
      ..removeWhere((element) => element.id == dividaEntity.id);

    prefs.setStringList(
      dividaCampoShared,
      dividas.map((e) => json.encode(e.toJson())).toList(),
    );
    buscarDividas();
  }

  Future<void> atualizarDivida(DividaEntity dividaEntity) async {
    emit(
      HomeDividasLoading(
        mesAtual: state.mesAtual,
        anoAtual: state.anoAtual,
        isDividas: state.isDividas,
        dividas: state.dividas,
        totalGastos: state.totalGastos,
        salarioFixo: state.salarioFixo,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    final resultDividas = prefs.getStringList(dividaCampoShared) ?? [];

    final dividas = resultDividas
        .map((e) => DividaModel.fromJson(json.decode(e)))
        .toList()
        .map(
          (e) => e.id == dividaEntity.id
              ? DividaModel.fromEntity(dividaEntity)
              : e,
        )
        .toList();

    prefs.setStringList(
      dividaCampoShared,
      dividas.map((e) => json.encode(e.toJson())).toList(),
    );
    buscarDividas();
  }

  Future<void> salvarDivida(DividaEntity dividaEntity) async {
    emit(
      HomeDividasLoading(
        mesAtual: state.mesAtual,
        anoAtual: state.anoAtual,
        isDividas: state.isDividas,
        dividas: state.dividas,
        totalGastos: state.totalGastos,
        salarioFixo: state.salarioFixo,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    final resultDividas = prefs.getStringList(dividaCampoShared) ?? [];

    resultDividas.add(
      json.encode(DividaModel.fromEntity(dividaEntity).toJson()),
    );
    prefs.setStringList(dividaCampoShared, resultDividas);
    buscarDividas();
  }

  void buscarDividas() async {
    emit(
      HomeDividasLoading(
        mesAtual: state.mesAtual,
        anoAtual: state.anoAtual,
        isDividas: state.isDividas,
        dividas: state.dividas,
        totalGastos: state.totalGastos,
        salarioFixo: state.salarioFixo,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    final result = prefs.getStringList(dividaCampoShared) ?? [];

    final dividas =
        result.map((e) => DividaModel.fromJson(json.decode(e))).toList();

    final somaGastos = dividas.fold<double>(
      0.0,
      (soma, divida) =>
          soma + divida.totalNaoPagoDoMes(state.anoAtual, state.mesAtual.id),
    );

    final salarioFixo = prefs.getDouble('salario_fixo') ?? 0.0;
    emit(
      HomeDividasSucesso(
        mesAtual: state.mesAtual,
        anoAtual: state.anoAtual,
        isDividas: state.isDividas,
        dividas: dividas.isEmpty ? state.dividas : dividas,
        totalGastos: somaGastos,
        salarioFixo: salarioFixo,
      ),
    );
  }

  void mudarListagem() {
    emit(
      HomeMudarMesAtual(
        mesAtual: state.mesAtual,
        anoAtual: state.anoAtual,
        isDividas: !state.isDividas,
        dividas: state.dividas,
        totalGastos: state.totalGastos,
        salarioFixo: state.salarioFixo,
      ),
    );
  }

  void mudarMesAtual(MesesEnum mes) {
    emit(
      HomeMudarMesAtual(
        mesAtual: mes,
        anoAtual: state.anoAtual,
        isDividas: state.isDividas,
        dividas: state.dividas,
        totalGastos: state.totalGastos,
        salarioFixo: state.salarioFixo,
      ),
    );
    buscarDividas();
  }

  void mudarAnoAtual(int ano) {
    emit(
      HomeMudarMesAtual(
        mesAtual: state.mesAtual,
        anoAtual: ano,
        isDividas: state.isDividas,
        dividas: state.dividas,
        totalGastos: state.totalGastos,
        salarioFixo: state.salarioFixo,
      ),
    );
    buscarDividas();
  }

  void buscarIsPlus() async {
    final prefs = await SharedPreferences.getInstance();
    final isPlus = prefs.getBool('isPlus') ?? false;
    UserController.setUser(
      UserEntity(isPlus: isPlus),
    );
  }

  Future<void> adicionarSubDivida(
    DividaEntity divida,
    SubDividaEntity subDivida,
  ) async {
    await atualizarDivida(
      divida.copyWith(
        subDividas: [...divida.subDividas, subDivida],
      ),
    );
  }

  Future<void> removerSubDivida(
    DividaEntity divida,
    String subDividaId,
  ) async {
    await atualizarDivida(
      divida.copyWith(
        subDividas:
            divida.subDividas.where((s) => s.id != subDividaId).toList(),
      ),
    );
  }

  Future<void> atualizarSubDivida(
    DividaEntity divida,
    SubDividaEntity subDividaAtualizada,
  ) async {
    await atualizarDivida(
      divida.copyWith(
        subDividas: divida.subDividas
            .map(
                (s) => s.id == subDividaAtualizada.id ? subDividaAtualizada : s)
            .toList(),
      ),
    );
  }

  Future<void> salvarSalario(double valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('salario_fixo', valor);
    emit(
      HomeDividasSucesso(
        mesAtual: state.mesAtual,
        anoAtual: state.anoAtual,
        isDividas: state.isDividas,
        dividas: state.dividas,
        totalGastos: state.totalGastos,
        salarioFixo: valor,
      ),
    );
  }
}
