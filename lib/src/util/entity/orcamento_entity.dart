import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class OrcamentoEntity {
  const OrcamentoEntity({
    required this.id,
    required this.nome,
    required this.cor,
    required this.valor,
    this.subItens = const [],
  });

  final String id;
  final String nome;
  final Color cor;

  /// Valor fixo do orçamento, usado quando [subItens] está vazio.
  final double valor;

  final List<SubItemOrcamentoEntity> subItens;

  /// Retorna o total do orçamento.
  /// Se não houver sub-itens, retorna [valor].
  /// Se houver sub-itens, retorna a soma dos valores dos sub-itens.
  double get totalOrcamento {
    if (subItens.isEmpty) return valor;
    return subItens.fold(0.0, (soma, s) => soma + s.valor);
  }

  OrcamentoEntity copyWith({
    String? id,
    String? nome,
    Color? cor,
    double? valor,
    List<SubItemOrcamentoEntity>? subItens,
  }) {
    return OrcamentoEntity(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cor: cor ?? this.cor,
      valor: valor ?? this.valor,
      subItens: subItens ?? this.subItens,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrcamentoEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nome == other.nome &&
          cor == other.cor &&
          valor == other.valor &&
          listEquals(subItens, other.subItens);

  @override
  int get hashCode => Object.hash(id, nome, cor, valor, subItens);

  @override
  String toString() =>
      'OrcamentoEntity(id: $id, nome: $nome, cor: $cor, valor: $valor, '
      'subItens: $subItens)';
}

@immutable
class SubItemOrcamentoEntity {
  const SubItemOrcamentoEntity({
    required this.id,
    required this.nome,
    required this.valor,
  });

  final String id;
  final String nome;
  final double valor;

  SubItemOrcamentoEntity copyWith({
    String? id,
    String? nome,
    double? valor,
  }) {
    return SubItemOrcamentoEntity(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      valor: valor ?? this.valor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubItemOrcamentoEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nome == other.nome &&
          valor == other.valor;

  @override
  int get hashCode => Object.hash(id, nome, valor);

  @override
  String toString() =>
      'SubItemOrcamentoEntity(id: $id, nome: $nome, valor: $valor)';
}
