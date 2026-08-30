class OcrBlock {
  final String text;
  final double confidence;
  final List<double>? boundingBox; // [left, top, right, bottom]

  const OcrBlock({
    required this.text,
    this.confidence = 1.0,
    this.boundingBox,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'confidence': confidence,
      'bounding_box': boundingBox,
    };
  }

  factory OcrBlock.fromMap(Map<String, dynamic> map) {
    return OcrBlock(
      text: map['text'] as String? ?? '',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
      boundingBox: (map['bounding_box'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
    );
  }
}

class OcrResultModel {
  final String screenshotId;
  final String rawText;
  final String language;
  final double confidence;
  final List<OcrBlock> blocks;
  final DateTime createdAt;

  const OcrResultModel({
    required this.screenshotId,
    required this.rawText,
    this.language = 'en',
    this.confidence = 1.0,
    this.blocks = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'screenshot_id': screenshotId,
      'raw_text': rawText,
      'language': language,
      'confidence': confidence,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory OcrResultModel.fromMap(Map<String, dynamic> map, [List<OcrBlock> blocks = const []]) {
    return OcrResultModel(
      screenshotId: map['screenshot_id'] as String,
      rawText: map['raw_text'] as String? ?? '',
      language: map['language'] as String? ?? 'en',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
      blocks: blocks,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory OcrResultModel.fromJson(Map<String, dynamic> json) =>
      OcrResultModel.fromMap(json);
}
