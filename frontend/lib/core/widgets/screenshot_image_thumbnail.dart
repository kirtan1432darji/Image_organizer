import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../constants/color_constants.dart';
import '../../models/screenshot_model.dart';

/// Global LRU memory cache for decoded thumbnail byte buffers (bounded to prevent memory leaks)
class _ThumbnailCache {
  static final Map<String, Uint8List> _cache = {};
  static final List<String> _keys = [];
  static const int _maxEntries = 200;

  static Uint8List? get(String key) => _cache[key];

  static void put(String key, Uint8List data) {
    if (_cache.containsKey(key)) {
      _cache[key] = data;
      return;
    }
    if (_keys.length >= _maxEntries) {
      final oldest = _keys.removeAt(0);
      _cache.remove(oldest);
    }
    _keys.add(key);
    _cache[key] = data;
  }
}

class ScreenshotImageThumbnail extends StatefulWidget {
  final ScreenshotModel screenshot;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool isHero;
  final bool isOriginal;

  const ScreenshotImageThumbnail({
    super.key,
    required this.screenshot,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.isHero = false,
    this.isOriginal = false,
  });

  @override
  State<ScreenshotImageThumbnail> createState() => _ScreenshotImageThumbnailState();
}

class _ScreenshotImageThumbnailState extends State<ScreenshotImageThumbnail> {
  Uint8List? _imageBytes;
  File? _fallbackFile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant ScreenshotImageThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.screenshot.deviceAssetId != widget.screenshot.deviceAssetId ||
        oldWidget.screenshot.filePath != widget.screenshot.filePath ||
        oldWidget.isOriginal != widget.isOriginal) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!mounted) return;

    final assetId = widget.screenshot.deviceAssetId;
    final filePath = widget.screenshot.filePath;

    // 1. Check in-memory cache if not full-size original
    if (!widget.isOriginal && assetId.isNotEmpty) {
      final cached = _ThumbnailCache.get(assetId);
      if (cached != null) {
        setState(() {
          _imageBytes = cached;
          _isLoading = false;
          _errorMessage = null;
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 2. Resolve via PhotoManager / MediaStore (Primary)
    if (assetId.isNotEmpty) {
      try {
        final AssetEntity? entity = await AssetEntity.fromId(assetId);
        if (entity != null) {
          Uint8List? bytes;
          if (widget.isOriginal) {
            // For detail screen zoom
            bytes = await entity.originBytes;
            if (bytes == null) {
              final f = await entity.file;
              if (f != null && f.existsSync()) {
                bytes = await f.readAsBytes();
              }
            }
            bytes ??= await entity.thumbnailDataWithSize(const ThumbnailSize(1080, 2400));
          } else {
            // For grid/carousel thumbnail
            bytes = await entity.thumbnailDataWithSize(const ThumbnailSize(400, 400));
            if (bytes != null) {
              _ThumbnailCache.put(assetId, bytes);
            }
          }

          if (bytes != null && mounted) {
            setState(() {
              _imageBytes = bytes;
              _isLoading = false;
              _errorMessage = null;
            });
            return;
          } else {
            debugPrint('[ScreenshotThumbnail] Failed to extract thumbnail data for asset ID: $assetId');
          }
        } else {
          debugPrint('[ScreenshotThumbnail] AssetEntity not found for asset ID: $assetId');
        }
      } catch (e) {
        debugPrint('[ScreenshotThumbnail] Exception reading PhotoManager asset $assetId: $e');
      }
    }

    // 3. Fallback to direct File path if exists
    if (filePath.isNotEmpty && !filePath.startsWith('assets/')) {
      try {
        final f = File(filePath);
        if (f.existsSync()) {
          if (mounted) {
            setState(() {
              _fallbackFile = f;
              _isLoading = false;
              _errorMessage = null;
            });
            return;
          }
        } else {
          debugPrint('[ScreenshotThumbnail] File path does not exist on disk: $filePath');
        }
      } catch (e) {
        debugPrint('[ScreenshotThumbnail] Exception reading file $filePath: $e');
      }
    }

    // 4. Failed to resolve
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Media unavailable on device';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = _buildLoading(context);
    } else if (_imageBytes != null) {
      content = Image.memory(
        _imageBytes!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        filterQuality: FilterQuality.medium,
        errorBuilder: (ctx, err, stack) {
          debugPrint('[ScreenshotThumbnail] Image.memory decoding error: $err');
          return _buildFallback(context, 'Decoding error');
        },
      );
    } else if (_fallbackFile != null) {
      content = Image.file(
        _fallbackFile!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (ctx, err, stack) {
          debugPrint('[ScreenshotThumbnail] Image.file error: $err');
          return _buildFallback(context, 'File error');
        },
      );
    } else {
      content = _buildFallback(context, _errorMessage ?? 'Unavailable');
    }

    if (widget.borderRadius != null) {
      content = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }

    if (widget.isHero) {
      return Hero(
        tag: 'screenshot_img_${widget.screenshot.id}',
        child: content,
      );
    }

    return content;
  }

  Widget _buildLoading(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: ColorConstants.primary.withValues(alpha: 0.06),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: ColorConstants.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context, String reason) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: widget.width,
      height: widget.height,
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: widget.isOriginal ? 48 : 28,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          if (widget.isOriginal) ...[
            const SizedBox(height: 6),
            Text(
              reason,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
