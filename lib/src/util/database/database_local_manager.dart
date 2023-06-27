import 'package:notes_app/src/util/database/idatabase_local.dart';
import 'package:notes_app/src/util/entity/cartao_entity.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

class DatabaseLocalManager extends IDatabaseLocal {
  static const String databaseName = 'payplan.db';
  static const String storeName = 'dividas';

  final DatabaseFactory _dbFactory = databaseFactoryIo;
  late Database _database;
  late StoreRef<String, Map<String, dynamic>> _store;

  Future<void> openDatabase() async {
    var directory = await getApplicationDocumentsDirectory();
    var databasePath = join(directory.path, databaseName);
    _database = await _dbFactory.openDatabase(databasePath);
    _store = stringMapStoreFactory.store(storeName);
  }

  @override
  Future<void> salvarCartao({required CartaoEntity cartaoEntity}) async {
    await openDatabase();
    await _store.record(cartaoEntity.id).add(_database, cartaoEntity.toMap());
  }

  @override
  Future<List<CartaoEntity>> buscarCartoes() async {
    await openDatabase();
    final snapshots = await _store.find(_database);
    return snapshots.map((snapshot) {
      final cartao = CartaoEntity.fromMap(snapshot.value);
      return cartao;
    }).toList();
  }

  @override
  Future<void> atualizarCartao({required CartaoEntity cartaoEntity}) async {
    await openDatabase();
    await _store
        .record(cartaoEntity.id)
        .update(_database, cartaoEntity.toMap());
  }

  @override
  Future<void> removerCartao({required CartaoEntity cartaoEntity}) async {
    await openDatabase();
    await _store.record(cartaoEntity.id).delete(_database);
  }

  Future<void> closeDatabase() async {
    await _database.close();
  }
}
