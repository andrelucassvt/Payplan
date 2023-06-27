import 'package:dartz/dartz.dart';
import 'package:notes_app/src/util/entity/cartao_entity.dart';
import 'package:notes_app/src/util/repository/idatabase_local_repository.dart';

class BuscarCartoesUsecase {
  final IDatabaseLocalRepository databaseLocalRepository;
  BuscarCartoesUsecase({
    required this.databaseLocalRepository,
  });
  Future<Either<Exception, List<CartaoEntity>>> call() async {
    return await databaseLocalRepository.buscarCartoes();
  }
}
