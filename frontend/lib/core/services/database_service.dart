import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
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

    final db = await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    // Schema migration check: ensure parent_id, classification columns, and history exist
    try {
      final info = await db.rawQuery('PRAGMA table_info(categories)');
      final hasParentId = info.any((col) => col['name'] == 'parent_id');
      if (!hasParentId) {
        await db.execute('ALTER TABLE categories ADD COLUMN parent_id TEXT');
      }
      await db.execute('CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON categories(parent_id)');

      final ssInfo = await db.rawQuery('PRAGMA table_info(screenshots)');
      final hasDetectedApp = ssInfo.any((col) => col['name'] == 'detected_app');
      if (!hasDetectedApp) {
        await db.execute('ALTER TABLE screenshots ADD COLUMN detected_app TEXT');
      }
      final hasKeywordsJson = ssInfo.any((col) => col['name'] == 'keywords_json');
      if (!hasKeywordsJson) {
        await db.execute('ALTER TABLE screenshots ADD COLUMN keywords_json TEXT');
      }
      final hasIsAutoCat = ssInfo.any((col) => col['name'] == 'is_auto_categorized');
      if (!hasIsAutoCat) {
        await db.execute('ALTER TABLE screenshots ADD COLUMN is_auto_categorized INTEGER DEFAULT 0');
      }

      await db.execute('''
        CREATE TABLE IF NOT EXISTS classification_history (
          id TEXT PRIMARY KEY,
          screenshot_id TEXT NOT NULL,
          category TEXT NOT NULL,
          sub_category TEXT,
          tags_json TEXT,
          confidence REAL NOT NULL DEFAULT 0.0,
          model_name TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (screenshot_id) REFERENCES screenshots (id) ON DELETE CASCADE
        )
      ''');
    } catch (_) {}

    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Categories table with hierarchical parent_id support
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        parent_id TEXT,
        icon_name TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        description TEXT,
        is_system INTEGER NOT NULL DEFAULT 1,
        order_index INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON categories(parent_id)');

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
        detected_app TEXT,
        keywords_json TEXT,
        is_auto_categorized INTEGER NOT NULL DEFAULT 0,
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

  Future<List<String>> _getCategoryAndDescendantIds(Database db, String categoryId) async {
    final result = <String>{categoryId};
    final queue = <String>[categoryId];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final children = await db.query(
        'categories',
        columns: ['id'],
        where: 'parent_id = ?',
        whereArgs: [current],
      );
      for (final child in children) {
        final childId = child['id'] as String;
        if (result.add(childId)) {
          queue.add(childId);
        }
      }
    }

    return result.toList();
  }

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
      final descendantIds = await _getCategoryAndDescendantIds(db, categoryId);
      final placeholders = List.filled(descendantIds.length, '?').join(', ');
      conditions.add('category_id IN ($placeholders)');
      whereArgs.addAll(descendantIds);
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

  // ==================== CATEGORIES & DYNAMIC SMART FOLDERS ====================

  /// Fetches categories. If [rootOnly] is true, returns only top-level categories.
  /// If [parentId] is supplied, returns direct subcategories of that parent.
  /// Calculates recursive screenshot counts across all descendant folders.
  Future<List<CategoryModel>> getCategories({String? parentId, bool rootOnly = false}) async {
    final db = await database;

    // 1. Direct screenshot count per category ID
    final idCountResults = await db.rawQuery('''
      SELECT category_id, COUNT(*) as count 
      FROM screenshots 
      WHERE is_mock = 0 AND category_id IS NOT NULL AND category_id != ''
      GROUP BY category_id
    ''');
    final directCounts = <String, int>{};
    for (final row in idCountResults) {
      final catId = (row['category_id'] as String?)?.toLowerCase();
      final count = row['count'] as int? ?? 0;
      if (catId != null && catId.isNotEmpty) {
        directCounts[catId] = count;
      }
    }

    // 2. Fetch all category rows to compute tree hierarchy & recursive counts
    final allCategoryRows = await db.query('categories', orderBy: 'order_index ASC, name ASC');

    // Build parent -> children map and category lookup
    final childrenMap = <String, List<String>>{};
    for (final r in allCategoryRows) {
      final id = r['id'] as String;
      final pid = r['parent_id'] as String?;
      if (pid != null && pid.isNotEmpty) {
        childrenMap.putIfAbsent(pid, () => []).add(id);
      }
    }

    // Helper for recursive count computation
    int computeRecursiveCount(String catId) {
      int total = directCounts[catId.toLowerCase()] ?? 0;
      final children = childrenMap[catId] ?? [];
      for (final childId in children) {
        total += computeRecursiveCount(childId);
      }
      return total;
    }

    // Filter which categories to return
    final filteredRows = <Map<String, dynamic>>[];
    for (final r in allCategoryRows) {
      final pid = r['parent_id'] as String?;
      if (rootOnly) {
        if (pid == null || pid.isEmpty) {
          filteredRows.add(r);
        }
      } else if (parentId != null) {
        if (pid == parentId) {
          filteredRows.add(r);
        }
      } else {
        filteredRows.add(r);
      }
    }

    final categories = <CategoryModel>[];
    bool hasUnsorted = false;

    for (final map in filteredRows) {
      final id = map['id'] as String;
      final name = (map['name'] as String? ?? '').toLowerCase();
      if (id.toLowerCase() == CategoryModel.unsortedId || name == CategoryModel.unsortedName.toLowerCase()) {
        hasUnsorted = true;
      }

      final totalCount = computeRecursiveCount(id);

      // Fetch immediate subcategories as models
      final immediateChildren = (childrenMap[id] ?? [])
          .map((cid) {
            final childRow = allCategoryRows.firstWhere(
              (cr) => cr['id'] == cid,
              orElse: () => <String, dynamic>{},
            );
            if (childRow.isEmpty) return null;
            return CategoryModel.fromMap(childRow, computeRecursiveCount(cid));
          })
          .whereType<CategoryModel>()
          .toList();

      categories.add(CategoryModel.fromMap(map, totalCount, immediateChildren));
    }

    // If rootOnly or viewing all, ensure Unsorted is included
    if ((rootOnly || parentId == null) && !hasUnsorted) {
      final unsortedCount = directCounts[CategoryModel.unsortedId] ?? 0;
      categories.add(CategoryModel.unsortedCategory.copyWith(screenshotCount: unsortedCount));
    }

    return categories;
  }

  /// Returns only root (top-level) Smart Folders
  Future<List<CategoryModel>> getRootCategories() => getCategories(rootOnly: true);

  /// Returns subfolders of a specific category
  Future<List<CategoryModel>> getSubcategories(String parentId) => getCategories(parentId: parentId);

  /// Traverses up from [categoryId] to the root to build clickable breadcrumbs
  Future<List<CategoryModel>> getCategoryAncestors(String categoryId) async {
    final db = await database;
    final ancestors = <CategoryModel>[];
    String? currentId = categoryId;

    while (currentId != null && currentId.isNotEmpty && currentId != 'all' && currentId != CategoryModel.unsortedId) {
      final rows = await db.query('categories', where: 'id = ?', whereArgs: [currentId]);
      if (rows.isEmpty) break;
      final cat = CategoryModel.fromMap(rows.first);
      ancestors.insert(0, cat);
      currentId = cat.parentId;
    }

    return ancestors;
  }

  /// Automatically retrieves or creates the folder hierarchy in SQLite.
  /// Given ['Projects', 'NHDC', 'Payroll'], it finds or creates:
  /// - Projects (root)
  ///   - NHDC (subfolder of Projects)
  ///     - Payroll (subfolder of NHDC)
  /// Returns the leaf CategoryModel.
  Future<CategoryModel> getOrCreateFolderHierarchy(List<String> folderSegments) async {
    final db = await database;
    if (folderSegments.isEmpty) {
      return CategoryModel.unsortedCategory;
    }

    String? currentParentId;
    CategoryModel? currentCategory;

    for (int i = 0; i < folderSegments.length; i++) {
      final segment = folderSegments[i].trim();
      if (segment.isEmpty) continue;

      List<Map<String, dynamic>> matches;
      if (currentParentId == null) {
        matches = await db.query(
          'categories',
          where: 'LOWER(name) = LOWER(?) AND (parent_id IS NULL OR parent_id = \'\')',
          whereArgs: [segment],
          limit: 1,
        );
      } else {
        matches = await db.query(
          'categories',
          where: 'LOWER(name) = LOWER(?) AND parent_id = ?',
          whereArgs: [segment, currentParentId],
          limit: 1,
        );
      }

      if (matches.isNotEmpty) {
        currentCategory = CategoryModel.fromMap(matches.first);
        currentParentId = currentCategory.id;
      } else {
        // Create new dynamic category
        final cleanSlug = segment.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
        const uuid = Uuid();
        final newId = 'folder_${cleanSlug}_${uuid.v4().substring(0, 8)}';
        final iconName = _inferCategoryIcon(segment);
        final colorHex = _inferCategoryColor(segment);

        final newCat = CategoryModel(
          id: newId,
          name: segment,
          parentId: currentParentId,
          iconName: iconName,
          colorHex: colorHex,
          description: i == 0 ? 'Smart Folder: $segment' : 'Subfolder of ${currentCategory?.name ?? "Root"}',
          isSystem: false,
          orderIndex: 50 + i,
        );

        await db.insert(
          'categories',
          newCat.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        currentCategory = newCat;
        currentParentId = newId;
      }
    }

    return currentCategory ?? CategoryModel.unsortedCategory;
  }

  String _inferCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('project') || lower.contains('work')) return 'folder_special';
    if (lower.contains('payroll') || lower.contains('salary')) return 'payments';
    if (lower.contains('shop') || lower.contains('amazon')) return 'shopping_bag';
    if (lower.contains('shoe') || lower.contains('fashion')) return 'roller_skating';
    if (lower.contains('learn') || lower.contains('tutorial') || lower.contains('study')) return 'school';
    if (lower.contains('code') || lower.contains('tech') || lower.contains('flutter')) return 'code';
    if (lower.contains('flight') || lower.contains('travel') || lower.contains('ticket')) return 'flight_takeoff';
    if (lower.contains('finance') || lower.contains('bank') || lower.contains('upi')) return 'account_balance_wallet';
    if (lower.contains('chat') || lower.contains('social') || lower.contains('whatsapp')) return 'chat_bubble_outline';
    if (lower.contains('doc') || lower.contains('id') || lower.contains('passport')) return 'description';
    if (lower.contains('meme') || lower.contains('humor')) return 'sentiment_satisfied_alt';
    return 'folder';
  }

  String _inferCategoryColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('project') || lower.contains('work')) return '6366F1';
    if (lower.contains('payroll') || lower.contains('salary')) return '10B981';
    if (lower.contains('shop') || lower.contains('amazon')) return 'F97316';
    if (lower.contains('shoe') || lower.contains('fashion')) return 'EC4899';
    if (lower.contains('learn') || lower.contains('tutorial')) return '8B5CF6';
    if (lower.contains('code') || lower.contains('tech') || lower.contains('flutter')) return '06B6D4';
    if (lower.contains('flight') || lower.contains('travel')) return '3B82F6';
    if (lower.contains('finance') || lower.contains('bank')) return '10B981';
    if (lower.contains('social') || lower.contains('whatsapp')) return '22C55E';
    if (lower.contains('doc') || lower.contains('id')) return 'F59E0B';
    if (lower.contains('meme')) return 'EAB308';
    return '6366F1';
  }

  Future<void> upsertCategory(CategoryModel category) async {
    final db = await database;

    final existingWithSameName = await db.query(
      'categories',
      where: 'LOWER(name) = LOWER(?) AND id != ?',
      whereArgs: [category.name, category.id],
    );

    if (existingWithSameName.isNotEmpty) {
      for (final oldRow in existingWithSameName) {
        final oldId = oldRow['id'] as String;
        await db.update(
          'screenshots',
          {'category_id': category.id, 'category_name': category.name},
          where: 'category_id = ?',
          whereArgs: [oldId],
        );
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

    // 2. Auto-classify and re-organize screenshots into dynamic hierarchical Smart Folders
    await autoClassifyAndOrganizeScreenshots(forceReclassifyAll: false);
  }

  /// Automatically categorizes and organizes all screenshots into proper dynamic hierarchical Smart Folders.
  /// If [forceReclassifyAll] is true, re-evaluates all screenshots.
  Future<int> autoClassifyAndOrganizeScreenshots({bool forceReclassifyAll = false}) async {
    final db = await database;
    const classifier = MediaClassifier();

    final String whereClause;
    final List<dynamic> whereArgs;

    if (forceReclassifyAll) {
      whereClause = 'is_mock = 0';
      whereArgs = [];
    } else {
      whereClause = 'is_mock = 0 AND (category_id = ? OR category_id = \'\' OR category_id IS NULL OR category_name = ? OR category_name = \'\' OR category_name = \'Notes & Knowledge\' OR subcategory IS NULL OR subcategory = \'\' OR subcategory = \'General\')';
      whereArgs = [CategoryModel.unsortedId, CategoryModel.unsortedName];
    }

    final items = await db.query(
      'screenshots',
      where: whereClause,
      whereArgs: whereArgs,
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

      // Dynamically resolve or create the folder hierarchy
      final targetCat = await getOrCreateFolderHierarchy(result.folderPath);

      await db.update(
        'screenshots',
        {
          'category_id': targetCat.id,
          'category_name': targetCat.name,
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

  // ==================== CLASSIFICATION HISTORY ====================

  Future<void> saveClassificationHistory({
    required String screenshotId,
    required String category,
    String? subCategory,
    List<String> tags = const [],
    double confidence = 0.0,
    String modelName = 'contextvault-local-engine',
  }) async {
    final db = await database;
    const uuid = Uuid();
    await db.insert('classification_history', {
      'id': 'hist_${uuid.v4()}',
      'screenshot_id': screenshotId,
      'category': category,
      'sub_category': subCategory,
      'tags_json': tags.join(','),
      'confidence': confidence,
      'model_name': modelName,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getClassificationHistory(String screenshotId) async {
    final db = await database;
    return await db.query(
      'classification_history',
      where: 'screenshot_id = ?',
      whereArgs: [screenshotId],
      orderBy: 'created_at DESC',
    );
  }
}
