const _monthsGenitive = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

const _weekdaysShort = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

DateTime startOfWeek(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return DateTime(day.year, day.month, day.day - (day.weekday - 1));
}

DateTime addDays(DateTime date, int days) {
  return DateTime(date.year, date.month, date.day + days);
}

DateTime dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool isCurrentWeek(DateTime weekStart) {
  return isSameDay(startOfWeek(weekStart), startOfWeek(DateTime.now()));
}

int currentDayIndex() {
  return DateTime.now().weekday - 1;
}

String dateKey(DateTime date) {
  final day = dateOnly(date);
  final month = day.month.toString().padLeft(2, '0');
  final dayNumber = day.day.toString().padLeft(2, '0');
  return '${day.year}-$month-$dayNumber';
}

String formatWeekdayShort(DateTime date) {
  return _weekdaysShort[date.weekday - 1];
}

String formatWeekRange(DateTime weekStart) {
  final start = startOfWeek(weekStart);
  final end = addDays(start, 6);
  final sameMonth = start.month == end.month && start.year == end.year;
  final left = sameMonth
      ? '${start.day}'
      : '${start.day} ${_monthsGenitive[start.month - 1]}';
  final right = '${end.day} ${_monthsGenitive[end.month - 1]}';
  final separator = sameMonth ? '–' : ' — ';
  return '$left$separator$right ${end.year}';
}

String formatDayMonth(DateTime date) {
  return '${date.day} ${_monthsGenitive[date.month - 1]}';
}

int seedForWeek(DateTime weekStart) {
  final start = startOfWeek(weekStart);
  final days = start.difference(DateTime(2024, 1, 1)).inDays;
  return days + 1;
}
