class ContextTaskModel {
  final String id;
  final String title;
  final bool isCompleted;
  final String? dueDate;

  const ContextTaskModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.dueDate,
  });

  factory ContextTaskModel.fromJson(Map<String, dynamic> json) {
    return ContextTaskModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      isCompleted: json['isCompleted'] == true || json['completed'] == true,
      dueDate: json['dueDate']?.toString() ?? json['date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'dueDate': dueDate,
      };

  ContextTaskModel copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    String? dueDate,
  }) {
    return ContextTaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

class ContextEntityModel {
  final String name;
  final String type;
  final int count;

  const ContextEntityModel({
    required this.name,
    required this.type,
    this.count = 1,
  });

  factory ContextEntityModel.fromJson(Map<String, dynamic> json) {
    return ContextEntityModel(
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'General',
      count: (json['count'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'count': count,
      };
}

class ContextDateModel {
  final String event;
  final String date;

  const ContextDateModel({
    required this.event,
    required this.date,
  });

  factory ContextDateModel.fromJson(Map<String, dynamic> json) {
    return ContextDateModel(
      event: json['event']?.toString() ?? json['title']?.toString() ?? 'Event',
      date: json['date']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'event': event,
        'date': date,
      };
}

class ContextTimelineItemModel {
  final String screenshotId;
  final String title;
  final String description;
  final DateTime capturedAt;
  final String? imagePath;

  const ContextTimelineItemModel({
    required this.screenshotId,
    required this.title,
    required this.description,
    required this.capturedAt,
    this.imagePath,
  });

  factory ContextTimelineItemModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['capturedAt'] != null) {
      parsedDate = DateTime.tryParse(json['capturedAt'].toString()) ?? DateTime.now();
    } else if (json['createdAt'] != null) {
      parsedDate = DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return ContextTimelineItemModel(
      screenshotId: json['screenshotId']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['fileName']?.toString() ?? 'Screenshot',
      description: json['description']?.toString() ?? json['summary']?.toString() ?? json['ocrSnippet']?.toString() ?? '',
      capturedAt: parsedDate,
      imagePath: json['imagePath']?.toString() ?? json['filePath']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'screenshotId': screenshotId,
        'title': title,
        'description': description,
        'capturedAt': capturedAt.toIso8601String(),
        'imagePath': imagePath,
      };
}

class FolderContextModel {
  final String categoryId;
  final String categoryName;
  final String summary;
  final List<String> keywords;
  final double confidence;
  final int screenshotCount;
  final DateTime? lastUpdatedAt;
  final List<ContextTaskModel> tasks;
  final List<ContextEntityModel> entities;
  final List<String> people;
  final List<String> links;
  final List<ContextDateModel> dates;
  final List<String> apps;
  final List<String> topics;
  final List<ContextTimelineItemModel> timeline;

  const FolderContextModel({
    required this.categoryId,
    required this.categoryName,
    required this.summary,
    this.keywords = const [],
    this.confidence = 0.0,
    this.screenshotCount = 0,
    this.lastUpdatedAt,
    this.tasks = const [],
    this.entities = const [],
    this.people = const [],
    this.links = const [],
    this.dates = const [],
    this.apps = const [],
    this.topics = const [],
    this.timeline = const [],
  });

  factory FolderContextModel.fromJson(Map<String, dynamic> json) {
    // Parse keywords
    List<String> parsedKeywords = [];
    if (json['keywords'] is List) {
      parsedKeywords = (json['keywords'] as List).map((e) => e.toString()).toList();
    } else if (json['keyTopics'] is List) {
      parsedKeywords = (json['keyTopics'] as List).map((e) => e.toString()).toList();
    }

    // Parse tasks
    List<ContextTaskModel> parsedTasks = [];
    if (json['tasks'] is List) {
      parsedTasks = (json['tasks'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => ContextTaskModel.fromJson(e))
          .toList();
    }

    // Parse entities
    List<ContextEntityModel> parsedEntities = [];
    if (json['entities'] is List) {
      parsedEntities = (json['entities'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => ContextEntityModel.fromJson(e))
          .toList();
    }

    // Parse people
    List<String> parsedPeople = [];
    if (json['people'] is List) {
      parsedPeople = (json['people'] as List).map((e) => e.toString()).toList();
    } else {
      // Fallback: extract people from entities if present
      parsedPeople = parsedEntities
          .where((e) => e.type.toLowerCase() == 'person')
          .map((e) => e.name)
          .toList();
    }

    // Parse links
    List<String> parsedLinks = [];
    if (json['links'] is List) {
      parsedLinks = (json['links'] as List).map((e) => e.toString()).toList();
    }

    // Parse dates
    List<ContextDateModel> parsedDates = [];
    if (json['dates'] is List) {
      parsedDates = (json['dates'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => ContextDateModel.fromJson(e))
          .toList();
    }

    // Parse apps
    List<String> parsedApps = [];
    if (json['apps'] is List) {
      parsedApps = (json['apps'] as List).map((e) => e.toString()).toList();
    }

    // Parse topics
    List<String> parsedTopics = [];
    if (json['topics'] is List) {
      parsedTopics = (json['topics'] as List).map((e) => e.toString()).toList();
    }

    // Parse timeline
    List<ContextTimelineItemModel> parsedTimeline = [];
    if (json['timeline'] is List) {
      parsedTimeline = (json['timeline'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => ContextTimelineItemModel.fromJson(e))
          .toList();
    }

    DateTime? parsedDate;
    if (json['lastUpdatedAt'] != null) {
      parsedDate = DateTime.tryParse(json['lastUpdatedAt'].toString());
    } else if (json['lastGeneratedAt'] != null) {
      parsedDate = DateTime.tryParse(json['lastGeneratedAt'].toString());
    }

    return FolderContextModel(
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? json['name']?.toString() ?? 'Folder Context',
      summary: json['summary']?.toString() ?? '',
      keywords: parsedKeywords,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      screenshotCount: (json['screenshotCount'] as num?)?.toInt() ?? 0,
      lastUpdatedAt: parsedDate,
      tasks: parsedTasks,
      entities: parsedEntities,
      people: parsedPeople,
      links: parsedLinks,
      dates: parsedDates,
      apps: parsedApps,
      topics: parsedTopics,
      timeline: parsedTimeline,
    );
  }

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'categoryName': categoryName,
        'summary': summary,
        'keywords': keywords,
        'confidence': confidence,
        'screenshotCount': screenshotCount,
        'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
        'tasks': tasks.map((e) => e.toJson()).toList(),
        'entities': entities.map((e) => e.toJson()).toList(),
        'people': people,
        'links': links,
        'dates': dates.map((e) => e.toJson()).toList(),
        'apps': apps,
        'topics': topics,
        'timeline': timeline.map((e) => e.toJson()).toList(),
      };

  FolderContextModel copyWith({
    String? categoryId,
    String? categoryName,
    String? summary,
    List<String>? keywords,
    double? confidence,
    int? screenshotCount,
    DateTime? lastUpdatedAt,
    List<ContextTaskModel>? tasks,
    List<ContextEntityModel>? entities,
    List<String>? people,
    List<String>? links,
    List<ContextDateModel>? dates,
    List<String>? apps,
    List<String>? topics,
    List<ContextTimelineItemModel>? timeline,
  }) {
    return FolderContextModel(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      summary: summary ?? this.summary,
      keywords: keywords ?? this.keywords,
      confidence: confidence ?? this.confidence,
      screenshotCount: screenshotCount ?? this.screenshotCount,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      tasks: tasks ?? this.tasks,
      entities: entities ?? this.entities,
      people: people ?? this.people,
      links: links ?? this.links,
      dates: dates ?? this.dates,
      apps: apps ?? this.apps,
      topics: topics ?? this.topics,
      timeline: timeline ?? this.timeline,
    );
  }

  /// Empty representation for unanalyzed folders
  factory FolderContextModel.empty({
    required String categoryId,
    required String categoryName,
    int screenshotCount = 0,
  }) {
    return FolderContextModel(
      categoryId: categoryId,
      categoryName: categoryName,
      summary: '',
      keywords: const [],
      confidence: 0.0,
      screenshotCount: screenshotCount,
      lastUpdatedAt: null,
      tasks: const [],
      entities: const [],
      people: const [],
      links: const [],
      dates: const [],
      apps: const [],
      topics: const [],
      timeline: const [],
    );
  }

  bool get isEmpty => summary.isEmpty && keywords.isEmpty && tasks.isEmpty && timeline.isEmpty;
}
