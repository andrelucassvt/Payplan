import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/src/util/entity/divida_entity.dart';
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
          ),
        );

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
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    final resultDividas = prefs.getStringList(
          dividaCampoShared,
        ) ??
        [];
    List<DividaEntity> dividas = [];

    dividas = resultDividas.map(
      (e) {
        return DividaEntity.fromJson(json.decode(e));
      },
    ).toList();

    dividas.removeWhere(
      (element) => element.id == dividaEntity.id,
    );

    final dividasEncode = dividas
        .map(
          (e) => json.encode(e.toMap()),
        )
        .toList();
    prefs.setStringList(
      dividaCampoShared,
      dividasEncode,
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
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    final resultDividas = prefs.getStringList(
          dividaCampoShared,
        ) ??
        [];
    List<DividaEntity> dividas = [];

    dividas = resultDividas.map(
      (e) {
        return DividaEntity.fromJson(json.decode(e));
      },
    ).toList();

    dividas = dividas.map(
      (e) {
        if (e.id == dividaEntity.id) {
          return dividaEntity;
        }
        return e;
      },
    ).toList();

    final dividasEncode = dividas
        .map(
          (e) => json.encode(e.toMap()),
        )
        .toList();
    prefs.setStringList(
      dividaCampoShared,
      dividasEncode,
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
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    final resultDividas = prefs.getStringList(
          dividaCampoShared,
        ) ??
        [];
    final dividaConvert = json.encode(dividaEntity.toMap());

    resultDividas.add(dividaConvert);
    prefs.setStringList(
      dividaCampoShared,
      resultDividas,
    );
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
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    final result = prefs.getStringList(
          dividaCampoShared,
        ) ??
        [];

    List<DividaEntity> dividas = [];

    dividas = result.map(
      (e) {
        return DividaEntity.fromJson(json.decode(e));
      },
    ).toList();

    final filtroGastos = dividas
        .map(
          (e) => e.faturas
              .where(
                (element) =>
                    element.ano == state.anoAtual &&
                    element.mes == state.mesAtual.id &&
                    !element.pago,
              )
              .toList(),
        )
        .toList();

    double somaGastos = 0;

    filtroGastos
        .map(
          (e) => e.map(
            (e) {
              somaGastos = somaGastos + e.valor;
            },
          ).toList(),
        )
        .toList();

    emit(
      HomeDividasSucesso(
        mesAtual: state.mesAtual,
        anoAtual: state.anoAtual,
        isDividas: state.isDividas,
        dividas: dividas.isEmpty ? state.dividas : dividas,
        totalGastos: somaGastos,
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
}
