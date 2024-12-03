import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/src/util/entity/divida_entity.dart';
import 'package:notes_app/src/util/enum/meses_enum.dart';
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
          ),
        );

  String dividaCampoShared = 'dividas';

  Future<void> atualizarDivida(DividaEntity dividaEntity) async {
    emit(
      HomeDividasLoading(
        mesAtual: state.mesAtual,
        anoAtual: state.anoAtual,
        isDividas: state.isDividas,
        dividas: state.dividas,
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

    emit(
      HomeDividasSucesso(
        mesAtual: state.mesAtual,
        anoAtual: state.anoAtual,
        isDividas: state.isDividas,
        dividas: dividas.isEmpty ? state.dividas : dividas,
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
      ),
    );
  }

  void mudarAnoAtual(int ano) {
    emit(
      HomeMudarMesAtual(
        mesAtual: state.mesAtual,
        anoAtual: ano,
        isDividas: state.isDividas,
        dividas: state.dividas,
      ),
    );
  }
}
