import 'package:get_it/get_it.dart';
import 'package:notes_app/src/features/home/presenter/cubit/home_cubit.dart';
import 'package:notes_app/src/features/novo_cartao/presenter/cubit/novo_cartao_cubit.dart';
import 'package:notes_app/src/util/database/database_local.dart';
import 'package:notes_app/src/util/database/database_local_manager.dart';
import 'package:notes_app/src/util/repository/database_local_repository.dart';
import 'package:notes_app/src/util/repository/idatabase_local_repository.dart';
import 'package:notes_app/src/util/usecases/atualizar_cartao_usecase.dart';
import 'package:notes_app/src/util/usecases/buscar_cartoes_usecase.dart';
import 'package:notes_app/src/util/usecases/remover_cartao_usecase.dart';
import 'package:notes_app/src/util/usecases/salvar_cartao_usecase.dart';

class AppInject {
  static void init() {
    final getIt = GetIt.instance;

    getIt.registerFactory(() => DatabaseLocalManager());
    getIt.registerFactory(
      () => DatabaseLocal(
        database: getIt(),
      ),
    );
    getIt.registerFactory<IDatabaseLocalRepository>(
      () => DatabaseLocalRepository(
        databaseLocal: getIt<DatabaseLocal>(),
      ),
    );

    getIt.registerFactory(() => AtualizarCartaoUsecase(
          databaseLocalRepository: getIt(),
        ));
    getIt.registerFactory(() => BuscarCartoesUsecase(
          databaseLocalRepository: getIt(),
        ));
    getIt.registerFactory(() => RemoverCartaoUsecase(
          databaseLocalRepository: getIt(),
        ));
    getIt.registerFactory<SalvarCartaoUsecase>(() => SalvarCartaoUsecase(
          databaseLocalRepository: getIt(),
        ));

    getIt.registerFactory(() => HomeCubit(
          buscarCartoesUsecase: getIt(),
          atualizarCartaoUsecase: getIt(),
          removerCartaoUsecase: getIt(),
        ));
    getIt.registerFactory(() => NovoCartaoCubit(
          salvarCartaoUsecase: getIt(),
          atualizarCartaoUsecase: getIt(),
        ));
  }
}
