import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/widgets/modern_card.dart';

class OcrTextView extends StatefulWidget {
  final String? ocrText;
  final String ocrStatus;
  final VoidCallback onReRunOcr;

  const OcrTextView({
    super.key,
    required this.ocrText,
    required this.ocrStatus,
    required this.onReRunOcr,
  });

  @override
  State<OcrTextView> createState() => _OcrTextViewState();
}

class _OcrTextViewState extends State<OcrTextView> {
  bool _isCopied = false;

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _isCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OCR text copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText = widget.ocrText != null && widget.ocrText!.trim().isNotEmpty;

    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorConstants.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.document_scanner_outlined,
                      color: ColorConstants.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Extracted OCR Text',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (hasText)
                TextButton.icon(
                  onPressed: () => _copyToClipboard(widget.ocrText!),
                  icon: Icon(
                    _isCopied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 16,
                    color: _isCopied ? ColorConstants.success : ColorConstants.primary,
                  ),
                  label: Text(
                    _isCopied ? 'Copied' : 'Copy',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isCopied ? ColorConstants.success : ColorConstants.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasText)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.4),
                ),
              ),
              child: SelectableText(
                widget.ocrText!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(
                    Icons.text_fields_rounded,
                    size: 32,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No text detected in this screenshot.',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: widget.onReRunOcr,
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: const Text('Re-run OCR', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
