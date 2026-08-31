import 'package:flutter_test/flutter_test.dart';
import 'package:ai_screenshot_organizer/core/constants/media_scanner_constants.dart';
import 'package:ai_screenshot_organizer/core/services/media_classifier.dart';
import 'package:ai_screenshot_organizer/core/services/direct_path_scanner.dart';

void main() {
  group('MediaScannerConstants & OEM Path Priority Tests', () {
    test('OPPO, OnePlus, and Realme screenshot path priority order is preserved', () {
      expect(MediaScannerConstants.screenshotPaths[0], '/storage/emulated/0/Pictures/Screenshots');
      expect(MediaScannerConstants.screenshotPaths[1], '/storage/emulated/0/DCIM/Screenshots');
      expect(MediaScannerConstants.screenshotPaths[2], '/storage/emulated/0/Pictures/ScreenShots');
      expect(MediaScannerConstants.screenshotPaths[3], '/storage/emulated/0/Screenshots');
    });

    test('Samsung, Pixel, and Xiaomi screen recording paths are defined in priority order', () {
      expect(MediaScannerConstants.screenRecordingPaths, contains('/storage/emulated/0/Movies/ScreenRecords'));
      expect(MediaScannerConstants.screenRecordingPaths, contains('/storage/emulated/0/DCIM/ScreenRecorder'));
      expect(MediaScannerConstants.screenRecordingPaths, contains('/storage/emulated/0/Movies/Screen recordings'));
    });

    test('Supported image and video extensions are complete and valid', () {
      expect(MediaScannerConstants.isImageExtension('jpg'), isTrue);
      expect(MediaScannerConstants.isImageExtension('JPEG'), isTrue);
      expect(MediaScannerConstants.isImageExtension('.png'), isTrue);
      expect(MediaScannerConstants.isImageExtension('webp'), isTrue);
      expect(MediaScannerConstants.isImageExtension('heic'), isTrue);
      expect(MediaScannerConstants.isImageExtension('heif'), isTrue);
      expect(MediaScannerConstants.isImageExtension('gif'), isTrue);
      expect(MediaScannerConstants.isImageExtension('bmp'), isTrue);

      expect(MediaScannerConstants.isVideoExtension('mp4'), isTrue);
      expect(MediaScannerConstants.isVideoExtension('mov'), isTrue);
      expect(MediaScannerConstants.isVideoExtension('mkv'), isTrue);
      expect(MediaScannerConstants.isVideoExtension('webm'), isTrue);
      expect(MediaScannerConstants.isVideoExtension('3gp'), isTrue);

      expect(MediaScannerConstants.isSupportedExtension('exe'), isFalse);
      expect(MediaScannerConstants.isSupportedExtension('pdf'), isFalse);
    });
  });

  group('MediaClassifier Android Classification Tests', () {
    const classifier = MediaClassifier();

    test('Classifies OPPO ColorOS screenshot paths correctly', () {
      final type1 = classifier.classifyAndroidMedia(
        filePath: '/storage/emulated/0/Pictures/Screenshots/Screenshot_20260831_120000.png',
      );
      expect(type1, DeviceMediaType.screenshot);

      final type2 = classifier.classifyAndroidMedia(
        filePath: '/storage/emulated/0/DCIM/Screenshots/Screenshot_2026.jpg',
      );
      expect(type2, DeviceMediaType.screenshot);
    });

    test('Classifies Samsung / Xiaomi screenshot and recording paths correctly', () {
      final ssType = classifier.classifyAndroidMedia(
        filePath: '/storage/emulated/0/Screenshots/Screenshot_2026.png',
      );
      expect(ssType, DeviceMediaType.screenshot);

      final recType = classifier.classifyAndroidMedia(
        filePath: '/storage/emulated/0/Movies/Screen recordings/Screen_Recording_2026.mp4',
        isVideo: true,
      );
      expect(recType, DeviceMediaType.screenRecording);
    });

    test('Classifies WhatsApp Images and hidden WhatsApp Statuses correctly on Android', () {
      final waImg = classifier.classifyAndroidMedia(
        filePath: '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images/IMG-2026.jpg',
      );
      expect(waImg, DeviceMediaType.whatsappImage);

      final waStatus = classifier.classifyAndroidMedia(
        filePath: '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses/status_123.jpg',
      );
      expect(waStatus, DeviceMediaType.whatsappStatus);
    });

    test('Classifies Telegram Images correctly on Android', () {
      final tgImg = classifier.classifyAndroidMedia(
        filePath: '/storage/emulated/0/Android/media/org.telegram.messenger/Telegram/Telegram Images/photo_2026.jpg',
      );
      expect(tgImg, DeviceMediaType.telegramImage);
    });

    test('Classifies Camera photos and Downloads on Android', () {
      final cam = classifier.classifyAndroidMedia(
        filePath: '/storage/emulated/0/DCIM/Camera/IMG_20260831.jpg',
      );
      expect(cam, DeviceMediaType.camera);

      final dl = classifier.classifyAndroidMedia(
        filePath: '/storage/emulated/0/Download/document_screenshot.pdf.jpg',
      );
      expect(dl, DeviceMediaType.download);
    });
  });

  group('MediaClassifier iOS PhotoKit Classification Tests', () {
    const classifier = MediaClassifier();

    test('Classifies native iOS Screenshots smart album as screenshot', () {
      final type = classifier.classifyIosMedia(
        albumName: 'Screenshots',
        isScreenshotSmartAlbum: true,
        fileName: 'IMG_0001.PNG',
      );
      expect(type, DeviceMediaType.screenshot);
    });

    test('Classifies native iOS Screen Recordings smart album as screenRecording', () {
      final type = classifier.classifyIosMedia(
        albumName: 'Screen Recordings',
        isScreenRecordingSmartAlbum: true,
        fileName: 'RPReplay_Final.MP4',
        isVideo: true,
      );
      expect(type, DeviceMediaType.screenRecording);
    });

    test('Classifies iOS Camera Roll / Recents as camera', () {
      final type = classifier.classifyIosMedia(
        albumName: 'Recents',
        fileName: 'IMG_4321.HEIC',
      );
      expect(type, DeviceMediaType.camera);
    });

    test('Classifies user WhatsApp or Telegram album on iOS only when explicitly named', () {
      final waType = classifier.classifyIosMedia(
        albumName: 'WhatsApp',
        fileName: 'IMG_5555.JPG',
      );
      expect(waType, DeviceMediaType.whatsappImage);

      final tgType = classifier.classifyIosMedia(
        albumName: 'Telegram',
        fileName: 'photo_1.JPG',
      );
      expect(tgType, DeviceMediaType.telegramImage);
    });

    test('Does not falsely classify random files as WhatsApp/Telegram on iOS without album', () {
      final type = classifier.classifyIosMedia(
        albumName: 'Family Vacation',
        fileName: 'whatsapp_style_image.jpg',
      );
      expect(type, DeviceMediaType.other);
    });
  });

  group('DirectPathScanner Platform Guard & Error Handling Tests', () {
    const scanner = DirectPathScanner();

    test('Returns empty list safely when scanning non-existent paths without throwing', () {
      final results = scanner.scanDirectories(
        customPaths: [
          '/non/existent/path/Screenshots',
          'C:\\invalid\\path\\test',
        ],
      );
      expect(results, isEmpty);
    });

    test('Deduplication correctly prevents duplicate items in DiscoveredMediaItem', () {
      final now = DateTime.now();
      final item1 = DiscoveredMediaItem(
        filePath: '/storage/emulated/0/Pictures/Screenshots/test.png',
        fileName: 'test.png',
        fileSize: 1024,
        modifiedAt: now,
        mediaType: DeviceMediaType.screenshot,
        isVideo: false,
      );

      final model = item1.toScreenshotModel(
        categoryId: 'unsorted',
        categoryName: 'Unsorted',
        deviceAssetId: 'test_asset_id',
      );

      expect(model.deviceAssetId, 'test_asset_id');
      expect(model.fileName, 'test.png');
      expect(model.sourceApp, 'Screenshots');
    });
  });
}
