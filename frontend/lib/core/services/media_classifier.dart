import '../constants/media_scanner_constants.dart';

class ClassificationResult {
  final String categoryName;
  final String subcategory;
  final List<String> folderPath;
  final List<String> tags;
  final double confidence;

  const ClassificationResult({
    required this.categoryName,
    required this.subcategory,
    this.folderPath = const [],
    required this.tags,
    required this.confidence,
  });

  /// The root folder name
  String get rootFolder => folderPath.isNotEmpty ? folderPath.first : categoryName;

  /// The leaf folder name
  String get leafFolder => folderPath.isNotEmpty ? folderPath.last : (subcategory.isNotEmpty ? subcategory : categoryName);
}

/// Pure classifier for images and videos across Android and iOS
class MediaClassifier {
  const MediaClassifier();

  /// Comprehensive classification of a screenshot into dynamic Folder Hierarchy, Category, Subcategory, and Tags
  ClassificationResult classifyMediaItem({
    String? fileName,
    String? filePath,
    String? ocrText,
    String? sourceApp,
    String? visionDescription,
  }) {
    final rawText = (ocrText ?? '').trim();
    final text = rawText.toLowerCase();
    final name = (fileName ?? '').toLowerCase();
    final path = (filePath ?? '').toLowerCase();
    final app = (sourceApp ?? inferSourceApp(path.isNotEmpty ? path : name) ?? '').toLowerCase();
    final desc = (visionDescription ?? '').toLowerCase();

    // ==================== 1. PROJECTS / PAYROLL / WORK ====================
    // e.g. "WhatsApp payroll screenshot -> Projects -> NHDC -> Payroll"
    final isPayroll = text.contains('payroll') || text.contains('payslip') || text.contains('salary slip') ||
        text.contains('net salary') || text.contains('gross salary') || text.contains('earnings & deductions') ||
        text.contains('pf contribution') || text.contains('basic pay') || text.contains('salary') ||
        name.contains('payroll') || name.contains('salary') || name.contains('payslip');

    final isProject = text.contains('project') || text.contains('sprint') || text.contains('jira') ||
        text.contains('trello') || text.contains('asana') || text.contains('client requirement') ||
        text.contains('deliverable') || app.contains('jira') || app.contains('asana') || app.contains('slack');

    if (isPayroll || isProject) {
      final tags = ['work', 'project'];
      String entity = '';

      // Try to extract project or organization acronym/name (e.g. NHDC, TCS, Infosys, etc.)
      final orgMatch = RegExp(r'\b(NHDC|TCS|INFOSYS|WIPRO|HCL|GOOGLE|META|AMAZON|MICROSOFT|RELIANCE|TATA|[A-Z]{3,8})\b')
          .firstMatch(rawText);
      if (orgMatch != null && orgMatch.group(0) != 'THE' && orgMatch.group(0) != 'AND' && orgMatch.group(0) != 'FOR') {
        entity = orgMatch.group(0)!;
      } else if (name.contains('nhdc') || text.contains('nhdc')) {
        entity = 'NHDC';
      }

      if (isPayroll) {
        tags.add('payroll');
        tags.add('salary');
        final folderHierarchy = entity.isNotEmpty
            ? ['Projects', entity, 'Payroll']
            : ['Projects', 'Payroll'];

        return ClassificationResult(
          categoryName: 'Projects',
          subcategory: 'Payroll',
          folderPath: folderHierarchy,
          tags: tags,
          confidence: 0.95,
        );
      } else {
        final sub = entity.isNotEmpty ? entity : 'General';
        final folderHierarchy = entity.isNotEmpty
            ? ['Projects', entity]
            : ['Projects', 'Tasks'];

        return ClassificationResult(
          categoryName: 'Projects',
          subcategory: sub,
          folderPath: folderHierarchy,
          tags: tags,
          confidence: 0.90,
        );
      }
    }

    // ==================== 2. SHOPPING & E-COMMERCE ====================
    // e.g. "Amazon shoes screenshot -> Shopping -> Shoes"
    final isShoppingApp = app.contains('amazon') || app.contains('flipkart') || app.contains('ebay') ||
        app.contains('myntra') || app.contains('zara') || app.contains('nike') || app.contains('adidas') ||
        app.contains('aliexpress') || app.contains('shein') || app.contains('walmart');

    final isShoppingText = text.contains('add to cart') || text.contains('buy now') || text.contains('in stock') ||
        text.contains('order placed') || text.contains('order total') || text.contains('delivery by') ||
        text.contains('dispatch') || text.contains('wishlist') || text.contains('price drop') ||
        text.contains('free delivery') || text.contains('eligible for free shipping') ||
        name.contains('amazon') || name.contains('shopping') || name.contains('flipkart');

    if (isShoppingApp || isShoppingText) {
      final tags = ['shopping'];
      String subFolder = 'General';

      if (text.contains('shoe') || text.contains('sneaker') || text.contains('running shoe') ||
          text.contains('boot') || text.contains('sandal') || text.contains('crocs') ||
          text.contains('footwear') || name.contains('shoe')) {
        subFolder = 'Shoes';
        tags.add('shoes');
      } else if (text.contains('laptop') || text.contains('phone') || text.contains('headphones') ||
          text.contains('charger') || text.contains('keyboard') || text.contains('monitor') ||
          text.contains('earbuds') || text.contains('processor') || text.contains('specs')) {
        subFolder = 'Electronics';
        tags.add('electronics');
      } else if (text.contains('shirt') || text.contains('t-shirt') || text.contains('jeans') ||
          text.contains('dress') || text.contains('jacket') || text.contains('hoodie') ||
          text.contains('clothing') || text.contains('apparel') || text.contains('size m') || text.contains('size l')) {
        subFolder = 'Clothing';
        tags.add('clothing');
      } else if (text.contains('book') || text.contains('paperback') || text.contains('hardcover')) {
        subFolder = 'Books';
        tags.add('books');
      } else if (isShoppingApp && app.isNotEmpty) {
        subFolder = app[0].toUpperCase() + app.substring(1);
        tags.add(app);
      }

      return ClassificationResult(
        categoryName: 'Shopping',
        subcategory: subFolder,
        folderPath: ['Shopping', subFolder],
        tags: tags,
        confidence: 0.94,
      );
    }

    // ==================== 3. LEARNING & TUTORIALS ====================
    // e.g. "Flutter tutorial screenshot -> Learning -> Flutter"
    final isTutorial = text.contains('tutorial') || text.contains('course') || text.contains('lesson') ||
        text.contains('lecture') || text.contains('how to') || text.contains('documentation') ||
        text.contains('cheat sheet') || text.contains('roadmap') || text.contains('curriculum') ||
        app.contains('udemy') || app.contains('coursera') || app.contains('edx') || app.contains('duolingo') ||
        name.contains('tutorial') || name.contains('course');

    final hasTechLang = text.contains('flutter') || text.contains('dart') || text.contains('react') ||
        text.contains('python') || text.contains('javascript') || text.contains('typescript') ||
        text.contains('kotlin') || text.contains('swift') || text.contains('rust') || text.contains('golang') ||
        text.contains('c#') || text.contains('sql') || text.contains('machine learning') || text.contains('deep learning');

    if (isTutorial || (hasTechLang && (text.contains('widget') || text.contains('learn') || text.contains('guide') || text.contains('beginner')))) {
      final tags = ['learning', 'education'];
      String subFolder = 'Tutorials';

      if (text.contains('flutter') || name.contains('flutter')) {
        subFolder = 'Flutter';
        tags.add('flutter');
      } else if (text.contains('python') || name.contains('python')) {
        subFolder = 'Python';
        tags.add('python');
      } else if (text.contains('react') || name.contains('react')) {
        subFolder = 'React';
        tags.add('react');
      } else if (text.contains('dart') || name.contains('dart')) {
        subFolder = 'Dart';
        tags.add('dart');
      } else if (text.contains('kotlin') || text.contains('android')) {
        subFolder = 'Android';
        tags.add('android');
      } else if (text.contains('swift') || text.contains('ios')) {
        subFolder = 'iOS';
        tags.add('ios');
      } else if (text.contains('machine learning') || text.contains('deep learning') || text.contains('ai')) {
        subFolder = 'AI & ML';
        tags.add('ai');
      }

      return ClassificationResult(
        categoryName: 'Learning',
        subcategory: subFolder,
        folderPath: ['Learning', subFolder],
        tags: tags,
        confidence: 0.93,
      );
    }

    // ==================== 4. TRAVEL & TICKETS ====================
    // e.g. "Flight ticket screenshot -> Travel -> Flights"
    if (text.contains('boarding pass') || text.contains('flight') || text.contains('gate') || text.contains('seat') ||
        text.contains('hotel booking') || text.contains('reservation') || text.contains('train ticket') || text.contains('pnr') ||
        text.contains('check-in') || name.contains('flight') || name.contains('ticket') || name.contains('boarding') ||
        app.contains('airbnb') || app.contains('booking.com') || app.contains('makemytrip') || app.contains('irctc') ||
        desc.contains('ticket') || desc.contains('boarding pass')) {
      final tags = ['travel', 'tickets'];
      String subCat = 'Tickets';

      if (text.contains('boarding pass') || text.contains('flight') || text.contains('gate') || text.contains('airline') || name.contains('flight')) {
        subCat = 'Flights';
        tags.add('flight');
      } else if (text.contains('hotel') || text.contains('airbnb') || text.contains('booking confirmation') || text.contains('resort')) {
        subCat = 'Hotels';
        tags.add('hotel');
      } else if (text.contains('train') || text.contains('railway') || text.contains('pnr') || text.contains('irctc')) {
        subCat = 'Trains';
        tags.add('transit');
      }

      return ClassificationResult(
        categoryName: 'Travel',
        subcategory: subCat,
        folderPath: ['Travel', subCat],
        tags: tags,
        confidence: 0.94,
      );
    }

    // ==================== 5. RECEIPTS & INVOICES ====================
    if (text.contains('invoice') || text.contains('receipt') || text.contains('subtotal') || text.contains('total') ||
        text.contains('tax') || text.contains('amount paid') || text.contains('bill') || text.contains('due date') ||
        text.contains('order #') || text.contains('order id') ||
        name.contains('receipt') || name.contains('invoice') || name.contains('bill') ||
        app.contains('uber eats') || app.contains('doordash') || app.contains('swiggy') || app.contains('zomato') ||
        desc.contains('receipt') || desc.contains('invoice') || desc.contains('bill')) {
      final tags = ['receipt', 'purchase'];
      String subCat = 'Bills';

      if (text.contains('dining') || text.contains('restaurant') || text.contains('food') || text.contains('starbucks') ||
          text.contains('eats') || text.contains('cafe') || app.contains('swiggy') || app.contains('zomato')) {
        subCat = 'Dining';
        tags.add('food');
      } else if (text.contains('grocery') || text.contains('market') || text.contains('walmart') || text.contains('whole foods') || text.contains('instacart')) {
        subCat = 'Groceries';
        tags.add('groceries');
      } else if (text.contains('electric') || text.contains('water') || text.contains('internet') || text.contains('utility')) {
        subCat = 'Utilities';
        tags.add('bills');
      }

      return ClassificationResult(
        categoryName: 'Receipts',
        subcategory: subCat,
        folderPath: ['Receipts', subCat],
        tags: tags,
        confidence: 0.94,
      );
    }

    // ==================== 6. FINANCE & BANKING ====================
    if (text.contains('account balance') || text.contains('available balance') || text.contains('bank statement') ||
        text.contains('bank account') || text.contains('transfer') || text.contains('upi') || text.contains('crypto') ||
        text.contains('bitcoin') || text.contains('ethereum') || text.contains('portfolio') || text.contains('stocks') ||
        text.contains('nasdaq') || text.contains('credited') || text.contains('debited') || text.contains('paid to') ||
        app.contains('bank') || app.contains('finance') || app.contains('crypto') || app.contains('wallet') ||
        app.contains('gpay') || app.contains('phonepe') || app.contains('paytm') || app.contains('binance') ||
        name.contains('upi') || name.contains('bank') || name.contains('payment')) {
      final tags = ['finance', 'money'];
      String subCat = 'Bank Statements';

      if (text.contains('crypto') || text.contains('btc') || text.contains('eth') || text.contains('binance') || text.contains('coinbase') || app.contains('crypto') || app.contains('binance')) {
        subCat = 'Crypto';
        tags.add('crypto');
      } else if (text.contains('stock') || text.contains('shares') || text.contains('nasdaq') || text.contains('dividend') || text.contains('zerodha') || text.contains('groww')) {
        subCat = 'Investments';
        tags.add('investing');
      } else if (text.contains('upi') || text.contains('sent to') || text.contains('transferred') || text.contains('gpay') || text.contains('phonepe') || text.contains('paytm')) {
        subCat = 'UPI & Transfers';
        tags.add('transfers');
      }

      return ClassificationResult(
        categoryName: 'Finance',
        subcategory: subCat,
        folderPath: ['Finance', subCat],
        tags: tags,
        confidence: 0.92,
      );
    }

    // ==================== 7. CODE & TECH ====================
    if (text.contains('function') || text.contains('public class') || text.contains('import ') || text.contains('exception') ||
        text.contains('stack trace') || text.contains('github') || text.contains('git commit') || text.contains('docker') ||
        text.contains('terminal') || text.contains('bash') || text.contains('powershell') || app.contains('github') ||
        app.contains('vscode') || app.contains('terminal') || name.contains('code') || name.contains('terminal')) {
      final tags = ['developer', 'tech'];
      String subCat = 'Snippets';

      if (text.contains('dart') || text.contains('flutter') || path.contains('.dart') || name.contains('.dart')) {
        subCat = 'Dart';
        tags.addAll(['dart', 'flutter']);
      } else if (text.contains('python')) {
        subCat = 'Python';
        tags.add('python');
      } else if (text.contains('c#') || text.contains('csharp') || text.contains('.net')) {
        subCat = 'C#';
        tags.add('csharp');
      } else if (text.contains('javascript') || text.contains('typescript') || text.contains('node')) {
        subCat = 'JavaScript';
        tags.add('js');
      } else if (text.contains('exception') || text.contains('error') || text.contains('stack trace') || text.contains('fatal')) {
        subCat = 'Error Logs';
        tags.add('debug');
      } else if (text.contains('terminal') || text.contains('bash') || text.contains('zsh') || text.contains('sudo')) {
        subCat = 'Terminal';
        tags.add('cli');
      }

      return ClassificationResult(
        categoryName: 'Code & Tech',
        subcategory: subCat,
        folderPath: ['Code & Tech', subCat],
        tags: tags,
        confidence: 0.94,
      );
    }

    // ==================== 8. SOCIAL & CHAT ====================
    if (app.contains('whatsapp') || app.contains('telegram') || app.contains('instagram') || app.contains('twitter') ||
        app.contains('x') || app.contains('discord') || app.contains('slack') || app.contains('messenger') ||
        path.contains('whatsapp') || path.contains('telegram') || name.contains('whatsapp') || name.contains('telegram') ||
        text.contains('online') || text.contains('typing...') || text.contains('retweet') || text.contains('direct message')) {
      final tags = ['social', 'chat'];
      String subCat = 'Chat';

      if (app.contains('whatsapp') || path.contains('whatsapp') || name.contains('whatsapp')) {
        subCat = 'WhatsApp';
        tags.add('whatsapp');
      } else if (app.contains('telegram') || path.contains('telegram') || name.contains('telegram')) {
        subCat = 'Telegram';
        tags.add('telegram');
      } else if (app.contains('twitter') || app.contains('x') || text.contains('retweet') || text.contains('tweet')) {
        subCat = 'Twitter';
        tags.add('twitter');
      } else if (app.contains('instagram') || text.contains('story') || text.contains('reels')) {
        subCat = 'Instagram';
        tags.add('instagram');
      }

      return ClassificationResult(
        categoryName: 'Social',
        subcategory: subCat,
        folderPath: ['Social', subCat],
        tags: tags,
        confidence: 0.93,
      );
    }

    // ==================== 9. DOCUMENTS & IDS ====================
    if (text.contains('passport') || text.contains('driver license') || text.contains('identity card') ||
        text.contains('certificate') || text.contains('agreement') || text.contains('contract') ||
        text.contains('aadhaar') || text.contains('pan card') || name.contains('passport') || name.contains('id') ||
        desc.contains('document') || desc.contains('id card')) {
      final tags = ['document', 'official'];
      String subCat = 'Documents';

      if (text.contains('passport') || name.contains('passport')) {
        subCat = 'Passports';
        tags.add('passport');
      } else if (text.contains('license') || text.contains('id card') || text.contains('aadhaar') || text.contains('pan card')) {
        subCat = 'IDs';
        tags.add('id');
      } else if (text.contains('certificate') || text.contains('degree')) {
        subCat = 'Certificates';
        tags.add('certificate');
      }

      return ClassificationResult(
        categoryName: 'Documents',
        subcategory: subCat,
        folderPath: ['Documents', subCat],
        tags: tags,
        confidence: 0.92,
      );
    }

    // ==================== 10. MEMES & HUMOR ====================
    if (app.contains('reddit') || app.contains('9gag') || app.contains('tiktok') ||
        name.contains('meme') || text.contains('meme') || text.contains('funny') || text.contains('lol')) {
      return const ClassificationResult(
        categoryName: 'Memes',
        subcategory: 'Humor',
        folderPath: ['Memes', 'Humor'],
        tags: ['meme', 'humor'],
        confidence: 0.89,
      );
    }

    // ==================== 11. DYNAMIC CONTENT FALLBACK ====================
    // Do NOT default to "Notes & Knowledge".
    // If OCR text contains lines, pick a clean topic or default to Unsorted
    if (rawText.isNotEmpty) {
      final lines = rawText.split('\n')
          .map((l) => l.trim())
          .where((l) => l.length >= 3 && l.length <= 25 && !l.contains('http'))
          .toList();

      if (lines.isNotEmpty) {
        // Take the first clean title line
        final candidate = lines.first.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();
        final words = candidate.split(' ').where((w) => w.isNotEmpty).take(3).toList();
        if (words.isNotEmpty) {
          final cleanTopic = words.map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
          return ClassificationResult(
            categoryName: 'General',
            subcategory: cleanTopic,
            folderPath: ['General', cleanTopic],
            tags: ['general'],
            confidence: 0.70,
          );
        }
      }
    }

    // Default Fallback is Unsorted, NEVER Notes & Knowledge
    return const ClassificationResult(
      categoryName: 'Unsorted',
      subcategory: 'General',
      folderPath: ['Unsorted'],
      tags: ['unsorted'],
      confidence: 0.50,
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
