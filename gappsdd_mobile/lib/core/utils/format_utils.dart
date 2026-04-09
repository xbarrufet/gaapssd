/// Converts a 1-based [month] number to a 3-letter uppercase label
/// (e.g. 1 -> "JAN", 12 -> "DEC").
String monthLabel(int month) {
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  return months[(month - 1).clamp(0, 11)];
}

/// Parses a [DateTime] from a visit ID that follows the format
/// `"xxx-YYYY-MM-DD-xxx"` (e.g. `"visit-2026-04-08"`).
///
/// Returns `null` if the ID cannot be parsed.
DateTime? parseVisitDate(String visitId) {
  final parts = visitId.split('-');
  if (parts.length < 4) {
    return null;
  }

  final year = int.tryParse(parts[1]);
  final month = int.tryParse(parts[2]);
  final day = int.tryParse(parts[3]);

  if (year == null || month == null || day == null) {
    return null;
  }

  return DateTime(year, month, day);
}

/// Returns `true` if [date] falls within the current ISO week
/// (Monday through Sunday).
bool isInCurrentWeek(DateTime date) {
  final now = DateTime.now();
  final startOfWeek = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - DateTime.monday));
  final endOfWeek = startOfWeek.add(const Duration(days: 7));

  return !date.isBefore(startOfWeek) && date.isBefore(endOfWeek);
}

/// Formats a duration given in [minutes] as a decimal-hours string
/// (e.g. 90 -> "1.5h").
String formatHours(int minutes) {
  final hours = minutes / 60;
  return '${hours.toStringAsFixed(1)}h';
}

/// Formats a duration given in [minutes] in a human-friendly way:
/// - "Xh XXm" when >= 60 minutes (e.g. 98 -> "1h 38m")
/// - "XXm" when < 60 minutes (e.g. 45 -> "45m")
String formatVisitDuration(int minutes) {
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours == 0) {
    return '${mins}m';
  }
  return '${hours}h ${mins.toString().padLeft(2, '0')}m';
}
