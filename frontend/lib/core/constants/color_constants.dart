import 'package:flutter/material.dart';

class ColorConstants {
  ColorConstants._();

  // Brand Palette - Premium Deep Indigo, Electric Violet & Neon Teal
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);

  static const Color secondary = Color(0xFF06B6D4); // Cyan / Teal
  static const Color secondaryDark = Color(0xFF0891B2);
  static const Color secondaryLight = Color(0xFF22D3EE);

  static const Color tertiary = Color(0xFFEC4899); // Pink / Fuchsia
  static const Color accent = Color(0xFF8B5CF6); // Violet

  // Neutral Colors - Light Theme
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color dividerLight = Color(0xFFF1F5F9);

  // Neutral Colors - Dark Theme
  static const Color backgroundDark = Color(0xFF0B0F19);
  static const Color surfaceDark = Color(0xFF131B2E);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);
  static const Color borderDark = Color(0xFF334155);
  static const Color dividerDark = Color(0xFF1E293B);

  // Category Accent Colors
  static const Color categoryFinance = Color(0xFF10B981); // Emerald
  static const Color categorySocial = Color(0xFF3B82F6); // Blue
  static const Color categoryWork = Color(0xFF8B5CF6); // Purple
  static const Color categoryCode = Color(0xFFF59E0B); // Amber
  static const Color categoryShopping = Color(0xFFEC4899); // Pink
  static const Color categoryTravel = Color(0xFF14B8A6); // Teal
  static const Color categoryMemes = Color(0xFFF97316); // Orange
  static const Color categoryUnsorted = Color(0xFF64748B); // Slate

  // Status & Confidence Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static Color getConfidenceColor(double confidence) {
    if (confidence >= 0.85) return success;
    if (confidence >= 0.65) return warning;
    return error;
  }
}
