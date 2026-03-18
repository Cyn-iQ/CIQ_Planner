class DailySettlement {
  final String logicDate;
  final int dailyTotalCount;
  final int dailyCompletedCount;
  final int fixedTotalCount;
  final int fixedCompletedCount;
  final bool isPerfectAttendance;
  final int bonusPoints;
  final DateTime settledAt;

  const DailySettlement({
    required this.logicDate,
    required this.dailyTotalCount,
    required this.dailyCompletedCount,
    required this.fixedTotalCount,
    required this.fixedCompletedCount,
    required this.isPerfectAttendance,
    required this.bonusPoints,
    required this.settledAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'logic_date': logicDate,
      'daily_total_count': dailyTotalCount,
      'daily_completed_count': dailyCompletedCount,
      'fixed_total_count': fixedTotalCount,
      'fixed_completed_count': fixedCompletedCount,
      'is_perfect_attendance': isPerfectAttendance ? 1 : 0,
      'bonus_points': bonusPoints,
      'settled_at': settledAt.toIso8601String(),
    };
  }

  factory DailySettlement.fromMap(Map<String, dynamic> map) {
    return DailySettlement(
      logicDate: map['logic_date'] as String,
      dailyTotalCount: map['daily_total_count'] as int,
      dailyCompletedCount: map['daily_completed_count'] as int,
      fixedTotalCount: map['fixed_total_count'] as int,
      fixedCompletedCount: map['fixed_completed_count'] as int,
      isPerfectAttendance: (map['is_perfect_attendance'] as int) == 1,
      bonusPoints: map['bonus_points'] as int,
      settledAt: DateTime.parse(map['settled_at'] as String),
    );
  }
}