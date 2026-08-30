import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import '../../models/category_model.dart';
import '../../models/screenshot_model.dart';
import '../../models/sync_queue_item_model.dart';
import '../../models/tag_model.dart';
import '../../mock/mock_data.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        description TEXT,
        is_system INTEGER NOT NULL DEFAULT 1,
        order_index INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 2. Folders table
    await db.execute('''
      CREATE TABLE folders (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 3. Tags table
    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        color_hex TEXT NOT NULL
      )
    ''');

    // 4. Screenshots table
    await db.execute('''
      CREATE TABLE screenshots (
        id TEXT PRIMARY KEY,
        device_asset_id TEXT,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        width INTEGER NOT NULL DEFAULT 1080,
        height INTEGER NOT NULL DEFAULT 2400,
        file_size INTEGER NOT NULL DEFAULT 0,
        category_id TEXT NOT NULL,
        category_name TEXT NOT NULL,
        subcategory TEXT,
        confidence REAL NOT NULL DEFAULT 0.0,
        source_app TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        is_reviewed INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        ocr_status TEXT NOT NULL DEFAULT 'none',
        ocr_text TEXT,
        last_scanned_at TEXT,
        is_mock INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET DEFAULT
      )
    ''');

    // 5. Screenshot-Tags many-to-many relationship
    await db.execute('''
      CREATE TABLE screenshot_tags (
        screenshot_id TEXT NOT NULL,
        tag_id TEXT NOT NULL,
        PRIMARY KEY (screenshot_id, tag_id),
        FOREIGN KEY (screenshot_id) REFERENCES screenshots (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
      )
    ''');

    // 6. OCR Cache table
    await db.execute('''
      CREATE TABLE ocr_cache (
        screenshot_id TEXT PRIMARY KEY,
        raw_text TEXT NOT NULL,
        language TEXT NOT NULL DEFAULT 'en',
        confidence REAL NOT NULL DEFAULT 1.0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (screenshot_id) REFERENCES screenshots (id) ON DELETE CASCADE
      )
    ''');

    // 7. Sync Queue table for offline transactions
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        endpoint TEXT NOT NULL,
        http_method TEXT NOT NULL DEFAULT 'POST',
        payload TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        last_error TEXT
      )
    ''');

    // Seed default categories
    final batch = db.batch();
    for (final category in MockData.initialCategories) {
      batch.insert('categories', category.toMap());
    }
    for (final tag in MockData.initialTags) {
      batch.insert('tags', tag.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration logic when database schema evolves
  }

  // ==================== SCREENSHOTS ====================

  Future<List<ScreenshotModel>> getAllScreenshots({
    String? categoryId,
    bool? isFavorite,
    bool? needsReview,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    final conditions = <String>[];
    if (categoryId != null && categoryId != 'all') {
      conditions.add('category_id = ?');
      whereArgs.add(categoryId);
    }
    if (isFavorite != null && isFavorite) {
      conditions.add('is_favorite = 1');
    }
    if (needsReview != null && needsReview) {
      conditions.add('(is_reviewed = 0 AND (confidence < 0.70 OR category_id = "unsorted"))');
    }

    if (conditions.isNotEmpty) {
      whereClause = 'WHERE ${conditions.join(' AND ')}';
    }

    final query = '''
      SELECT * FROM screenshots 
      $whereClause
      ORDER BY created_at DESC 
      LIMIT $limit OFFSET $offset
    ''';

    final maps = await db.rawQuery(query, whereArgs);
    final screenshots = <ScreenshotModel>[];

    for (final map in maps) {
      final tags = await getTagsForScreenshot(map['id'] as String);
      screenshots.add(ScreenshotModel.fromMap(map, tags));
    }

    return screenshots;
  }

  Future<ScreenshotModel?> getScreenshotById(String id) async {
    final db = await database;
    final maps = await db.query(
      'screenshots',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    final tags = await getTagsForScreenshot(id);
    return ScreenshotModel.fromMap(maps.first, tags);
  }

  Future<void> insertScreenshot(ScreenshotModel screenshot) async {
    final db = await database;
    await db.insert(
      'screenshots',
      screenshot.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Link tags
    for (final tag in screenshot.tags) {
      await db.insert(
        'screenshot_tags',
        {'screenshot_id': screenshot.id, 'tag_id': tag.id},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> updateScreenshot(ScreenshotModel screenshot) async {
    final db = await database;
    await db.update(
      'screenshots',
      screenshot.toMap(),
      where: 'id = ?',
      whereArgs: [screenshot.id],
    );

    // Sync tags
    await db.delete(
      'screenshot_tags',
      where: 'screenshot_id = ?',
      whereArgs: [screenshot.id],
    );
    for (final tag in screenshot.tags) {
      await db.insert(
        'screenshot_tags',
        {'screenshot_id': screenshot.id, 'tag_id': tag.id},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'screenshots',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteScreenshot(String id) async {
    final db = await database;
    await db.delete('screenshots', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== SEARCH ====================

  Future<List<ScreenshotModel>> searchScreenshots({
    required String query,
    String? categoryId,
    String? sourceApp,
    bool searchOcr = true,
    bool searchTags = true,
  }) async {
    final db = await database;
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final wildQuery = '%$cleanQuery%';

    final sql = '''
      SELECT DISTINCT s.* FROM screenshots s
      LEFT JOIN screenshot_tags st ON s.id = st.screenshot_id
      LEFT JOIN tags t ON st.tag_id = t.id
      WHERE (
        LOWER(s.file_name) LIKE ?
        OR LOWER(s.category_name) LIKE ?
        OR LOWER(s.subcategory) LIKE ?
        OR LOWER(s.source_app) LIKE ?
        OR (1 = ? AND LOWER(s.ocr_text) LIKE ?)
        OR (1 = ? AND LOWER(t.name) LIKE ?)
      )
      ${categoryId != null && categoryId != 'all' ? 'AND s.category_id = ?' : ''}
      ${sourceApp != null && sourceApp.isNotEmpty ? 'AND LOWER(s.source_app) = ?' : ''}
      ORDER BY s.created_at DESC
    ''';

    final args = <dynamic>[
      wildQuery,
      wildQuery,
      wildQuery,
      wildQuery,
      searchOcr ? 1 : 0,
      wildQuery,
      searchTags ? 1 : 0,
      wildQuery,
    ];

    if (categoryId != null && categoryId != 'all') {
      args.add(categoryId);
    }
    if (sourceApp != null && sourceApp.isNotEmpty) {
      args.add(sourceApp.toLowerCase());
    }

    final maps = await db.rawQuery(sql, args);
    final results = <ScreenshotModel>[];

    for (final map in maps) {
      final tags = await getTagsForScreenshot(map['id'] as String);
      results.add(ScreenshotModel.fromMap(map, tags));
    }

    return results;
  }

  // ==================== CATEGORIES ====================

  Future<List<CategoryModel>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'order_index ASC');
    final categories = <CategoryModel>[];

    for (final map in maps) {
      final id = map['id'] as String;
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM screenshots WHERE category_id = ?',
        [id],
      );
      final count = Sqflite.firstIntValue(countResult) ?? 0;
      categories.add(CategoryModel.fromMap(map, count));
    }

    return categories;
  }

  // ==================== TAGS ====================

  Future<List<TagModel>> getAllTags() async {
    final db = await database;
    final maps = await db.query('tags', orderBy: 'name ASC');
    return maps.map((m) => TagModel.fromMap(m)).toList();
  }

  Future<List<TagModel>> getTagsForScreenshot(String screenshotId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT t.* FROM tags t
      INNER JOIN screenshot_tags st ON t.id = st.tag_id
      WHERE st.screenshot_id = ?
    ''', [screenshotId]);

    return maps.map((m) => TagModel.fromMap(m)).toList();
  }

  Future<void> addTag(TagModel tag) async {
    final db = await database;
    await db.insert(
      'tags',
      tag.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // ==================== STATS & COUNTS ====================

  Future<Map<String, int>> getStats() async {
    final db = await database;
    final totalResult = await db.rawQuery('SELECT COUNT(*) FROM screenshots');
    final favoritesResult =
        await db.rawQuery('SELECT COUNT(*) FROM screenshots WHERE is_favorite = 1');
    final needsReviewResult = await db.rawQuery(
        'SELECT COUNT(*) FROM screenshots WHERE is_reviewed = 0 AND (confidence < 0.70 OR category_id = "unsorted")');
    final syncedResult =
        await db.rawQuery('SELECT COUNT(*) FROM screenshots WHERE is_synced = 1');

    return {
      'total': Sqflite.firstIntValue(totalResult) ?? 0,
      'favorites': Sqflite.firstIntValue(favoritesResult) ?? 0,
      'needs_review': Sqflite.firstIntValue(needsReviewResult) ?? 0,
      'synced': Sqflite.firstIntValue(syncedResult) ?? 0,
    };
  }

  // ==================== SYNC QUEUE ====================

  Future<void> addToSyncQueue(SyncQueueItemModel item) async {
    final db = await database;
    await db.insert(
      'sync_queue',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SyncQueueItemModel>> getPendingSyncItems() async {
    final db = await database;
    final maps = await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => SyncQueueItemModel.fromMap(m)).toList();
  }

  Future<void> updateSyncItemStatus(String id, String status, [String? error]) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {'status': status, 'last_error': error},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> purgeMockScreenshots() async {
    final db = await database;
    await db.delete('screenshots', where: 'is_mock = 1 OR file_path LIKE ?', whereArgs: ['%assets/mock_screenshots%']);
  }

  Future<void> clearAiCache() async {
    final db = await database;
    await db.delete('ocr_cache');
    await db.update('screenshots', {'ocr_status': 'none', 'ocr_text': null});
  }
}
