import 'package:intl/intl.dart';

class AppDateUtils {
  static String todayString() => formatDate(DateTime.now());

  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String displayDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return DateFormat('M月d日').format(date);
  }

  static String displayFullDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return DateFormat('yyyy年M月d日').format(date);
  }

  static String monthTitle(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return '未知月份';
    return DateFormat('yyyy年M月').format(date);
  }

  static String monthKey(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return 'unknown';
    return DateFormat('yyyy-MM').format(date);
  }
}
