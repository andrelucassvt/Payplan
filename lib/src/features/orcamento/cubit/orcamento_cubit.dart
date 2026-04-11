import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notes_app/src/util/entity/orcamento_entity.dart';
import 'package:notes_app/src/util/model/orcamento_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'orcamento_state.dart';

class OrcamentoCubit extends Cubit<OrcamentoState> {
  OrcamentoCubit()
      : super(
          OrcamentoInitial(
            orcamentos: [],
            totalGeral: 0,
          ),
        );

  final String _campoShared = 'orcamentos';

  bool temOrcamentos() => state.orcamentos.isNotEmpty;

  Future<void> buscarOrcamentos() async {
    emit(
      OrcamentoLoading(
        orcamentos: state.orcamentos,
        totalGeral: state.totalGeral,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final result = prefs.getStringList(_campoShared) ?? [];
    final orcamentos =
        result.map((e) => OrcamentoModel.fromJson(json.decode(e))).toList();

    final total = orcamentos.fold<double>(
      0.0,
      (soma, o) => soma + o.totalOrcamento,
    );

    emit(
      OrcamentoSucesso(
        orcamentos: orcamentos,
        totalGeral: total,
      ),
    );
  }

  Future<void> salvarOrcamento(OrcamentoEntity orcamento) async {
    emit(
      OrcamentoLoading(
        orcamentos: state.orcamentos,
        totalGeral: state.totalGeral,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final result = prefs.getStringList(_campoShared) ?? [];
    result.add(json.encode(OrcamentoModel.fromEntity(orcamento).toJson()));
    await prefs.setStringList(_campoShared, result);

    buscarOrcamentos();
  }

  Future<void> atualizarOrcamento(OrcamentoEntity orcamento) async {
    emit(
      OrcamentoLoading(
        orcamentos: state.orcamentos,
        totalGeral: state.totalGeral,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final result = prefs.getStringList(_campoShared) ?? [];
    final orcamentos = result
        .map((e) => OrcamentoModel.fromJson(json.decode(e)))
        .toList()
        .map(
          (e) =>
              e.id == orcamento.id ? OrcamentoModel.fromEntity(orcamento) : e,
        )
        .toList();

    await prefs.setStringList(
      _campoShared,
      orcamentos.map((e) => json.encode(e.toJson())).toList(),
    );

    buscarOrcamentos();
  }

  Future<void> removerOrcamento(OrcamentoEntity orcamento) async {
    emit(
      OrcamentoLoading(
        orcamentos: state.orcamentos,
        totalGeral: state.totalGeral,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final result = prefs.getStringList(_campoShared) ?? [];
    final orcamentos = result
        .map((e) => OrcamentoModel.fromJson(json.decode(e)))
        .toList()
      ..removeWhere((e) => e.id == orcamento.id);

    await prefs.setStringList(
      _campoShared,
      orcamentos.map((e) => json.encode(e.toJson())).toList(),
    );

    buscarOrcamentos();
  }

  Future<void> adicionarSubItem(
    OrcamentoEntity orcamento,
    SubItemOrcamentoEntity subItem,
  ) async {
    await atualizarOrcamento(
      orcamento.copyWith(
        subItens: [...orcamento.subItens, subItem],
      ),
    );
  }

  Future<void> removerSubItem(
    OrcamentoEntity orcamento,
    String subItemId,
  ) async {
    await atualizarOrcamento(
      orcamento.copyWith(
        subItens: orcamento.subItens.where((s) => s.id != subItemId).toList(),
      ),
    );
  }
}
