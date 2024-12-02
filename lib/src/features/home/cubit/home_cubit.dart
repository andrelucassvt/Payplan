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
    );

    List<DividaEntity> dividas = [];

    if (result != null) {
      dividas = result.map(
        (e) {
          return DividaEntity.fromJson(json.decode(e));
        },
      ).toList();
    }

    emit(
      HomeDividasSucesso(
        mesAtual: state.mesAtual,
        anoAtual: state.anoAtual,
        isDividas: state.isDividas,
        dividas: dividas.isEmpty ? state.dividas : dividas,
      ),
    );
  }

  void salvarDivida(DividaEntity entity) async {
    emit(
      HomeDividasLoading(
        mesAtual: state.mesAtual,
        anoAtual: state.anoAtual,
        isDividas: state.isDividas,
        dividas: state.dividas,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
      dividaCampoShared,
      [],
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
