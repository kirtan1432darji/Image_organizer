class ClassificationResultModel {
  final String screenshotId;
  final String categoryId;
  final String categoryName;
  final String? subCategoryId;
  final String subcategory;
  final List<String> folderPath;
  final double confidence;
  final String? sourceApp;
  final String? detectedApp;
  final List<String> suggestedTags;
  final List<String> keywords;
  final String summary;
  final bool isAutoCategorized;
  final Map<String, dynamic>? keyEntities; // e.g. amount, merchant, date, url

  const ClassificationResultModel({
    required this.screenshotId,
    required this.categoryId,
    required this.categoryName,
    this.subCategoryId,
    this.subcategory = '',
    this.folderPath = const [],
    required this.confidence,
    this.sourceApp,
    this.detectedApp,
    this.suggestedTags = const [],
    this.keywords = const [],
    this.summary = '',
    this.isAutoCategorized = true,
    this.keyEntities,
  });

  Map<String, dynamic> toJson() {
    return {
      'screenshot_id': screenshotId,
      'category_id': categoryId,
      'category_name': categoryName,
      'subcategory_id': subCategoryId,
      'subcategory': subcategory,
      'folder_path': folderPath,
      'confidence': confidence,
      'source_app': sourceApp,
      'detected_app': detectedApp,
      'suggested_tags': suggestedTags,
      'keywords': keywords,
      'summary': summary,
      'is_auto_categorized': isAutoCategorized,
      'key_entities': keyEntities,
    };
  }

  factory ClassificationResultModel.fromJson(Map<String, dynamic> json) {
    return ClassificationResultModel(
      screenshotId: json['screenshot_id'] as String? ?? '',
      categoryId: json['category_id'] as String? ?? 'unsorted',
      categoryName: json['category_name'] as String? ?? (json['category'] as String? ?? 'Unsorted'),
      subCategoryId: json['subcategory_id'] as String?,
      subcategory: json['subcategory'] as String? ?? (json['sub_category_name'] as String? ?? ''),
      folderPath: (json['folder_path'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [json['category_name'] as String? ?? 'Unsorted'],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      sourceApp: json['source_app'] as String?,
      detectedApp: json['detected_app'] as String? ?? json['source_app'] as String?,
      suggestedTags: (json['suggested_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      keywords: (json['keywords'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      summary: json['summary'] as String? ?? '',
      isAutoCategorized: json['is_auto_categorized'] as bool? ?? true,
      keyEntities: json['key_entities'] as Map<String, dynamic>?,
    );
  }
}
