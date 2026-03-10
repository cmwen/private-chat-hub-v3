import 'package:intl/intl.dart';

/// Utilities for date grouping and formatting in conversations.
class ConversationDateUtils {
  const ConversationDateUtils._();

  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateFormat = DateFormat('MMM d');
  static final DateFormat _yearFormat = DateFormat('MMM d, y');

  /// Returns a label for how to display a message timestamp.
  static String formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) return _timeFormat.format(dateTime);
    if (diff == 1) return 'Yesterday';
    if (dateTime.year == now.year) return _dateFormat.format(dateTime);
    return _yearFormat.format(dateTime);
  }

  /// Groups conversations into named buckets.
  /// Returns keys in order: Today, Yesterday, Previous 7 Days, Older.
  static Map<String, List<T>> groupByDate<T>(
    List<T> items,
    DateTime Function(T) getDate,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final groups = <String, List<T>>{
      'Today': [],
      'Yesterday': [],
      'Previous 7 Days': [],
      'Older': [],
    };

    for (final item in items) {
      final date = getDate(item);
      final itemDay = DateTime(date.year, date.month, date.day);
      final diff = today.difference(itemDay).inDays;

      if (diff == 0) {
        groups['Today']!.add(item);
      } else if (diff == 1) {
        groups['Yesterday']!.add(item);
      } else if (diff <= 7) {
        groups['Previous 7 Days']!.add(item);
      } else {
        groups['Older']!.add(item);
      }
    }

    // Remove empty groups but maintain insertion order.
    groups.removeWhere((_, v) => v.isEmpty);
    return groups;
  }
}
