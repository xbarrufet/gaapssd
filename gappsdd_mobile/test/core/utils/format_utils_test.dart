import 'package:flutter_test/flutter_test.dart';
import 'package:gappsdd/core/utils/format_utils.dart';

void main() {
  group('monthLabel', () {
    test('returns correct 3-letter labels for all months', () {
      expect(monthLabel(1), 'JAN');
      expect(monthLabel(2), 'FEB');
      expect(monthLabel(3), 'MAR');
      expect(monthLabel(4), 'APR');
      expect(monthLabel(5), 'MAY');
      expect(monthLabel(6), 'JUN');
      expect(monthLabel(7), 'JUL');
      expect(monthLabel(8), 'AUG');
      expect(monthLabel(9), 'SEP');
      expect(monthLabel(10), 'OCT');
      expect(monthLabel(11), 'NOV');
      expect(monthLabel(12), 'DEC');
    });

    test('clamps out-of-range values', () {
      expect(monthLabel(0), 'JAN');
      expect(monthLabel(-1), 'JAN');
      expect(monthLabel(13), 'DEC');
    });
  });

  group('parseVisitDate', () {
    test('parses valid visit ID format', () {
      final date = parseVisitDate('visit-2026-04-08');
      expect(date, DateTime(2026, 4, 8));
    });

    test('parses ID with extra segments', () {
      final date = parseVisitDate('visit-2026-04-08-extra-segments');
      expect(date, DateTime(2026, 4, 8));
    });

    test('returns null for too few segments', () {
      expect(parseVisitDate('visit-2026-04'), isNull);
      expect(parseVisitDate('visit-2026'), isNull);
      expect(parseVisitDate('visit'), isNull);
    });

    test('returns null for non-numeric segments', () {
      expect(parseVisitDate('visit-abc-04-08'), isNull);
      expect(parseVisitDate('visit-2026-xx-08'), isNull);
    });
  });

  group('isInCurrentWeek', () {
    test('today is in current week', () {
      expect(isInCurrentWeek(DateTime.now()), isTrue);
    });

    test('30 days ago is not in current week', () {
      final past = DateTime.now().subtract(const Duration(days: 30));
      expect(isInCurrentWeek(past), isFalse);
    });

    test('30 days from now is not in current week', () {
      final future = DateTime.now().add(const Duration(days: 30));
      expect(isInCurrentWeek(future), isFalse);
    });
  });

  group('formatHours', () {
    test('formats minutes as decimal hours', () {
      expect(formatHours(0), '0.0h');
      expect(formatHours(30), '0.5h');
      expect(formatHours(60), '1.0h');
      expect(formatHours(90), '1.5h');
      expect(formatHours(150), '2.5h');
    });
  });

  group('formatVisitDuration', () {
    test('formats sub-hour durations as minutes only', () {
      expect(formatVisitDuration(0), '0m');
      expect(formatVisitDuration(5), '5m');
      expect(formatVisitDuration(45), '45m');
    });

    test('formats hour+ durations as hours and minutes', () {
      expect(formatVisitDuration(60), '1h 00m');
      expect(formatVisitDuration(98), '1h 38m');
      expect(formatVisitDuration(125), '2h 05m');
      expect(formatVisitDuration(180), '3h 00m');
    });
  });
}
