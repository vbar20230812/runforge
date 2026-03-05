import 'package:intl/intl.dart';

class DateHelpers {
  static final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat displayFormat = DateFormat('MMM d, yyyy');
  static final DateFormat dayFormat = DateFormat('EEEE');
  static final DateFormat monthFormat = DateFormat('MMMM yyyy');

  static String formatDate(DateTime date) {
    return dateFormat.format(date);
  }

  static String formatDisplay(DateTime date) {
    return displayFormat.format(date);
  }

  static String formatDay(DateTime date) {
    return dayFormat.format(date);
  }

  static String formatMonth(DateTime date) {
    return monthFormat.format(date);
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
