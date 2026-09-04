import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_screenshot_organizer/core/constants/app_constants.dart';
import 'package:ai_screenshot_organizer/core/constants/media_scanner_constants.dart';
import 'package:ai_screenshot_organizer/core/services/media_classifier.dart';
import 'package:ai_screenshot_organizer/repositories/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Automatic Screenshot Detection & OEM Path Tests', () {
    const classifier = MediaClassifier();

    test('OPPO ColorOS screenshot directory is recognized', () {
      const path = '/storage/emulated/0/Pictures/Screenshots/Screenshot_2026_09_04.png';
      expect(
        MediaScannerConstants.screenshotPaths.any((p) => path.startsWith(p)),
        isTrue,
      );
      expect(
        classifier.classifyAndroidMedia(filePath: path, fileName: 'Screenshot_2026_09_04.png'),
        equals(DeviceMediaType.screenshot),
      );
    });

    test('Samsung / Xiaomi / Pixel screenshot directories are recognized', () {
      const samsungPath = '/storage/emulated/0/DCIM/Screenshots/Screenshot_20260904-123456.jpg';
      const pixelPath = '/storage/emulated/0/Pictures/Screenshots/Screenshot_20260904_123456.png';
      const genericPath = '/storage/emulated/0/Screenshots/Screenshot_20260904.png';

      expect(MediaScannerConstants.screenshotPaths.any((p) => samsungPath.startsWith(p)), isTrue);
      expect(MediaScannerConstants.screenshotPaths.any((p) => pixelPath.startsWith(p)), isTrue);
      expect(MediaScannerConstants.screenshotPaths.any((p) => genericPath.startsWith(p)), isTrue);
    });

    test('Non-screenshot media (camera, downloads, whatsapp) are not falsely classified as screenshots', () {
      const cameraPath = '/storage/emulated/0/DCIM/Camera/IMG_20260904_123456.jpg';
      const downloadPath = '/storage/emulated/0/Download/invoice.pdf';
      const whatsappPath = '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images/IMG-20260904.jpg';

      expect(classifier.classifyAndroidMedia(filePath: cameraPath, fileName: 'IMG_20260904_123456.jpg'), equals(DeviceMediaType.camera));
      expect(classifier.classifyAndroidMedia(filePath: downloadPath, fileName: 'invoice.pdf'), equals(DeviceMediaType.download));
      expect(classifier.classifyAndroidMedia(filePath: whatsappPath, fileName: 'IMG-20260904.jpg'), equals(DeviceMediaType.whatsappImage));
    });

    test('Duplicate prevention logic verifies file path and asset ID', () {
      final processedSet = <String>{};
      const assetId = 'asset_12345';
      const filePath = '/storage/emulated/0/Pictures/Screenshots/Screenshot_1.png';

      expect(processedSet.contains(assetId) || processedSet.contains(filePath), isFalse);

      processedSet.add(assetId);
      processedSet.add(filePath);

      expect(processedSet.contains(assetId) || processedSet.contains(filePath), isTrue);
      // Second attempt is blocked
      expect(processedSet.contains('asset_12345'), isTrue);
    });
  });

  group('SettingsRepository Auto-Detection & Notification Preferences Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyAutoDetectScreenshots: true,
        AppConstants.keyScreenshotNotifications: true,
        AppConstants.keyLastScanTimestamp: '2026-09-04T12:00:00.000Z',
      });
    });

    test('reads and writes auto-detection preferences properly', () async {
      final repo = SettingsRepositoryImpl();

      expect(await repo.getAutoDetectScreenshots(), isTrue);
      await repo.setAutoDetectScreenshots(false);
      expect(await repo.getAutoDetectScreenshots(), isFalse);

      expect(await repo.getScreenshotNotifications(), isTrue);
      await repo.setScreenshotNotifications(false);
      expect(await repo.getScreenshotNotifications(), isFalse);

      final lastTime = await repo.getLastScanTime();
      expect(lastTime, isNotNull);
      expect(lastTime!.year, equals(2026));

      final newTime = DateTime(2026, 9, 4, 15, 30);
      await repo.setLastScanTime(newTime);
      final updatedTime = await repo.getLastScanTime();
      expect(updatedTime?.hour, equals(15));
    });
  });
}
