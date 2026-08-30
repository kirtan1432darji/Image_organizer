import '../core/services/database_service.dart';
import '../models/folder_model.dart';
import 'package:uuid/uuid.dart';

abstract class FolderRepository {
  Future<List<FolderModel>> getFolders();
  Future<void> createFolder(String name, String icon);
  Future<void> deleteFolder(String id);
}

class FolderRepositoryImpl implements FolderRepository {
  final DatabaseService _db;
  final _uuid = const Uuid();

  FolderRepositoryImpl({DatabaseService? db}) : _db = db ?? DatabaseService();

  @override
  Future<List<FolderModel>> getFolders() async {
    final db = await _db.database;
    final maps = await db.query('folders', orderBy: 'created_at DESC');
    final folders = <FolderModel>[];
    for (final map in maps) {
      folders.add(FolderModel.fromMap(map));
    }
    return folders;
  }

  @override
  Future<void> createFolder(String name, String icon) async {
    final db = await _db.database;
    final folder = FolderModel(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      createdAt: DateTime.now(),
    );
    await db.insert('folders', folder.toMap());
  }

  @override
  Future<void> deleteFolder(String id) async {
    final db = await _db.database;
    await db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }
}
