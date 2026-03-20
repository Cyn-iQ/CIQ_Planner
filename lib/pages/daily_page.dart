import 'package:flutter/material.dart';
import '../data/daily_task_repository.dart';
import '../data/score_repository.dart';
import '../data/settings_repository.dart';
import '../models/app_settings.dart';
import '../services/logic_day_service.dart';
import '../models/task.dart';
import '../data/wheel_repository.dart';

class DailyPage extends StatefulWidget {
  const DailyPage({super.key});

  @override
  State<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  String _logicDate = '';
  AppSettings _settings = const AppSettings(
    dayStartTime: '00:00',
    shortTaskBaseCapacity: 3,
    fixedTaskBaseCapacity: 5,
    shortTaskCurrentCapacity: 3,
    fixedTaskCurrentCapacity: 5,
  );

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final settings = await SettingsRepository.getSettings();
    final info = LogicDayService.calculate(
      now: DateTime.now(),
      dayStartTime: settings.dayStartTime,
    );
    final logicDate = LogicDayService.formatDate(info.logicDay);

    await DailyTaskRepository.insertDefaultDailyTasksForLogicDate(logicDate);
    final tasks = await DailyTaskRepository.getTasksByLogicDate(logicDate);

    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _logicDate = logicDate;
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _reloadTasks() async {
    if (_logicDate.isEmpty) return;
    final tasks = await DailyTaskRepository.getTasksByLogicDate(_logicDate);
    final settings = await SettingsRepository.getSettings();

    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _settings = settings;
    });
  }

  int get _dailyTaskLimit {
    final current = _settings.shortTaskCurrentCapacity;
    return current < AppSettings.maxShortTaskCapacity
        ? current
        : AppSettings.maxShortTaskCapacity;
  }

  int get _fixedTaskLimit {
    final current = _settings.fixedTaskCurrentCapacity;
    return current < AppSettings.maxFixedTaskCapacity
        ? current
        : AppSettings.maxFixedTaskCapacity;
  }

  bool _canEditTask(Task task) {
    return task.type == TaskType.daily || task.type == TaskType.fixed;
  }

  Future<void> _toggleTask(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) return;

    final task = _tasks[index];
    final wasCompleted = task.isCompleted;
    final newStatus = wasCompleted ? TaskStatus.pending : TaskStatus.completed;

    await DailyTaskRepository.updateTask(
      task.copyWith(status: newStatus),
    );

    final settings = await SettingsRepository.getSettings();
    final info = LogicDayService.calculate(
      now: DateTime.now(),
      dayStartTime: settings.dayStartTime,
    );
    final logicDate = LogicDayService.formatDate(info.logicDay);

    if (newStatus == TaskStatus.completed && task.type == TaskType.fixed) {
      await WheelRepository.removeItem(
        logicDate: logicDate,
        targetId: task.id,
      );
    }

    if (!wasCompleted) {
      await ScoreRepository.addEarnRecord(
        score: task.points,
        source: 'daily_task',
        remark: '完成任务：${task.title}',
      );
    } else {
      await ScoreRepository.addSpendRecord(
        score: task.points,
        source: 'daily_task_undo',
        remark: '取消完成任务：${task.title}',
      );
    }

    await _reloadTasks();
  }

  void _showEditTaskDialog(Task task) {
    if (!_canEditTask(task)) return;

    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    final pointsController = TextEditingController(text: task.points.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑任务'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '任务名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '任务描述',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pointsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '积分',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final description = descriptionController.text.trim();
                final points = int.tryParse(pointsController.text.trim()) ?? 0;

                if (title.isEmpty) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('任务名称不能为空')),
                  );
                  return;
                }

                await DailyTaskRepository.updateTask(
                  task.copyWith(
                    title: title,
                    description: description.isEmpty ? '无描述' : description,
                    points: points,
                  ),
                );

                await _reloadTasks();

                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final pointsController = TextEditingController(text: '1');
    TaskType selectedType = TaskType.daily;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('添加任务'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: '任务名称',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: '任务描述',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pointsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '积分',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TaskType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: '任务类型',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: TaskType.daily,
                          child: Text('短期任务'),
                        ),
                        DropdownMenuItem(
                          value: TaskType.fixed,
                          child: Text('固定任务'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedType = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final description = descriptionController.text.trim();
                    final points = int.tryParse(pointsController.text.trim()) ?? 0;

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('任务名称不能为空')),
                      );
                      return;
                    }

                    final dailyCount = _tasks
                        .where((task) => task.type == TaskType.daily)
                        .length;
                    final fixedCount = _tasks
                        .where((task) => task.type == TaskType.fixed)
                        .length;

                    if (selectedType == TaskType.daily &&
                        dailyCount >= _dailyTaskLimit) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '短期任务已达到上限：$_dailyTaskLimit（系统最高 ${AppSettings.maxShortTaskCapacity}）',
                          ),
                        ),
                      );
                      return;
                    }

                    if (selectedType == TaskType.fixed &&
                        fixedCount >= _fixedTaskLimit) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '固定任务已达到上限：$_fixedTaskLimit（系统最高 ${AppSettings.maxFixedTaskCapacity}）',
                          ),
                        ),
                      );
                      return;
                    }

                    await DailyTaskRepository.addTask(
                      Task(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: title,
                        description: description.isEmpty ? '无描述' : description,
                        type: selectedType,
                        status: TaskStatus.pending,
                        points: points,
                        progress: 0,
                        targetCount: 1,
                        createdAt: DateTime.now(),
                        logicDate: _logicDate,
                      ),
                    );

                    await _reloadTasks();

                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text('添加'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteTaskDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除任务'),
          content: Text('确定要删除“${task.title}”吗？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                await DailyTaskRepository.removeTask(task.id);
                await _reloadTasks();

                if (!mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已删除任务：${task.title}')),
                );
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  String _typeLabel(TaskType type) {
    switch (type) {
      case TaskType.daily:
        return '短期任务';
      case TaskType.longTerm:
        return '长期任务';
      case TaskType.fixed:
        return '固定任务';
    }
  }

  IconData _typeIcon(TaskType type) {
    switch (type) {
      case TaskType.daily:
        return Icons.today;
      case TaskType.longTerm:
        return Icons.flag;
      case TaskType.fixed:
        return Icons.repeat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _tasks.where((task) => task.isCompleted).length;
    final totalPoints = _tasks
        .where((task) => task.isCompleted)
        .fold<int>(0, (sum, task) => sum + task.points);

    final dailyCount = _tasks.where((task) => task.type == TaskType.daily).length;
    final fixedCount = _tasks.where((task) => task.type == TaskType.fixed).length;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('今日任务'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '逻辑日：$_logicDate',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text('起始时间：${_settings.dayStartTime}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '已完成 $completedCount / ${_tasks.length}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '任务积分 $totalPoints',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '短期：$dailyCount / $_dailyTaskLimit',
                              ),
                              Text(
                                '固定：$fixedCount / $_fixedTaskLimit',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _tasks.isEmpty
                        ? const Center(
                            child: Text('今天还没有任务'),
                          )
                        : ListView.separated(
                            itemCount: _tasks.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final task = _tasks[index];
                              return Card(
                                child: ListTile(
                                  leading: Icon(_typeIcon(task.type)),
                                  title: Text(
                                    task.title,
                                    style: TextStyle(
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${_typeLabel(task.type)} · ${task.description} · ${task.points} 分',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_canEditTask(task))
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined),
                                          tooltip: '编辑任务',
                                          onPressed: () =>
                                              _showEditTaskDialog(task),
                                        ),
                                      Checkbox(
                                        value: task.isCompleted,
                                        onChanged: (_) => _toggleTask(task.id),
                                      ),
                                    ],
                                  ),
                                  onTap: () => _toggleTask(task.id),
                                  onLongPress: () => _showDeleteTaskDialog(task),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

