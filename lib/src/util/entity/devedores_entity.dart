import 'package:flutter/foundation.dart';

@immutable
class ParcelaDevedorEntity {
  const ParcelaDevedorEntity({
    required this.numero,
    required this.valor,
    this.pago = false,
  });

  final int numero;
  final double valor;
  final bool pago;

  ParcelaDevedorEntity copyWith({
    int? numero,
    double? valor,
    bool? pago,
  }) {
    return ParcelaDevedorEntity(
      numero: numero ?? this.numero,
      valor: valor ?? this.valor,
      pago: pago ?? this.pago,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'valor': valor,
      'pago': pago,
    };
  }

  factory ParcelaDevedorEntity.fromJson(Map<String, dynamic> map) {
    return ParcelaDevedorEntity(
      numero: map['numero'] as int,
      valor: (map['valor'] as num).toDouble(),
      pago: map['pago'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParcelaDevedorEntity &&
          numero == other.numero &&
          valor == other.valor &&
          pago == other.pago;

  @override
  int get hashCode => Object.hash(numero, valor, pago);
}

class DevedoresEntity {
  final String id;
  final String nome;
  final double valor;
  final String? pix;
  final String? message;
  final DateTime? notificar;
  final List<ParcelaDevedorEntity> parcelas;

  DevedoresEntity({
    required this.id,
    required this.nome,
    required this.valor,
    this.pix,
    this.message,
    this.notificar,
    this.parcelas = const [],
  });

  /// Retorna o valor pendente (não pago).
  /// Se não houver parcelas, retorna o valor total.
  /// Se houver parcelas, retorna a soma das parcelas não pagas.
  double get valorPendente {
    if (parcelas.isEmpty) return valor;
    return parcelas
        .where((p) => !p.pago)
        .fold(0.0, (soma, p) => soma + p.valor);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'valor': valor,
      'pix': pix,
      'message': message,
      'notificar': notificar?.millisecondsSinceEpoch,
      'parcelas': parcelas.map((p) => p.toMap()).toList(),
    };
  }

  factory DevedoresEntity.fromJson(Map<String, dynamic> map) {
    return DevedoresEntity(
      id: map['id'] as String,
      nome: map['nome'] as String,
      valor: (map['valor'] as num).toDouble(),
      pix: map['pix'] as String?,
      message: map['message'] as String?,
      notificar: map['notificar'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['notificar'] as int)
          : null,
      parcelas: (map['parcelas'] as List<dynamic>?)
              ?.map((e) =>
                  ParcelaDevedorEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  DevedoresEntity copyWith({
    String? id,
    String? nome,
    double? valor,
    String? pix,
    String? message,
    DateTime? notificar,
    List<ParcelaDevedorEntity>? parcelas,
  }) {
    return DevedoresEntity(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      valor: valor ?? this.valor,
      pix: pix ?? this.pix,
      message: message ?? this.message,
      notificar: notificar ?? this.notificar,
      parcelas: parcelas ?? this.parcelas,
    );
  }
}
