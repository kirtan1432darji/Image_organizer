import '../constants/media_scanner_constants.dart';

/// Pure classifier for images and videos across Android and iOS
class MediaClassifier {
  const MediaClassifier();

  /// Classifies media discovered on Android using MediaStore metadata and path details
  DeviceMediaType classifyAndroidMedia({
    String? filePath,
    String? relativePath,
    String? albumName,
    String? fileName,
    String? mimeType,
    bool isVideo = false,
  }) {
    final path = (filePath ?? '').toLowerCase();
    final relPath = (relativePath ?? '').toLowerCase();
    final album = (albumName ?? '').toLowerCase();
    final name = (fileName ?? '').toLowerCase();
    final mime = (mimeType ?? '').toLowerCase();

    // 1. WhatsApp Statuses (.Statuses)
    if (path.contains('/.statuses') ||
        relPath.contains('/.statuses') ||
        album.contains('.statuses') ||
        album == 'statuses') {
      return DeviceMediaType.whatsappStatus;
    }

    // 2. WhatsApp Images / Media
    if (path.contains('com.whatsapp/whatsapp/media/whatsapp images') ||
        path.contains('/whatsapp/media/whatsapp images') ||
        relPath.contains('whatsapp images') ||
        album == 'whatsapp images' ||
        album == 'whatsapp') {
      return DeviceMediaType.whatsappImage;
    }

    // 3. Telegram Images / Media
    if (path.contains('org.telegram.messenger/telegram/telegram images') ||
        path.contains('/telegram/telegram images') ||
        relPath.contains('telegram images') ||
        album == 'telegram images' ||
        album == 'telegram') {
      return DeviceMediaType.telegramImage;
    }

    // 4. Screen Recordings
    if (isVideo || mime.startsWith('video/')) {
      if (path.contains('screenrecords') ||
          path.contains('screenrecorder') ||
          path.contains('screen recordings') ||
          relPath.contains('screenrecords') ||
          relPath.contains('screenrecorder') ||
          relPath.contains('screen recordings') ||
          album.contains('screenrecord') ||
          album.contains('screen recorder') ||
          album.contains('screen recordings') ||
          name.contains('screen_recording') ||
          name.contains('screenrecord')) {
        return DeviceMediaType.screenRecording;
      }
    }

    // 5. Screenshots
    if (isScreenshotPath(path) ||
        isScreenshotPath(relPath) ||
        isScreenshotAlbum(album) ||
        isScreenshotFileName(name)) {
      return DeviceMediaType.screenshot;
    }

    // 6. Downloads
    if (path.contains('/download') ||
        relPath.contains('download') ||
        album == 'download' ||
        album == 'downloads') {
      return DeviceMediaType.download;
    }

    // 7. Camera photos / videos
    if (path.contains('/dcim/camera') ||
        path.contains('/dcim/100media') ||
        path.contains('/dcim/100andro') ||
        relPath.contains('dcim/camera') ||
        album == 'camera' ||
        album == '100media') {
      return DeviceMediaType.camera;
    }

    return DeviceMediaType.other;
  }

  /// Classifies media discovered on iOS using PhotoKit smart album types & album titles
  DeviceMediaType classifyIosMedia({
    required String albumName,
    bool isScreenshotSmartAlbum = false,
    bool isScreenRecordingSmartAlbum = false,
    String? fileName,
    bool isVideo = false,
  }) {
    final album = albumName.trim().toLowerCase();
    final name = (fileName ?? '').toLowerCase();

    // 1. Native iOS Screenshots smart album
    if (isScreenshotSmartAlbum || album == 'screenshots') {
      return DeviceMediaType.screenshot;
    }

    // 2. Native iOS Screen Recordings smart album
    if (isScreenRecordingSmartAlbum ||
        album == 'screen recordings' ||
        album == 'screen recordings') {
      return DeviceMediaType.screenRecording;
    }

    // 3. Exact recognizable WhatsApp user album on iOS
    if (album == 'whatsapp' || album == 'whatsapp images') {
      return DeviceMediaType.whatsappImage;
    }

    // 4. Exact recognizable Telegram user album on iOS
    if (album == 'telegram' || album == 'telegram images') {
      return DeviceMediaType.telegramImage;
    }

    // 5. Camera Roll / Recents / All Photos
    if (album == 'recents' ||
        album == 'camera roll' ||
        album == 'all photos' ||
        album == 'user library' ||
        album.isEmpty) {
      if (isScreenshotFileName(name)) {
        return DeviceMediaType.screenshot;
      }
      return DeviceMediaType.camera;
    }

    // 6. Default to other (never guess WhatsApp/Telegram on iOS without album)
    return DeviceMediaType.other;
  }

  /// Infers source application from file name or path
  String? inferSourceApp(String pathOrTitle) {
    final lower = pathOrTitle.toLowerCase();
    if (lower.contains('whatsapp')) return 'WhatsApp';
    if (lower.contains('telegram')) return 'Telegram';
    if (lower.contains('instagram')) return 'Instagram';
    if (lower.contains('twitter') || lower.contains('x_') || lower.contains('x.com')) return 'X / Twitter';
    if (lower.contains('slack')) return 'Slack';
    if (lower.contains('reddit')) return 'Reddit';
    if (lower.contains('amazon')) return 'Amazon';
    if (lower.contains('chrome')) return 'Google Chrome';
    if (lower.contains('safari')) return 'Safari';
    if (lower.contains('youtube')) return 'YouTube';
    if (lower.contains('linkedin')) return 'LinkedIn';
    if (lower.contains('tiktok')) return 'TikTok';
    if (lower.contains('facebook') || lower.contains('fb_')) return 'Facebook';
    if (lower.contains('screen recorder') || lower.contains('screenrecords')) return 'Screen Recorder';
    return null;
  }

  bool isScreenshotPath(String path) {
    return path.contains('pictures/screenshots') ||
        path.contains('dcim/screenshots') ||
        path.contains('pictures/screenshots') ||
        path.contains('/screenshots') ||
        path.contains('pictures/screen_shots') ||
        path.contains('pictures/capture');
  }

  bool isScreenshotAlbum(String album) {
    return album == 'screenshots' ||
        album == 'screenshot' ||
        album == 'screen_shot' ||
        album == 'screen shots' ||
        album == 'captures' ||
        album == 'capture' ||
        album == 'screencaps' ||
        album == 'screencap' ||
        album.contains('screenshot');
  }

  bool isScreenshotFileName(String fileName) {
    return fileName.startsWith('screenshot') ||
        fileName.startsWith('screen_shot') ||
        fileName.startsWith('screenshot_') ||
        fileName.startsWith('scrn') ||
        fileName.startsWith('capture_') ||
        fileName.contains('screenshot') ||
        fileName.contains('screencap');
  }
}
