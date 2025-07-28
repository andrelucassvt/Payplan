class DevedoresEntity {
  final String id;
  final String nome;
  final double valor;
  final String? pix;
  final String? message;
  final DateTime? notificar;

  DevedoresEntity({
    required this.id,
    required this.nome,
    required this.valor,
    this.pix,
    this.message,
    this.notificar,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'valor': valor,
      'pix': pix,
      'message': message,
      'notificar': notificar?.millisecondsSinceEpoch,
    };
  }

  factory DevedoresEntity.fromJson(Map<String, dynamic> map) {
    return DevedoresEntity(
      id: map['id'] as String,
      nome: map['nome'] as String,
      valor: map['valor'] as double,
      pix: map['pix'] as String?,
      message: map['message'] as String?,
      notificar: map['notificar'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['notificar'] as int)
          : null,
    );
  }

  DevedoresEntity copyWith({
    String? id,
    String? nome,
    double? valor,
    String? pix,
    String? message,
    DateTime? notificar,
  }) {
    return DevedoresEntity(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      valor: valor ?? this.valor,
      pix: pix ?? this.pix,
      message: message ?? this.message,
      notificar: notificar ?? this.notificar,
    );
  }
}
