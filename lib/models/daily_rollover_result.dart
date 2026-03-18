class DailyRolloverResult {
  final bool hasRolledOver;
  final String currentLogicDay;
  final String? previousProcessedLogicDay;
  final String message;
  final DateTime nextRollOverTime;

  const DailyRolloverResult({
    required this.hasRolledOver,
    required this.currentLogicDay,
    required this.previousProcessedLogicDay,
    required this.message,
    required this.nextRollOverTime,
  });
}