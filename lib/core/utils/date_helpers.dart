import 'package:intl/intl.dart';

class DateHelpers {
  static final DateFormat _displayFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _shortFormat = DateFormat('dd/MM');
  static final DateFormat _dayFormat = DateFormat('EEEE');
  static final DateFormat _monthFormat = DateFormat('MMMM yyyy');

  /// Format as DD/MM/YYYY
  static String formatDate(DateTime date) {
    return _displayFormat.format(date);
  }

  /// Format as DD/MM/YYYY
  static String formatDisplay(DateTime date) {
    return _displayFormat.format(date);
  }

  /// Format as DD/MM
  static String formatShort(DateTime date) {
    return _shortFormat.format(date);
  }

  /// Format as day name e.g. "Monday"
  static String formatDay(DateTime date) {
    return _dayFormat.format(date);
  }

  /// Format as "April 2026"
  static String formatMonth(DateTime date) {
    return _monthFormat.format(date);
  }

  static DateTime startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static DateTime endOfWeek(DateTime date) {
    return date.add(Duration(days: 7 - date.weekday));
  }

  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  static int weekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final days = date.difference(startOfYear).inDays;
    return ((days + startOfYear.weekday) / 7).ceil();
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  static List<DateTime> getWeekDays(DateTime weekStart) {
    return List.generate(7, (i) => weekStart.add(Duration(days: i)));
  }
}
