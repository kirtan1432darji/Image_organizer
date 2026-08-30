class ClassificationResultModel {
  final String screenshotId;
  final String categoryId;
  final String categoryName;
  final String subcategory;
  final double confidence;
  final String? sourceApp;
  final List<String> suggestedTags;
  final String summary;
  final Map<String, dynamic>? keyEntities; // e.g. amount, merchant, date, url

  const ClassificationResultModel({
    required this.screenshotId,
    required this.categoryId,
    required this.categoryName,
    this.subcategory = '',
    required this.confidence,
    this.sourceApp,
    this.suggestedTags = const [],
    this.summary = '',
    this.keyEntities,
  });

  Map<String, dynamic> toJson() {
    return {
      'screenshot_id': screenshotId,
      'category_id': categoryId,
      'category_name': categoryName,
      'subcategory': subcategory,
      'confidence': confidence,
      'source_app': sourceApp,
      'suggested_tags': suggestedTags,
      'summary': summary,
      'key_entities': keyEntities,
    };
  }

  factory ClassificationResultModel.fromJson(Map<String, dynamic> json) {
    return ClassificationResultModel(
      screenshotId: json['screenshot_id'] as String? ?? '',
      categoryId: json['category_id'] as String? ?? 'unsorted',
      categoryName: json['category_name'] as String? ?? 'Unsorted',
      subcategory: json['subcategory'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      sourceApp: json['source_app'] as String?,
      suggestedTags: (json['suggested_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      summary: json['summary'] as String? ?? '',
      keyEntities: json['key_entities'] as Map<String, dynamic>?,
    );
  }
}
