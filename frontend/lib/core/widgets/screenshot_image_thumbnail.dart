import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../constants/color_constants.dart';
import '../../models/screenshot_model.dart';

class ScreenshotImageThumbnail extends StatelessWidget {
  final ScreenshotModel screenshot;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool isHero;

  const ScreenshotImageThumbnail({
    super.key,
    required this.screenshot,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = _buildImageContent(context);

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    if (isHero) {
      return Hero(
        tag: 'screenshot_img_${screenshot.id}',
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildImageContent(BuildContext context) {
    // 1. Primary: PhotoManager AssetEntity Thumbnail (Optimized memory)
    if (!kIsWeb && screenshot.deviceAssetId.isNotEmpty) {
      return FutureBuilder<AssetEntity?>(
        future: AssetEntity.fromId(screenshot.deviceAssetId),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return FutureBuilder<Uint8List?>(
              future: snapshot.data!.thumbnailDataWithSize(const ThumbnailSize(350, 350)),
              builder: (context, thumbSnap) {
                if (thumbSnap.hasData && thumbSnap.data != null) {
                  return Image.memory(
                    thumbSnap.data!,
                    fit: fit,
                    width: width,
                    height: height,
                    errorBuilder: (_, __, ___) => _buildFileFallback(context),
                  );
                }
                return _buildPlaceholder(context);
              },
            );
          }
          return _buildFileFallback(context);
        },
      );
    }

    return _buildFileFallback(context);
  }

  Widget _buildFileFallback(BuildContext context) {
    // 2. Secondary fallback: Local File on device if exists
    if (!kIsWeb && screenshot.filePath.isNotEmpty && !screenshot.filePath.startsWith('assets/')) {
      final file = File(screenshot.filePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => _buildNetworkOrPlaceholder(context),
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) return child;
            return _buildPlaceholder(context);
          },
        );
      }
    }

    return _buildNetworkOrPlaceholder(context);
  }

  Widget _buildNetworkOrPlaceholder(BuildContext context) {
    // 3. Network URL fallback
    if (screenshot.filePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: screenshot.filePath,
        fit: fit,
        width: width,
        height: height,
        placeholder: (_, __) => _buildPlaceholder(context),
        errorWidget: (_, __, ___) => _buildFallback(context),
      );
    }

    // 4. Fallback Placeholder Icon
    return _buildFallback(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: ColorConstants.primary.withValues(alpha: 0.08),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: ColorConstants.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: ColorConstants.primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 32,
          color: ColorConstants.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
