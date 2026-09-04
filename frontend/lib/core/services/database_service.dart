import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import '../../models/category_model.dart';
import '../../models/screenshot_model.dart';
import '../../models/sync_queue_item_model.dart';
import '../../models/tag_model.dart';
import 'media_classifier.dart';

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

    // Seed default canonical categories
    for (final cat in CategoryModel.defaultCategories) {
      await db.insert('categories', cat.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
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

  Future<void> purgeMockScreenshots() async {
    final db = await database;
    await db.delete(
      'screenshots',
      where: "file_path LIKE 'assets/mock_screenshots%' OR is_mock = 1",
    );
  }

  Future<ScreenshotModel?> getScreenshotByDeviceAssetId(String deviceAssetId) async {
    if (deviceAssetId.isEmpty) return null;
    final db = await database;
    final maps = await db.query(
      'screenshots',
      where: 'device_asset_id = ?',
      whereArgs: [deviceAssetId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    final tags = await getTagsForScreenshot(maps.first['id'] as String);
    return ScreenshotModel.fromMap(maps.first, tags);
  }

  Future<ScreenshotModel?> getScreenshotByFilePath(String filePath) async {
    if (filePath.isEmpty) return null;
    final db = await database;
    final maps = await db.query(
      'screenshots',
      where: 'file_path = ?',
      whereArgs: [filePath],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    final tags = await getTagsForScreenshot(maps.first['id'] as String);
    return ScreenshotModel.fromMap(maps.first, tags);
  }

  /// Checks if a screenshot already exists by either device asset ID or file path
  Future<bool> hasScreenshot({String? deviceAssetId, String? filePath}) async {
    final db = await database;
    if (deviceAssetId != null && deviceAssetId.isNotEmpty) {
      final res = await db.rawQuery(
        'SELECT 1 FROM screenshots WHERE device_asset_id = ? LIMIT 1',
        [deviceAssetId],
      );
      if (res.isNotEmpty) return true;
    }

    if (filePath != null && filePath.isNotEmpty) {
      final res = await db.rawQuery(
        'SELECT 1 FROM screenshots WHERE file_path = ? LIMIT 1',
        [filePath],
      );
      if (res.isNotEmpty) return true;
    }

    return false;
  }

  Future<void> upsertScreenshot(ScreenshotModel screenshot) async {
    final existing = await getScreenshotByDeviceAssetId(screenshot.deviceAssetId);
    
    if (existing == null) {
      await insertScreenshot(screenshot);
    } else {
      // Merge with existing record
      final merged = screenshot.copyWith(
        id: existing.id,
        categoryId: screenshot.categoryId != 'unsorted' ? screenshot.categoryId : existing.categoryId,
        categoryName: screenshot.categoryId != 'unsorted' ? screenshot.categoryName : existing.categoryName,
        subcategory: screenshot.subcategory.isNotEmpty ? screenshot.subcategory : existing.subcategory,
        confidence: screenshot.confidence > 0 ? screenshot.confidence : existing.confidence,
        isFavorite: existing.isFavorite,
        isReviewed: existing.isReviewed,
        ocrText: screenshot.ocrText ?? existing.ocrText,
        tags: screenshot.tags.isNotEmpty ? screenshot.tags : existing.tags,
      );
      await updateScreenshot(merged);
    }
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

  Future<void> linkScreenshotTag(String screenshotId, String tagId) async {
    final db = await database;
    await db.insert(
      'screenshot_tags',
      {'screenshot_id': screenshotId, 'tag_id': tagId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
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

    // 1. Single grouped query for exact ID counts
    final idCountResults = await db.rawQuery('''
      SELECT category_id, COUNT(*) as count 
      FROM screenshots 
      WHERE is_mock = 0 
      GROUP BY category_id
    ''');
    final idCounts = <String, int>{};
    for (final row in idCountResults) {
      final catId = row['category_id'] as String?;
      final count = row['count'] as int? ?? 0;
      if (catId != null && catId.isNotEmpty) {
        idCounts[catId.toLowerCase()] = count;
      }
    }

    // 2. Fallback grouped query for category name counts
    final nameCountResults = await db.rawQuery('''
      SELECT LOWER(category_name) as lower_name, COUNT(*) as count 
      FROM screenshots 
      WHERE is_mock = 0 AND category_name IS NOT NULL
      GROUP BY LOWER(category_name)
    ''');
    final nameCounts = <String, int>{};
    for (final row in nameCountResults) {
      final name = row['lower_name'] as String?;
      final count = row['count'] as int? ?? 0;
      if (name != null && name.isNotEmpty) {
        nameCounts[name] = count;
      }
    }

    // 3. Ensure all default categories are seeded in SQLite
    List<Map<String, dynamic>> maps = await db.query('categories', orderBy: 'order_index ASC, name ASC');
    if (maps.length <= 1) {
      for (final cat in CategoryModel.defaultCategories) {
        await db.insert('categories', cat.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await autoClassifyAndOrganizeScreenshots();
      // Re-run count queries
      final updatedIdCounts = await db.rawQuery('SELECT category_id, COUNT(*) as count FROM screenshots WHERE is_mock = 0 GROUP BY category_id');
      for (final row in updatedIdCounts) {
        final catId = row['category_id'] as String?;
        final count = row['count'] as int? ?? 0;
        if (catId != null && catId.isNotEmpty) {
          idCounts[catId.toLowerCase()] = count;
        }
      }
      maps = await db.query('categories', orderBy: 'order_index ASC, name ASC');
    }

    final categories = <CategoryModel>[];
    bool hasUnsorted = false;

    for (final map in maps) {
      final id = (map['id'] as String).toLowerCase();
      final name = (map['name'] as String? ?? '').toLowerCase();
      if (id == CategoryModel.unsortedId || name == CategoryModel.unsortedName.toLowerCase()) {
        hasUnsorted = true;
      }

      int count = idCounts[id] ?? 0;
      if (count == 0 && nameCounts.containsKey(name)) {
        count = nameCounts[name] ?? 0;
      }

      categories.add(CategoryModel.fromMap(map, count));
    }

    // 4. Ensure Unsorted category is always included
    if (!hasUnsorted) {
      int unsortedCount = idCounts[CategoryModel.unsortedId] ?? 0;
      if (unsortedCount == 0 && nameCounts.containsKey(CategoryModel.unsortedName.toLowerCase())) {
        unsortedCount = nameCounts[CategoryModel.unsortedName.toLowerCase()] ?? 0;
      }
      categories.add(CategoryModel.unsortedCategory.copyWith(screenshotCount: unsortedCount));
    }

    return categories;
  }

  Future<void> upsertCategory(CategoryModel category) async {
    final db = await database;

    // Check if an old category exists with the same name but different id (e.g. old string ID)
    final existingWithSameName = await db.query(
      'categories',
      where: 'LOWER(name) = LOWER(?) AND id != ?',
      whereArgs: [category.name, category.id],
    );

    if (existingWithSameName.isNotEmpty) {
      for (final oldRow in existingWithSameName) {
        final oldId = oldRow['id'] as String;
        // Re-link screenshots that had old ID to new canonical ID
        await db.update(
          'screenshots',
          {'category_id': category.id, 'category_name': category.name},
          where: 'category_id = ?',
          whereArgs: [oldId],
        );
        // Delete old row
        await db.delete(
          'categories',
          where: 'id = ?',
          whereArgs: [oldId],
        );
      }
    }

    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertCategories(List<CategoryModel> categories) async {
    for (final cat in categories) {
      await upsertCategory(cat);
    }
  }

  Future<void> migrateCategoryIdsAndRepairData(List<CategoryModel> canonicalCategories) async {
    final db = await database;

    // 1. Purge legacy mock screenshot records
    await db.delete(
      'screenshots',
      where: "file_path LIKE 'assets/mock_screenshots%' OR is_mock = 1",
    );

    // 2. Map old mock category IDs to backend category names
    final oldMockMap = {
      'receipts': 'Receipts & Invoices',
      'social': 'Social & Chat',
      'social & chats': 'Social & Chat',
      'finance': 'Finance & Banking',
      'documents': 'Documents & IDs',
      'work': 'Documents & IDs',
      'code': 'Code & Tech',
      'memes': 'Memes & Humor',
      'notes': 'Notes & Knowledge',
      'shopping': 'Shopping & Wishlist',
      'travel': 'Travel & Tickets',
    };

    // 3. For each canonical category, update screenshots that have matching name or old mock ID
    for (final cat in canonicalCategories) {
      final matchingOldIds = <String>[cat.id];
      for (final entry in oldMockMap.entries) {
        if (entry.value.toLowerCase() == cat.name.toLowerCase()) {
          matchingOldIds.add(entry.key);
        }
      }

      for (final oldId in matchingOldIds) {
        await db.update(
          'screenshots',
          {'category_id': cat.id, 'category_name': cat.name},
          where: '(category_id = ? OR LOWER(category_name) = LOWER(?)) AND category_id != ? AND is_mock = 0',
          whereArgs: [oldId, cat.name, cat.id],
        );
      }
    }

    // 4. Auto-classify all unsorted screenshots into appropriate Categories & Subcategories
    await autoClassifyAndOrganizeScreenshots();
  }

  /// Automatically categorizes and organizes all unsorted screenshots into proper Category & Subcategory folders
  Future<int> autoClassifyAndOrganizeScreenshots() async {
    final db = await database;
    const classifier = MediaClassifier();

    // 1. Ensure all default categories exist in SQLite
    var catRows = await db.query('categories');
    if (catRows.length <= 1) {
      for (final cat in CategoryModel.defaultCategories) {
        await db.insert('categories', cat.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      catRows = await db.query('categories');
    }

    final catMap = <String, CategoryModel>{};
    for (final r in catRows) {
      final c = CategoryModel.fromMap(r);
      catMap[c.name.toLowerCase()] = c;
    }

    // 2. Fetch all screenshots needing proper folder organization
    final items = await db.query(
      'screenshots',
      where: 'is_mock = 0 AND (category_id = ? OR category_id = \'\' OR category_id IS NULL OR category_name = ? OR category_name = \'\' OR subcategory IS NULL OR subcategory = \'\')',
      whereArgs: [CategoryModel.unsortedId, CategoryModel.unsortedName],
    );

    int organized = 0;

    for (final row in items) {
      final id = row['id'] as String;
      final fileName = row['file_name'] as String? ?? '';
      final filePath = row['file_path'] as String? ?? '';
      final sourceApp = row['source_app'] as String? ?? '';
      final ocrText = row['ocr_text'] as String? ?? '';

      final result = classifier.classifyMediaItem(
        fileName: fileName,
        filePath: filePath,
        sourceApp: sourceApp,
        ocrText: ocrText,
      );

      final targetCat = catMap[result.categoryName.toLowerCase()];
      final targetCatId = targetCat?.id ?? CategoryModel.unsortedId;
      final targetCatName = targetCat?.name ?? result.categoryName;

      await db.update(
        'screenshots',
        {
          'category_id': targetCatId,
          'category_name': targetCatName,
          'subcategory': result.subcategory,
          'confidence': result.confidence,
          'is_reviewed': result.confidence >= 0.85 ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      // Add tags
      for (final tagStr in result.tags) {
        final tagId = tagStr.toLowerCase().replaceAll(' ', '_');
        await db.insert(
          'tags',
          {'id': tagId, 'name': tagStr, 'color_hex': '6366F1'},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        await db.insert(
          'screenshot_tags',
          {'screenshot_id': id, 'tag_id': tagId},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      organized++;
    }

    return organized;
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
    final totalResult = await db.rawQuery('SELECT COUNT(*) FROM screenshots WHERE is_mock = 0');
    final favoritesResult =
        await db.rawQuery('SELECT COUNT(*) FROM screenshots WHERE is_favorite = 1 AND is_mock = 0');
    final needsReviewResult = await db.rawQuery(
        'SELECT COUNT(*) FROM screenshots WHERE is_reviewed = 0 AND (confidence < 0.70 OR category_id = "unsorted") AND is_mock = 0');
    final syncedResult =
        await db.rawQuery('SELECT COUNT(*) FROM screenshots WHERE is_synced = 1 AND is_mock = 0');

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

  Future<void> clearAiCache() async {
    final db = await database;
    await db.delete('ocr_cache');
    await db.update('screenshots', {'ocr_status': 'none', 'ocr_text': null});
  }
}
