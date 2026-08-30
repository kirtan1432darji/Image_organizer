import 'dart:convert';

class SyncQueueItemModel {
  final String id;
  final String endpoint;
  final String httpMethod; // POST, PUT, DELETE
  final Map<String, dynamic> payload;
  final int retryCount;
  final String status; // 'pending', 'processing', 'failed'
  final DateTime createdAt;
  final String? lastError;

  const SyncQueueItemModel({
    required this.id,
    required this.endpoint,
    this.httpMethod = 'POST',
    required this.payload,
    this.retryCount = 0,
    this.status = 'pending',
    required this.createdAt,
    this.lastError,
  });

  SyncQueueItemModel copyWith({
    String? id,
    String? endpoint,
    String? httpMethod,
    Map<String, dynamic>? payload,
    int? retryCount,
    String? status,
    DateTime? createdAt,
    String? lastError,
  }) {
    return SyncQueueItemModel(
      id: id ?? this.id,
      endpoint: endpoint ?? this.endpoint,
      httpMethod: httpMethod ?? this.httpMethod,
      payload: payload ?? this.payload,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'endpoint': endpoint,
      'http_method': httpMethod,
      'payload': jsonEncode(payload),
      'retry_count': retryCount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'last_error': lastError,
    };
  }

  factory SyncQueueItemModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> parsedPayload = {};
    try {
      final raw = map['payload'];
      if (raw is String) {
        parsedPayload = jsonDecode(raw) as Map<String, dynamic>;
      } else if (raw is Map) {
        parsedPayload = Map<String, dynamic>.from(raw);
      }
    } catch (_) {}

    return SyncQueueItemModel(
      id: map['id'] as String,
      endpoint: map['endpoint'] as String,
      httpMethod: map['http_method'] as String? ?? 'POST',
      payload: parsedPayload,
      retryCount: map['retry_count'] as int? ?? 0,
      status: map['status'] as String? ?? 'pending',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      lastError: map['last_error'] as String?,
    );
  }
}
