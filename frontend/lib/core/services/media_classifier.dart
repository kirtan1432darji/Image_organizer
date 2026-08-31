import '../constants/media_scanner_constants.dart';

class ClassificationResult {
  final String categoryName;
  final String subcategory;
  final List<String> tags;
  final double confidence;

  const ClassificationResult({
    required this.categoryName,
    required this.subcategory,
    required this.tags,
    required this.confidence,
  });
}

/// Pure classifier for images and videos across Android and iOS
class MediaClassifier {
  const MediaClassifier();

  /// Comprehensive classification of a screenshot into Category, Subcategory, and Tags
  ClassificationResult classifyMediaItem({
    String? fileName,
    String? filePath,
    String? ocrText,
    String? sourceApp,
    String? visionDescription,
  }) {
    final text = (ocrText ?? '').toLowerCase();
    final name = (fileName ?? '').toLowerCase();
    final path = (filePath ?? '').toLowerCase();
    final app = (sourceApp ?? inferSourceApp(path.isNotEmpty ? path : name) ?? '').toLowerCase();
    final desc = (visionDescription ?? '').toLowerCase();

    // 1. Receipts & Invoices
    if (text.contains('invoice') || text.contains('receipt') || text.contains('subtotal') || text.contains('total') ||
        text.contains('tax') || text.contains('amount paid') || text.contains('bill') || text.contains('due date') ||
        text.contains('order #') || text.contains('order id') || text.contains('purchase') ||
        name.contains('receipt') || name.contains('invoice') || name.contains('bill') ||
        app.contains('uber eats') || app.contains('doordash') || app.contains('swiggy') || app.contains('zomato') ||
        desc.contains('receipt') || desc.contains('invoice') || desc.contains('bill')) {
      final tags = ['receipt', 'purchase'];
      String subCat = 'Shopping';

      if (text.contains('dining') || text.contains('restaurant') || text.contains('food') || text.contains('starbucks') ||
          text.contains('eats') || text.contains('cafe') || app.contains('swiggy') || app.contains('zomato')) {
        subCat = 'Dining';
        tags.add('food');
      } else if (text.contains('grocery') || text.contains('market') || text.contains('walmart') || text.contains('whole foods') || text.contains('instacart')) {
        subCat = 'Groceries';
        tags.add('groceries');
      } else if (text.contains('electric') || text.contains('water') || text.contains('internet') || text.contains('utility') || text.contains('bill')) {
        subCat = 'Utilities';
        tags.add('bills');
      } else if (text.contains('flight') || text.contains('hotel') || text.contains('airbnb') || text.contains('airline')) {
        subCat = 'Travel';
        tags.add('travel');
      }

      return ClassificationResult(
        categoryName: 'Receipts & Invoices',
        subcategory: subCat,
        tags: tags,
        confidence: 0.94,
      );
    }

    // 2. Finance & Banking
    if (text.contains('account balance') || text.contains('available balance') || text.contains('bank statement') ||
        text.contains('bank account') || text.contains('transfer') || text.contains('upi') || text.contains('crypto') ||
        text.contains('bitcoin') || text.contains('ethereum') || text.contains('portfolio') || text.contains('stocks') ||
        text.contains('nasdaq') || text.contains('chase') || text.contains('wells fargo') || text.contains('revolut') ||
        text.contains('credited') || text.contains('debited') || text.contains('inr') || text.contains('paid to') ||
        app.contains('bank') || app.contains('finance') || app.contains('crypto') || app.contains('wallet') ||
        app.contains('gpay') || app.contains('phonepe') || app.contains('paytm') || app.contains('binance') ||
        name.contains('upi') || name.contains('bank') || name.contains('payment')) {
      final tags = ['finance', 'money'];
      String subCat = 'Bank Statements';

      if (text.contains('crypto') || text.contains('btc') || text.contains('eth') || text.contains('binance') || text.contains('coinbase') || app.contains('crypto') || app.contains('binance')) {
        subCat = 'Crypto';
        tags.add('crypto');
      } else if (text.contains('stock') || text.contains('shares') || text.contains('nasdaq') || text.contains('dividend') || text.contains('robinhood') || text.contains('zerodha')) {
        subCat = 'Investments';
        tags.add('investing');
      } else if (text.contains('upi') || text.contains('sent to') || text.contains('transferred') || text.contains('venmo') || text.contains('zelle') || app.contains('gpay') || app.contains('phonepe') || app.contains('paytm')) {
        subCat = 'UPI & Transfers';
        tags.add('transfers');
      }

      return ClassificationResult(
        categoryName: 'Finance & Banking',
        subcategory: subCat,
        tags: tags,
        confidence: 0.92,
      );
    }

    // 3. Code & Tech
    if (text.contains('function') || text.contains('public class') || text.contains('import ') || text.contains('exception') ||
        text.contains('stack trace') || text.contains('github') || text.contains('git commit') || text.contains('const ') ||
        text.contains('npm ') || text.contains('docker') || text.contains('kubernetes') || text.contains('terminal') ||
        text.contains('bash') || text.contains('powershell') || text.contains('flutter') || text.contains('widget') ||
        app.contains('github') || app.contains('vscode') || app.contains('terminal') || app.contains('stack overflow') ||
        name.contains('code') || name.contains('terminal') || name.contains('stack') || name.contains('error')) {
      final tags = ['developer', 'tech'];
      String subCat = 'Code Snippets';

      if (text.contains('exception') || text.contains('error') || text.contains('stack trace') || text.contains('fatal') || text.contains('failed')) {
        subCat = 'Error Logs';
        tags.add('debug');
      } else if (text.contains('terminal') || text.contains('bash') || text.contains('zsh') || text.contains('command not found') || text.contains('sudo') || app.contains('terminal')) {
        subCat = 'Terminal';
        tags.add('cli');
      }

      return ClassificationResult(
        categoryName: 'Code & Tech',
        subcategory: subCat,
        tags: tags,
        confidence: 0.95,
      );
    }

    // 4. Social & Chat
    if (app.contains('whatsapp') || app.contains('telegram') || app.contains('instagram') || app.contains('twitter') ||
        app.contains('x') || app.contains('discord') || app.contains('slack') || app.contains('messenger') ||
        path.contains('whatsapp') || path.contains('telegram') || name.contains('whatsapp') || name.contains('telegram') ||
        text.contains('online') || text.contains('typing...') || text.contains('message') || text.contains('retweet') ||
        text.contains('replying to') || text.contains('direct message')) {
      final tags = ['social', 'chat'];
      String subCat = 'Chat';

      if (app.contains('whatsapp') || path.contains('whatsapp') || name.contains('whatsapp')) {
        subCat = 'WhatsApp';
        tags.add('whatsapp');
      } else if (app.contains('telegram') || path.contains('telegram') || name.contains('telegram')) {
        subCat = 'Telegram';
        tags.add('telegram');
      } else if (app.contains('twitter') || app.contains('x') || text.contains('retweet') || text.contains('tweet')) {
        subCat = 'Twitter/X';
        tags.add('twitter');
      } else if (app.contains('instagram') || text.contains('story') || text.contains('reels')) {
        subCat = 'Instagram';
        tags.add('instagram');
      } else if (app.contains('discord') || text.contains('discord')) {
        subCat = 'Discord';
        tags.add('discord');
      } else if (app.contains('slack') || text.contains('slack')) {
        subCat = 'Slack';
        tags.add('slack');
      }

      return ClassificationResult(
        categoryName: 'Social & Chat',
        subcategory: subCat,
        tags: tags,
        confidence: 0.93,
      );
    }

    // 5. Travel & Tickets
    if (text.contains('boarding pass') || text.contains('flight') || text.contains('gate') || text.contains('seat') ||
        text.contains('hotel booking') || text.contains('reservation') || text.contains('train ticket') || text.contains('pnr') ||
        text.contains('check-in') || name.contains('flight') || name.contains('ticket') || name.contains('boarding') ||
        app.contains('airbnb') || app.contains('booking.com') || app.contains('makemytrip') || app.contains('irctc') ||
        desc.contains('ticket') || desc.contains('boarding pass')) {
      final tags = ['travel', 'tickets'];
      String subCat = 'Tickets';

      if (text.contains('boarding pass') || text.contains('flight') || text.contains('gate') || text.contains('airline')) {
        subCat = 'Boarding Passes';
        tags.add('flight');
      } else if (text.contains('hotel') || text.contains('airbnb') || text.contains('booking confirmation')) {
        subCat = 'Hotels';
        tags.add('hotel');
      } else if (text.contains('train') || text.contains('railway') || text.contains('pnr')) {
        subCat = 'Train Tickets';
        tags.add('transit');
      }

      return ClassificationResult(
        categoryName: 'Travel & Tickets',
        subcategory: subCat,
        tags: tags,
        confidence: 0.93,
      );
    }

    // 6. Documents & IDs
    if (text.contains('passport') || text.contains('driver license') || text.contains('identity card') || text.contains('social security') ||
        text.contains('certificate') || text.contains('agreement') || text.contains('confidential') || text.contains('contract') ||
        text.contains('aadhaar') || text.contains('pan card') || name.contains('passport') || name.contains('id') || name.contains('doc') ||
        desc.contains('document') || desc.contains('id card')) {
      final tags = ['document', 'official'];
      String subCat = 'Documents';

      if (text.contains('passport') || name.contains('passport')) {
        subCat = 'Passports';
        tags.add('passport');
      } else if (text.contains('license') || text.contains('id card') || text.contains('national id') || text.contains('aadhaar') || text.contains('pan card')) {
        subCat = 'IDs';
        tags.add('id');
      } else if (text.contains('certificate') || text.contains('degree')) {
        subCat = 'Certificates';
        tags.add('certificate');
      }

      return ClassificationResult(
        categoryName: 'Documents & IDs',
        subcategory: subCat,
        tags: tags,
        confidence: 0.90,
      );
    }

    // 7. Shopping & Wishlist
    if (app.contains('amazon') || app.contains('flipkart') || app.contains('ebay') || app.contains('myntra') ||
        text.contains('add to cart') || text.contains('wishlist') || text.contains('in stock') || text.contains('buy now') ||
        text.contains('discount') || text.contains('coupon code')) {
      return const ClassificationResult(
        categoryName: 'Shopping & Wishlist',
        subcategory: 'Wishlist',
        tags: ['shopping', 'wishlist'],
        confidence: 0.88,
      );
    }

    // 8. Memes & Humor
    if (app.contains('reddit') || app.contains('9gag') || app.contains('tiktok') ||
        name.contains('meme') || text.contains('meme') || text.contains('funny') || text.contains('lol')) {
      return const ClassificationResult(
        categoryName: 'Memes & Humor',
        subcategory: 'Memes',
        tags: ['meme', 'humor'],
        confidence: 0.89,
      );
    }

    // 9. Notes & Knowledge (Default for browser snapshots / articles)
    if (app.contains('chrome') || app.contains('safari') || app.contains('browser') || app.contains('medium') ||
        app.contains('wikipedia') || text.contains('article') || text.contains('summary') || text.contains('chapter') ||
        name.contains('note')) {
      return const ClassificationResult(
        categoryName: 'Notes & Knowledge',
        subcategory: 'Notes',
        tags: ['notes', 'reference'],
        confidence: 0.85,
      );
    }

    // Default Fallback
    return const ClassificationResult(
      categoryName: 'Notes & Knowledge',
      subcategory: 'General',
      tags: ['snapshot'],
      confidence: 0.75,
    );
  }

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
