class LogicDayInfo {
  final DateTime now;
  final DateTime logicDay;
  final DateTime previousLogicDay;
  final DateTime nextLogicDay;
  final DateTime nextRollOverTime;

  const LogicDayInfo({
    required this.now,
    required this.logicDay,
    required this.previousLogicDay,
    required this.nextLogicDay,
    required this.nextRollOverTime,
  });
}

class LogicDayService {
  LogicDayService._();

  static LogicDayInfo calculate({
    required DateTime now,
    required String dayStartTime,
  }) {
    final parts = dayStartTime.split(':');
    final startHour = int.parse(parts[0]);
    final startMinute = int.parse(parts[1]);

    final todayStart = DateTime(
      now.year,
      now.month,
      now.day,
      startHour,
      startMinute,
    );

    late DateTime logicDay;
    late DateTime nextRollOverTime;

    if (now.isBefore(todayStart)) {
      logicDay = DateTime(now.year, now.month, now.day).subtract(
        const Duration(days: 1),
      );
      nextRollOverTime = todayStart;
    } else {
      logicDay = DateTime(now.year, now.month, now.day);
      nextRollOverTime = todayStart.add(const Duration(days: 1));
    }

    final previousLogicDay = logicDay.subtract(const Duration(days: 1));
    final nextLogicDay = logicDay.add(const Duration(days: 1));

    return LogicDayInfo(
      now: now,
      logicDay: logicDay,
      previousLogicDay: previousLogicDay,
      nextLogicDay: nextLogicDay,
      nextRollOverTime: nextRollOverTime,
    );
  }

  static String formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '${dateTime.year}-$month-$day $hour:$minute';
  }
}