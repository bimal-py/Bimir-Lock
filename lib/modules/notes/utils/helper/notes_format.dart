/// Formats note timestamps as relative labels for cards and detail headers,
/// e.g. "Today, 2:00 PM", "Yesterday, 9:15 AM", "3 days ago, 6:40 PM" or
/// "26 Jan 2025, 12:30 AM".
class NotesFormat {
  NotesFormat._();

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String relativeLabel(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    final days = today.difference(that).inDays;
    final time = _time(date);
    if (days == 0) return 'Today, $time';
    if (days == 1) return 'Yesterday, $time';
    if (days > 1 && days < 7) return '$days days ago, $time';
    return '${_date(date)}, $time';
  }

  static String _time(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  static String _date(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';
}
