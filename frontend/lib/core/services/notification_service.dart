import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static const MethodChannel _channel = MethodChannel('contextvault/notifications');
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  /// Requests notification permission on Android 13+ (API 33+)
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    try {
      final status = await Permission.notification.status;
      if (status.isGranted) return true;

      final result = await Permission.notification.request();
      return result.isGranted;
    } catch (e) {
      debugPrint('[NotificationService] Error requesting notification permission: $e');
      return false;
    }
  }

  /// Check if notification permission is currently granted
  Future<bool> hasNotificationPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      return await Permission.notification.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Shows local notification for an automatically organized screenshot
  Future<bool> showScreenshotOrganizedNotification({
    required String categoryName,
    String? subcategory,
    required String fileName,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return false;

    try {
      final sub = (subcategory != null && subcategory.isNotEmpty && subcategory != 'General')
          ? ' / $subcategory'
          : '';
      final body = 'Screenshot added to ContextVault → $categoryName$sub';

      final success = await _channel.invokeMethod<bool>('showNotification', {
        'title': 'ContextVault',
        'body': body,
      });

      debugPrint('[NotificationService] Notification displayed: $body');
      return success ?? true;
    } catch (e) {
      debugPrint('[NotificationService] Failed to show notification: $e');
      return false;
    }
  }
}
