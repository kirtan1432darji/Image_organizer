import 'package:flutter/material.dart';
import '../constants/color_constants.dart';

class ConfidenceBadge extends StatelessWidget {
  final double confidence;
  final bool showLabel;
  final double size;

  const ConfidenceBadge({
    super.key,
    required this.confidence,
    this.showLabel = true,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    final color = ColorConstants.getConfidenceColor(confidence);
    final percent = (confidence * 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size * 0.6,
            height: size * 0.6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$percent% AI Match',
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
