abstract final class AppDateUtils {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Parses a raw ISO date string and returns a human-readable form
  /// such as "15 Jan 1990". Returns "—" when the value is null or unparseable.
  static String formatDob(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }

  /// Formats a [DateTime] to "YYYY-MM-DD" for server storage.
  static String toServerDate(DateTime date) =>
      '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
