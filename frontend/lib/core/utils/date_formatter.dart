import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _fullFormat = DateFormat('MMM dd, yyyy • hh:mm a');
  static final DateFormat _shortFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _timeOnlyFormat = DateFormat('hh:mm a');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');

  static String formatFull(DateTime dateTime) => _fullFormat.format(dateTime);
  static String formatShort(DateTime dateTime) => _shortFormat.format(dateTime);
  static String formatTime(DateTime dateTime) => _timeOnlyFormat.format(dateTime);
  static String formatMonthYear(DateTime dateTime) => _monthYearFormat.format(dateTime);

  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else {
        return '${difference.inHours}h ago';
      }
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      return _shortFormat.format(dateTime);
    }
  }
}
