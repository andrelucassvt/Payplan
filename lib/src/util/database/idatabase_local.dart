import 'package:notes_app/src/util/entity/cartao_entity.dart';

abstract class IDatabaseLocal {
  Future<void> salvarCartao({
    required CartaoEntity cartaoEntity,
  });

  Future<void> removerCartao({
    required CartaoEntity cartaoEntity,
  });

  Future<List<CartaoEntity>> buscarCartoes();

  Future<void> atualizarCartao({
    required CartaoEntity cartaoEntity,
  });
}
