//работа с датами
class DateHelper {
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  static String formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}