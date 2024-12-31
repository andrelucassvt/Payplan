import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/src/util/entity/devedores_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'devedores_state.dart';

class DevedoresCubit extends Cubit<DevedoresState> {
  DevedoresCubit()
      : super(DevedoresInitial(
          devedores: [],
          totalValorDevedor: 0,
        ));

  String devedoresCampoShared = 'devedores';

  void buscarDevedores() async {
    emit(DevedoresLoading(
      devedores: state.devedores,
      totalValorDevedor: state.totalValorDevedor,
    ));
    final prefs = await SharedPreferences.getInstance();
    final resultDevedores = prefs.getStringList(
          devedoresCampoShared,
        ) ??
        [];
    List<DevedoresEntity> devedores = [];

    devedores = resultDevedores.map(
      (e) {
        return DevedoresEntity.fromJson(json.decode(e));
      },
    ).toList();

    double totalValorDevedor = 0;
    for (var element in devedores) {
      totalValorDevedor += element.valor;
    }

    emit(DevedoresSucesso(
      devedores: devedores,
      totalValorDevedor: totalValorDevedor,
    ));
  }

  void adicionarDevedor(DevedoresEntity devedor) async {
    emit(DevedoresLoading(
      devedores: state.devedores,
      totalValorDevedor: state.totalValorDevedor,
    ));
    final prefs = await SharedPreferences.getInstance();
    final resultDevedores = prefs.getStringList(
          devedoresCampoShared,
        ) ??
        [];
    List<DevedoresEntity> devedores = [];

    devedores = resultDevedores.map(
      (e) {
        return DevedoresEntity.fromJson(json.decode(e));
      },
    ).toList();

    devedores.add(devedor);

    final devedoresEncode = devedores
        .map(
          (e) => json.encode(e.toMap()),
        )
        .toList();
    prefs.setStringList(
      devedoresCampoShared,
      devedoresEncode,
    );

    buscarDevedores();
  }

  void editarDevedor(DevedoresEntity devedor) async {
    emit(DevedoresLoading(
      devedores: state.devedores,
      totalValorDevedor: state.totalValorDevedor,
    ));
    final prefs = await SharedPreferences.getInstance();
    final resultDevedores = prefs.getStringList(
          devedoresCampoShared,
        ) ??
        [];
    List<DevedoresEntity> devedores = [];

    devedores = resultDevedores.map(
      (e) {
        return DevedoresEntity.fromJson(json.decode(e));
      },
    ).toList();

    devedores = devedores.map(
      (e) {
        if (e.id == devedor.id) {
          return devedor;
        }
        return e;
      },
    ).toList();

    final devedoresEncode = devedores
        .map(
          (e) => json.encode(e.toMap()),
        )
        .toList();
    prefs.setStringList(
      devedoresCampoShared,
      devedoresEncode,
    );

    buscarDevedores();
  }

  void deletarDevedor(String id) async {
    emit(DevedoresLoading(
      devedores: state.devedores,
      totalValorDevedor: state.totalValorDevedor,
    ));
    final prefs = await SharedPreferences.getInstance();
    final resultDevedores = prefs.getStringList(
          devedoresCampoShared,
        ) ??
        [];
    List<DevedoresEntity> devedores = [];

    devedores = resultDevedores.map(
      (e) {
        return DevedoresEntity.fromJson(json.decode(e));
      },
    ).toList();

    devedores.removeWhere(
      (element) => element.id == id,
    );

    final devedoresEncode = devedores
        .map(
          (e) => json.encode(e.toMap()),
        )
        .toList();
    prefs.setStringList(
      devedoresCampoShared,
      devedoresEncode,
    );

    buscarDevedores();
  }
}
