import 'package:dartz/dartz.dart';
import 'package:notes_app/src/util/entity/cartao_entity.dart';

abstract class IDatabaseLocalRepository {
  Future<Either<Exception, void>> salvarCartao({
    required CartaoEntity cartaoEntity,
  });

  Future<Either<Exception, void>> removerCartao({
    required CartaoEntity cartaoEntity,
  });

  Future<Either<Exception, List<CartaoEntity>>> buscarCartoes();

  Future<Either<Exception, void>> atualizarCartao({
    required CartaoEntity cartaoEntity,
  });
}
