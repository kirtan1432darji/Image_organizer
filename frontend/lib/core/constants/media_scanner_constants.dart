/// Device Media Types supported across Android and iOS
enum DeviceMediaType {
  camera,
  screenshot,
  screenRecording,
  download,
  whatsappImage,
  whatsappStatus,
  telegramImage,
  other,
}

extension DeviceMediaTypeExtension on DeviceMediaType {
  String get displayName {
    switch (this) {
      case DeviceMediaType.camera:
        return 'Camera';
      case DeviceMediaType.screenshot:
        return 'Screenshots';
      case DeviceMediaType.screenRecording:
        return 'Screen Recordings';
      case DeviceMediaType.download:
        return 'Downloads';
      case DeviceMediaType.whatsappImage:
        return 'WhatsApp Images';
      case DeviceMediaType.whatsappStatus:
        return 'WhatsApp Statuses';
      case DeviceMediaType.telegramImage:
        return 'Telegram';
      case DeviceMediaType.other:
        return 'Other Media';
    }
  }

  bool get isScreenshot => this == DeviceMediaType.screenshot;
  bool get isScreenRecording => this == DeviceMediaType.screenRecording;
  bool get isCapture => isScreenshot || isScreenRecording;
}

class MediaScannerConstants {
  MediaScannerConstants._();

  // --- Android OEM Priority Filesystem Paths ---

  /// Camera photos
  static const List<String> cameraPaths = [
    '/storage/emulated/0/DCIM/Camera',
  ];

  /// Screenshot folders in priority order across OPPO/OnePlus/Realme, Samsung, Xiaomi, Pixel, Vivo, Huawei
  static const List<String> screenshotPaths = [
    // OPPO, OnePlus, Realme / ColorOS / OxygenOS
    '/storage/emulated/0/Pictures/Screenshots',
    '/storage/emulated/0/DCIM/Screenshots',
    '/storage/emulated/0/Pictures/ScreenShots',

    // Common alternatives on Samsung, Xiaomi, Vivo, Huawei, Motorola, Pixel
    '/storage/emulated/0/Screenshots',
  ];

  /// Screen recording folders in priority order
  static const List<String> screenRecordingPaths = [
    // OPPO / OnePlus / Realme
    '/storage/emulated/0/Movies/ScreenRecords',
    '/storage/emulated/0/DCIM/ScreenRecorder',

    // Samsung, Pixel, Xiaomi, Vivo, Huawei and other Android phones
    '/storage/emulated/0/Movies/Screen recordings',
    '/storage/emulated/0/Movies/ScreenRecords',
    '/storage/emulated/0/Movies/ScreenRecorder',
    '/storage/emulated/0/DCIM/Screen recordings',
    '/storage/emulated/0/DCIM/ScreenRecorder',
  ];

  /// Download folders
  static const List<String> downloadPaths = [
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Downloads',
  ];

  /// WhatsApp media folders
  static const List<String> whatsappImagePaths = [
    '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images',
    '/storage/emulated/0/WhatsApp/Media/WhatsApp Images', // legacy devices
  ];

  /// WhatsApp Status folders (hidden .Statuses)
  static const List<String> whatsappStatusPaths = [
    '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
    '/storage/emulated/0/WhatsApp/Media/.Statuses', // legacy devices
  ];

  /// Telegram media folders
  static const List<String> telegramImagePaths = [
    '/storage/emulated/0/Android/media/org.telegram.messenger/Telegram/Telegram Images',
    '/storage/emulated/0/Telegram/Telegram Images', // legacy devices
  ];

  // --- Supported Media File Extensions ---

  /// Image extensions supported
  static const Set<String> supportedImageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
    'gif',
    'bmp',
  };

  /// Video extensions supported
  static const Set<String> supportedVideoExtensions = {
    'mp4',
    'mov',
    'mkv',
    'webm',
    '3gp',
  };

  /// All supported media extensions
  static Set<String> get allSupportedExtensions => {
        ...supportedImageExtensions,
        ...supportedVideoExtensions,
      };

  /// Check if an extension is a supported image
  static bool isImageExtension(String ext) =>
      supportedImageExtensions.contains(ext.toLowerCase().replaceAll('.', ''));

  /// Check if an extension is a supported video
  static bool isVideoExtension(String ext) =>
      supportedVideoExtensions.contains(ext.toLowerCase().replaceAll('.', ''));

  /// Check if an extension is supported media
  static bool isSupportedExtension(String ext) =>
      allSupportedExtensions.contains(ext.toLowerCase().replaceAll('.', ''));
}
