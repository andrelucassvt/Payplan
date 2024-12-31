class DevedoresEntity {
  final String id;
  final String nome;
  final double valor;
  final DateTime? notificar;

  DevedoresEntity({
    required this.id,
    required this.nome,
    required this.valor,
    this.notificar,
  });

  DevedoresEntity copyWith({
    String? id,
    String? nome,
    double? valor,
    DateTime? notificar,
  }) {
    return DevedoresEntity(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      valor: valor ?? this.valor,
      notificar: notificar ?? this.notificar,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'nome': nome,
      'valor': valor,
      'notificar': notificar?.millisecondsSinceEpoch,
    };
  }

  factory DevedoresEntity.fromJson(Map<String, dynamic> map) {
    return DevedoresEntity(
      id: map['id'] as String,
      nome: map['nome'] as String,
      valor: map['valor'] as double,
      notificar: map['notificar'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['notificar'] as int)
          : null,
    );
  }
}
