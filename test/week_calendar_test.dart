import 'package:flutter_test/flutter_test.dart';
import 'package:norma/core/planner/week_calendar.dart';

void main() {
  test('startOfWeek всегда возвращает понедельник', () {
    expect(startOfWeek(DateTime(2026, 11, 9)), DateTime(2026, 11, 9));
    expect(startOfWeek(DateTime(2026, 11, 15)), DateTime(2026, 11, 9));
    expect(startOfWeek(DateTime(2026, 11, 12)), DateTime(2026, 11, 9));
  });

  test('formatWeekRange форматирует неделю внутри месяца', () {
    expect(formatWeekRange(DateTime(2026, 11, 9)), '9–15 ноября 2026');
  });

  test('formatWeekRange форматирует неделю на стыке месяцев', () {
    expect(
      formatWeekRange(DateTime(2026, 11, 30)),
      '30 ноября — 6 декабря 2026',
    );
  });

  test('seedForWeek стабилен для одной недели', () {
    expect(
      seedForWeek(DateTime(2026, 11, 9)),
      seedForWeek(DateTime(2026, 11, 15)),
    );
    expect(
      seedForWeek(DateTime(2026, 11, 9)),
      isNot(seedForWeek(DateTime(2026, 11, 16))),
    );
  });

  test('dateKey и day index', () {
    expect(dateKey(DateTime(2026, 1, 5)), '2026-01-05');
    expect(formatWeekdayShort(DateTime(2026, 11, 12)), 'Чт');
    expect(formatDayMonth(DateTime(2026, 11, 12)), '12 ноября');
  });
}
