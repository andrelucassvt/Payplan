import 'package:notes_app/src/util/database/database_local_manager.dart';
import 'package:notes_app/src/util/database/idatabase_local.dart';
import 'package:notes_app/src/util/entity/cartao_entity.dart';

class DatabaseLocal implements IDatabaseLocal {
  final DatabaseLocalManager database;
  DatabaseLocal({
    required this.database,
  });
  @override
  Future<void> atualizarCartao({required CartaoEntity cartaoEntity}) async {
    try {
      await database.atualizarCartao(cartaoEntity: cartaoEntity);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<CartaoEntity>> buscarCartoes() async {
    try {
      return await database.buscarCartoes();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> removerCartao({required CartaoEntity cartaoEntity}) async {
    try {
      return await database.removerCartao(cartaoEntity: cartaoEntity);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> salvarCartao({required CartaoEntity cartaoEntity}) async {
    try {
      return await database.salvarCartao(cartaoEntity: cartaoEntity);
    } catch (e) {
      rethrow;
    }
  }
}
