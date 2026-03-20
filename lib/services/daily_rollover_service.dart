import '../data/daily_settlement_repository.dart';
import '../data/daily_task_repository.dart';
import '../data/fixed_plan_template_repository.dart';
import '../data/runtime_state_repository.dart';
import '../data/score_repository.dart';
import '../data/settings_repository.dart';
import '../models/daily_rollover_result.dart';
import '../models/daily_settlement.dart';
import '../models/task.dart';
import 'logic_day_service.dart';

class DailyRolloverService {
  DailyRolloverService._();

  static Future<DailyRolloverResult> ensureDailyRollover({
    required String dayStartTime,
  }) async {
    final info = LogicDayService.calculate(
      now: DateTime.now(),
      dayStartTime: dayStartTime,
    );

    final currentLogicDay = LogicDayService.formatDate(info.logicDay);
    final lastProcessedLogicDay =
        await RuntimeStateRepository.getLastRolloverLogicDay();

    if (lastProcessedLogicDay == null) {
      await _processFirstInitialization(currentLogicDay);
      await RuntimeStateRepository.setLastRolloverLogicDay(currentLogicDay);

      return DailyRolloverResult(
        hasRolledOver: false,
        currentLogicDay: currentLogicDay,
        previousProcessedLogicDay: null,
        message: '首次初始化逻辑日',
        nextRollOverTime: info.nextRollOverTime,
      );
    }

    if (lastProcessedLogicDay != currentLogicDay) {
      await _processNewLogicDay(
        previousLogicDay: lastProcessedLogicDay,
        currentLogicDay: currentLogicDay,
      );

      await RuntimeStateRepository.setLastRolloverLogicDay(currentLogicDay);

      return DailyRolloverResult(
        hasRolledOver: true,
        currentLogicDay: currentLogicDay,
        previousProcessedLogicDay: lastProcessedLogicDay,
        message: '检测到新逻辑日，已完成基础翻篇',
        nextRollOverTime: info.nextRollOverTime,
      );
    }

    await _ensureTodayTasks(currentLogicDay);

    return DailyRolloverResult(
      hasRolledOver: false,
      currentLogicDay: currentLogicDay,
      previousProcessedLogicDay: lastProcessedLogicDay,
      message: '当前无需翻篇',
      nextRollOverTime: info.nextRollOverTime,
    );
  }

  static Future<void> _processFirstInitialization(String logicDay) async {
    final settings = await SettingsRepository.getSettings();

    await DailyTaskRepository.insertDefaultDailyTasksForLogicDate(logicDay);

    final templates = await FixedPlanTemplateRepository.getTemplates();
    await DailyTaskRepository.ensureFixedTasksForLogicDate(
      logicDate: logicDay,
      templates: templates,
      fixedCapacity: settings.fixedTaskCurrentCapacity,
    );

    await RuntimeStateRepository.setCurrentDailyTaskLogicDay(logicDay);
  }

  static Future<void> _processNewLogicDay({
    required String previousLogicDay,
    required String currentLogicDay,
  }) async {
    await _settlePreviousLogicDay(previousLogicDay);
    await _adjustCapacitiesByPreviousDay(previousLogicDay);

    final settings = await SettingsRepository.getSettings();

    await DailyTaskRepository.insertDefaultDailyTasksForLogicDate(
      currentLogicDay,
    );

    final templates = await FixedPlanTemplateRepository.getTemplates();
    await DailyTaskRepository.ensureFixedTasksForLogicDate(
      logicDate: currentLogicDay,
      templates: templates,
      fixedCapacity: settings.fixedTaskCurrentCapacity,
    );

    await RuntimeStateRepository.setCurrentDailyTaskLogicDay(currentLogicDay);
  }

  static Future<void> _ensureTodayTasks(String logicDay) async {
    final settings = await SettingsRepository.getSettings();

    await DailyTaskRepository.insertDefaultDailyTasksForLogicDate(logicDay);

    final templates = await FixedPlanTemplateRepository.getTemplates();
    await DailyTaskRepository.ensureFixedTasksForLogicDate(
      logicDate: logicDay,
      templates: templates,
      fixedCapacity: settings.fixedTaskCurrentCapacity,
    );

    await RuntimeStateRepository.setCurrentDailyTaskLogicDay(logicDay);
  }

  static Future<void> _settlePreviousLogicDay(String logicDate) async {
    final hasSettled = await DailySettlementRepository.hasSettled(logicDate);
    if (hasSettled) return;

    final dailyStats = await DailyTaskRepository.getTaskStatsByTypeAndLogicDate(
      logicDate: logicDate,
      type: TaskType.daily,
    );

    final fixedStats = await DailyTaskRepository.getTaskStatsByTypeAndLogicDate(
      logicDate: logicDate,
      type: TaskType.fixed,
    );

    final dailyTotal = dailyStats['totalCount'] ?? 0;
    final dailyCompleted = dailyStats['completedCount'] ?? 0;
    final fixedTotal = fixedStats['totalCount'] ?? 0;
    final fixedCompleted = fixedStats['completedCount'] ?? 0;

    final isPerfectAttendance =
        dailyTotal == dailyCompleted && fixedTotal == fixedCompleted;

    int bonusPoints = 0;

    if (isPerfectAttendance && (dailyTotal + fixedTotal) > 0) {
      final completedPoints =
          await DailyTaskRepository.getCompletedPointsByLogicDate(logicDate);
      bonusPoints = completedPoints ~/ 3;
      if (bonusPoints < 1) {
        bonusPoints = 1;
      }

      await ScoreRepository.addSystemBonusRecord(
        score: bonusPoints,
        remark: '全勤奖励：$logicDate',
      );
    }

    final settlement = DailySettlement(
      logicDate: logicDate,
      dailyTotalCount: dailyTotal,
      dailyCompletedCount: dailyCompleted,
      fixedTotalCount: fixedTotal,
      fixedCompletedCount: fixedCompleted,
      isPerfectAttendance: isPerfectAttendance,
      bonusPoints: bonusPoints,
      settledAt: DateTime.now(),
    );

    await DailySettlementRepository.insertSettlement(settlement);
  }

  static Future<void> _adjustCapacitiesByPreviousDay(String logicDate) async {
    final settings = await SettingsRepository.getSettings();

    final dailyStats = await DailyTaskRepository.getTaskStatsByTypeAndLogicDate(
      logicDate: logicDate,
      type: TaskType.daily,
    );

    final fixedStats = await DailyTaskRepository.getTaskStatsByTypeAndLogicDate(
      logicDate: logicDate,
      type: TaskType.fixed,
    );

    final newShortCapacity = _calculateNextCapacity(
      baseCapacity: settings.shortTaskBaseCapacity,
      currentCapacity: settings.shortTaskCurrentCapacity,
      totalCount: dailyStats['totalCount'] ?? 0,
      completedCount: dailyStats['completedCount'] ?? 0,
      maxCapacity: SettingsRepository.maxShortTaskCapacity,
    );

    final newFixedCapacity = _calculateNextCapacity(
      baseCapacity: settings.fixedTaskBaseCapacity,
      currentCapacity: settings.fixedTaskCurrentCapacity,
      totalCount: fixedStats['totalCount'] ?? 0,
      completedCount: fixedStats['completedCount'] ?? 0,
      maxCapacity: SettingsRepository.maxFixedTaskCapacity,
    );

    final updatedSettings = settings.copyWith(
      shortTaskCurrentCapacity: newShortCapacity,
      fixedTaskCurrentCapacity: newFixedCapacity,
    );

    await SettingsRepository.saveSettings(updatedSettings);
  }

  static int _calculateNextCapacity({
    required int baseCapacity,
    required int currentCapacity,
    required int totalCount,
    required int completedCount,
    required int maxCapacity,
  }) {
    if (totalCount == 0) {
      return currentCapacity.clamp(baseCapacity, maxCapacity).toInt();
    }

    final completionRate = completedCount / totalCount;

    int nextCapacity;
    if (completionRate >= 0.8) {
      nextCapacity = currentCapacity + 1;
    } else {
      nextCapacity = currentCapacity - 1;
    }

    if (nextCapacity < baseCapacity) {
      nextCapacity = baseCapacity;
    }

    if (nextCapacity > maxCapacity) {
      nextCapacity = maxCapacity;
    }

    return nextCapacity;
  }
}
