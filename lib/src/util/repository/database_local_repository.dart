import 'package:dartz/dartz.dart';
import 'package:notes_app/src/util/database/idatabase_local.dart';
import 'package:notes_app/src/util/entity/cartao_entity.dart';
import 'package:notes_app/src/util/repository/idatabase_local_repository.dart';

class DatabaseLocalRepository implements IDatabaseLocalRepository {
  final IDatabaseLocal databaseLocal;
  DatabaseLocalRepository({
    required this.databaseLocal,
  });
  @override
  Future<Either<Exception, void>> atualizarCartao({
    required CartaoEntity cartaoEntity,
  }) async {
    try {
      final result =
          await databaseLocal.atualizarCartao(cartaoEntity: cartaoEntity);
      return Right(result);
    } on Exception catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<Exception, List<CartaoEntity>>> buscarCartoes() async {
    try {
      final result = await databaseLocal.buscarCartoes();
      return Right(result);
    } on Exception catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<Exception, void>> removerCartao(
      {required CartaoEntity cartaoEntity}) async {
    try {
      final result =
          await databaseLocal.removerCartao(cartaoEntity: cartaoEntity);
      return Right(result);
    } on Exception catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<Exception, void>> salvarCartao(
      {required CartaoEntity cartaoEntity}) async {
    try {
      final result =
          await databaseLocal.salvarCartao(cartaoEntity: cartaoEntity);
      return Right(result);
    } on Exception catch (e) {
      return Left(e);
    }
  }
}
