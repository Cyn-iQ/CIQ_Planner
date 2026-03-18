import 'dart:math';

import 'package:flutter/material.dart';

import '../data/daily_task_repository.dart';
import '../data/long_term_plan_repository.dart';
import '../data/score_repository.dart';
import '../data/settings_repository.dart';
import '../data/wheel_repository.dart';
import '../models/long_term_plan.dart';
import '../models/task.dart';
import '../services/logic_day_service.dart';
import 'wheel_sequence_page.dart';

class WheelPage extends StatefulWidget {
  const WheelPage({super.key});

  @override
  State<WheelPage> createState() => _WheelPageState();
}

class _WheelPageState extends State<WheelPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final Random _random = Random();

  bool _isLoading = true;
  String _logicDate = '';

  List<Task> _dailyTasks = [];
  List<LongTermPlan> _longTermPlans = [];

  Task? _selectedDailyTask;
  LongTermPlan? _selectedLongTermPlan;

  List<String> _dailySequence = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final settings = await SettingsRepository.getSettings();
    final info = LogicDayService.calculate(
      now: DateTime.now(),
      dayStartTime: settings.dayStartTime,
    );
    final logicDate = LogicDayService.formatDate(info.logicDay);

    final dailyTasks = await DailyTaskRepository.getTasksByLogicDate(logicDate);
    final longTermPlans = await LongTermPlanRepository.getPlans();

    final dailySeq = await WheelRepository.getSequence(
      logicDate: logicDate,
      type: 'daily',
    );

    if (!mounted) return;

    setState(() {
      _logicDate = logicDate;
      _dailyTasks = dailyTasks;
      _longTermPlans = longTermPlans;
      _dailySequence = dailySeq;
      _syncSequences();
      _selectedDailyTask = _keepValidSelectedDailyTask();
      _selectedLongTermPlan = _keepValidSelectedLongTermPlan();
      _isLoading = false;
    });
  }

  Task? _keepValidSelectedDailyTask() {
    final remaining = _remainingDailyTasks;
    if (_selectedDailyTask == null) return null;

    final exists = remaining.any((task) => task.id == _selectedDailyTask!.id);
    if (!exists) return null;

    return remaining.firstWhere((task) => task.id == _selectedDailyTask!.id);
  }

  LongTermPlan? _keepValidSelectedLongTermPlan() {
    final remaining = _remainingLongTermPlans;
    if (_selectedLongTermPlan == null) return null;

    final exists = remaining.any((plan) => plan.id == _selectedLongTermPlan!.id);
    if (!exists) return null;

    return remaining.firstWhere((plan) => plan.id == _selectedLongTermPlan!.id);
  }

  void _syncSequences() {
    final remainingIds = _remainingDailyTasks.map((task) => task.id).toSet();
    _dailySequence = _dailySequence.where((id) => remainingIds.contains(id)).toList();
  }

  List<Task> get _remainingDailyTasks {
    return _dailyTasks.where((task) => !task.isCompleted).toList();
  }

  List<LongTermPlan> get _remainingLongTermPlans {
    return _longTermPlans
        .where((plan) => plan.status == LongTermPlanStatus.active)
        .toList();
  }

  List<Task> get _dailyDrawableTasks {
    final dailyTaskIds = _remainingDailyTasks
        .where((task) => task.type == TaskType.daily)
        .map((task) => task.id)
        .toSet();

    final drawnDailyTaskIds = _dailySequence
        .where((id) => dailyTaskIds.contains(id))
        .toSet();

    return _remainingDailyTasks.where((task) {
      if (task.type == TaskType.fixed) {
        return true;
      }

      if (task.type == TaskType.daily) {
        return !drawnDailyTaskIds.contains(task.id);
      }

      return false;
    }).toList();
  }

  bool get _isLongTermUnlocked {
    return _remainingDailyTasks.isEmpty;
  }

  Future<void> _drawDailyTask() async {
    final drawable = _dailyDrawableTasks;
    if (drawable.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('今日没有可抽取的新任务')),
      );
      return;
    }

    final picked = drawable[_random.nextInt(drawable.length)];

    if (picked.type == TaskType.daily) {
      await WheelRepository.addSequence(
        logicDate: _logicDate,
        type: 'daily',
        targetId: picked.id,
      );
    } else if (picked.type == TaskType.fixed) {
      await WheelRepository.addSequence(
        logicDate: _logicDate,
        type: 'daily',
        targetId: picked.id,
        allowDuplicate: true,
      );
    }

    await _loadData();

    if (!mounted) return;

    setState(() {
      _selectedDailyTask = _remainingDailyTasks.firstWhere(
        (task) => task.id == picked.id,
        orElse: () => picked,
      );
    });
  }

  Future<void> _drawLongTermPlan() async {
    final drawable = _remainingLongTermPlans;
    if (drawable.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前没有可推进的长期计划')),
      );
      return;
    }

    final picked = drawable[_random.nextInt(drawable.length)];

    await _loadData();

    if (!mounted) return;

    setState(() {
      _selectedLongTermPlan = _remainingLongTermPlans.firstWhere(
        (plan) => plan.id == picked.id,
        orElse: () => picked,
      );
    });
  }

  Future<void> _completeDailyTask(Task task) async {
    await DailyTaskRepository.updateTask(task.copyWith(status: TaskStatus.completed));

    if (task.type == TaskType.fixed) {
      await WheelRepository.removeItem(
        logicDate: _logicDate,
        targetId: task.id,
      );
    }

    await ScoreRepository.addEarnRecord(
      score: task.points,
      source: 'daily_task',
      remark: '轮盘完成任务：${task.title}',
    );

    await _loadData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已完成：${task.title}')),
    );
  }

  Future<void> _progressLongTermPlan(LongTermPlan plan) async {
    final updatedPlan = plan.copyWith(progressCount: plan.progressCount + 1);

    await LongTermPlanRepository.updatePlan(updatedPlan);

    await ScoreRepository.addEarnRecord(
      score: 1,
      source: 'long_term_plan',
      remark: '轮盘推进长期计划：${plan.title}',
    );

    await _loadData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已推进 +1：${plan.title}')),
    );
  }

  String _taskTypeLabel(TaskType type) {
    switch (type) {
      case TaskType.daily:
        return '短期任务';
      case TaskType.longTerm:
        return '长期任务';
      case TaskType.fixed:
        return '固定任务';
    }
  }

  void _openSequencePage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WheelSequencePage(
          logicDate: _logicDate,
          dailySequence: _dailySequence,
          dailyTasks: _dailyTasks,
        ),
      ),
    );
  }

  Widget _buildDailyWheelTab() {
    final remaining = _remainingDailyTasks;
    final drawable = _dailyDrawableTasks;

    if (remaining.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.celebration, size: 48),
                  SizedBox(height: 12),
                  Text('今日无任务，享受闲暇'),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (remaining.length == 1 && _selectedDailyTask == null) {
      final task = remaining.first;

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('唯一任务', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_taskTypeLabel(task.type)} · ${task.description} · ${task.points} 分',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _completeDailyTask(task),
                      child: const Text('立即完成'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final selectedTask = _selectedDailyTask;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  '当前剩余任务 ${remaining.length} 个',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  selectedTask == null ? '点击抽取一个任务' : '当前显示本次抽取结果',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: drawable.isEmpty ? null : _drawDailyTask,
                    child: Text(drawable.isEmpty ? '没有新的可抽任务' : '开始抽取'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (selectedTask != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('当前抽取结果', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Text(
                    selectedTask.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_taskTypeLabel(selectedTask.type)} · ${selectedTask.description} · ${selectedTask.points} 分',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _completeDailyTask(selectedTask),
                      child: const Text('完成该任务'),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLongTermWheelTab() {
    if (!_isLongTermUnlocked) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.lock_outline, size: 48),
                  SizedBox(height: 12),
                  Text('请先完成全部日常任务'),
                  SizedBox(height: 8),
                  Text('日常轮盘全部完成后，长期轮盘才会解锁', textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final remaining = _remainingLongTermPlans;

    if (remaining.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 48),
                  SizedBox(height: 12),
                  Text('当前没有可推进的长期计划'),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (remaining.length == 1 && _selectedLongTermPlan == null) {
      final plan = remaining.first;

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('唯一长期计划', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Text(
                    plan.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${plan.description} · 已推进 ${plan.progressCount} 次',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _progressLongTermPlan(plan),
                      child: const Text('推进 +1'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final selectedPlan = _selectedLongTermPlan;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  '当前候选长期计划 ${remaining.length} 个',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  selectedPlan == null ? '点击抽取一个长期计划' : '当前显示本次抽取结果',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _drawLongTermPlan,
                    child: const Text('开始抽取'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (selectedPlan != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('当前抽取结果', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Text(
                    selectedPlan.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${selectedPlan.description} · 已推进 ${selectedPlan.progressCount} 次',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _progressLongTermPlan(selectedPlan),
                      child: const Text('推进 +1'),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_logicDate.isEmpty ? '随机轮盘' : '随机轮盘（$_logicDate）'),
        actions: [
          IconButton(
            tooltip: '次序列表',
            onPressed: _isLoading ? null : _openSequencePage,
            icon: const Icon(Icons.format_list_numbered),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.casino_outlined), text: '日常轮盘'),
            Tab(icon: Icon(Icons.flag_outlined), text: '长期轮盘'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDailyWheelTab(),
                _buildLongTermWheelTab(),
              ],
            ),
    );
  }
}

