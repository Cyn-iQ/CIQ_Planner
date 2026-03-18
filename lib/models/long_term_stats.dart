class LongTermStats {
  final int activeCount;
  final int historyCount;
  final int completedCount;
  final int pressLineDoneCount;
  final int expiredCount;
  final int totalProgressCount;
  final double averageProgressCount;
  final double completionRate;

  const LongTermStats({
    required this.activeCount,
    required this.historyCount,
    required this.completedCount,
    required this.pressLineDoneCount,
    required this.expiredCount,
    required this.totalProgressCount,
    required this.averageProgressCount,
    required this.completionRate,
  });
}