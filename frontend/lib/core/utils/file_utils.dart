import 'dart:math';

class FileUtils {
  FileUtils._();

  static String formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    final clampedIndex = i.clamp(0, suffixes.length - 1);
    final size = bytes / pow(1024, clampedIndex);
    return '${size.toStringAsFixed(decimals)} ${suffixes[clampedIndex]}';
  }

  static String formatResolution(int width, int height) {
    if (width <= 0 || height <= 0) return 'Unknown';
    return '$width × $height px';
  }
}
