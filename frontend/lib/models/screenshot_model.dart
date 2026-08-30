import 'tag_model.dart';

class ScreenshotModel {
  final String id;
  final String deviceAssetId;
  final String filePath;
  final String fileName;
  final DateTime createdAt;
  final int width;
  final int height;
  final int fileSize;
  final String categoryId;
  final String categoryName;
  final String subcategory;
  final double confidence;
  final String? sourceApp;
  final bool isFavorite;
  final bool isReviewed;
  final bool isSynced;
  final String ocrStatus; // 'none', 'pending', 'processing', 'completed', 'failed'
  final String? ocrText;
  final List<TagModel> tags;
  final DateTime? lastScannedAt;
  final bool isMock;

  const ScreenshotModel({
    required this.id,
    this.deviceAssetId = '',
    required this.filePath,
    required this.fileName,
    required this.createdAt,
    this.width = 1080,
    this.height = 2400,
    this.fileSize = 0,
    this.categoryId = 'unsorted',
    this.categoryName = 'Unsorted',
    this.subcategory = '',
    this.confidence = 0.0,
    this.sourceApp,
    this.isFavorite = false,
    this.isReviewed = false,
    this.isSynced = false,
    this.ocrStatus = 'none',
    this.ocrText,
    this.tags = const [],
    this.lastScannedAt,
    this.isMock = false,
  });

  double get aspectRatio => (width > 0 && height > 0) ? (width / height) : (9 / 16);

  bool get hasHighConfidence => confidence >= 0.85;
  bool get needsReview => !isReviewed && (confidence < 0.70 || categoryId == 'unsorted');

  ScreenshotModel copyWith({
    String? id,
    String? deviceAssetId,
    String? filePath,
    String? fileName,
    DateTime? createdAt,
    int? width,
    int? height,
    int? fileSize,
    String? categoryId,
    String? categoryName,
    String? subcategory,
    double? confidence,
    String? sourceApp,
    bool? isFavorite,
    bool? isReviewed,
    bool? isSynced,
    String? ocrStatus,
    String? ocrText,
    List<TagModel>? tags,
    DateTime? lastScannedAt,
    bool? isMock,
  }) {
    return ScreenshotModel(
      id: id ?? this.id,
      deviceAssetId: deviceAssetId ?? this.deviceAssetId,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      createdAt: createdAt ?? this.createdAt,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSize: fileSize ?? this.fileSize,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      subcategory: subcategory ?? this.subcategory,
      confidence: confidence ?? this.confidence,
      sourceApp: sourceApp ?? this.sourceApp,
      isFavorite: isFavorite ?? this.isFavorite,
      isReviewed: isReviewed ?? this.isReviewed,
      isSynced: isSynced ?? this.isSynced,
      ocrStatus: ocrStatus ?? this.ocrStatus,
      ocrText: ocrText ?? this.ocrText,
      tags: tags ?? this.tags,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
      isMock: isMock ?? this.isMock,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_asset_id': deviceAssetId,
      'file_path': filePath,
      'file_name': fileName,
      'created_at': createdAt.toIso8601String(),
      'width': width,
      'height': height,
      'file_size': fileSize,
      'category_id': categoryId,
      'category_name': categoryName,
      'subcategory': subcategory,
      'confidence': confidence,
      'source_app': sourceApp,
      'is_favorite': isFavorite ? 1 : 0,
      'is_reviewed': isReviewed ? 1 : 0,
      'is_synced': isSynced ? 1 : 0,
      'ocr_status': ocrStatus,
      'ocr_text': ocrText,
      'last_scanned_at': lastScannedAt?.toIso8601String(),
      'is_mock': isMock ? 1 : 0,
    };
  }

  factory ScreenshotModel.fromMap(Map<String, dynamic> map, [List<TagModel> tags = const []]) {
    return ScreenshotModel(
      id: map['id'] as String,
      deviceAssetId: map['device_asset_id'] as String? ?? '',
      filePath: map['file_path'] as String? ?? '',
      fileName: map['file_name'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      width: map['width'] as int? ?? 1080,
      height: map['height'] as int? ?? 2400,
      fileSize: map['file_size'] as int? ?? 0,
      categoryId: map['category_id'] as String? ?? 'unsorted',
      categoryName: map['category_name'] as String? ?? 'Unsorted',
      subcategory: map['subcategory'] as String? ?? '',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      sourceApp: map['source_app'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      isReviewed: (map['is_reviewed'] as int? ?? 0) == 1,
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
      ocrStatus: map['ocr_status'] as String? ?? 'none',
      ocrText: map['ocr_text'] as String?,
      tags: tags,
      lastScannedAt: map['last_scanned_at'] != null
          ? DateTime.parse(map['last_scanned_at'] as String)
          : null,
      isMock: (map['is_mock'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory ScreenshotModel.fromJson(Map<String, dynamic> json) =>
      ScreenshotModel.fromMap(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenshotModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
