import 'package:dartz/dartz.dart';
import 'package:notes_app/src/util/entity/cartao_entity.dart';
import 'package:notes_app/src/util/repository/idatabase_local_repository.dart';

class AtualizarCartaoUsecase {
  final IDatabaseLocalRepository databaseLocalRepository;
  AtualizarCartaoUsecase({
    required this.databaseLocalRepository,
  });
  Future<Either<Exception, void>> call({
    required CartaoEntity cartaoEntity,
  }) async {
    return await databaseLocalRepository.atualizarCartao(
        cartaoEntity: cartaoEntity);
  }
}
