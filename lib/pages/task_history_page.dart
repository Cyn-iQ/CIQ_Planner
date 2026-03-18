import 'package:flutter/material.dart';

import '../data/daily_task_repository.dart';
import '../models/task.dart';

class TaskHistoryPage extends StatefulWidget {
  const TaskHistoryPage({super.key});

  @override
  State<TaskHistoryPage> createState() => _TaskHistoryPageState();
}

class _TaskHistoryPageState extends State<TaskHistoryPage> {
  List<String> _logicDates = [];
  List<Task> _tasks = [];
  String? _selectedLogicDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogicDates();
  }

  Future<void> _loadLogicDates() async {
    final logicDates = await DailyTaskRepository.getAllLogicDates();

    if (!mounted) return;

    if (logicDates.isEmpty) {
      setState(() {
        _logicDates = [];
        _tasks = [];
        _selectedLogicDate = null;
        _isLoading = false;
      });
      return;
    }

    final selectedDate = logicDates.first;
    final tasks = await DailyTaskRepository.getTasksByLogicDate(selectedDate);

    if (!mounted) return;

    setState(() {
      _logicDates = logicDates;
      _selectedLogicDate = selectedDate;
      _tasks = tasks;
      _isLoading = false;
    });
  }

  Future<void> _selectLogicDate(String logicDate) async {
    final tasks = await DailyTaskRepository.getTasksByLogicDate(logicDate);

    if (!mounted) return;

    setState(() {
      _selectedLogicDate = logicDate;
      _tasks = tasks;
    });
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

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('历史任务'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logicDates.isEmpty
              ? const Center(
                  child: Text('还没有历史任务记录'),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedLogicDate,
                        decoration: const InputDecoration(
                          labelText: '选择逻辑日',
                          border: OutlineInputBorder(),
                        ),
                        items: _logicDates
                            .map(
                              (date) => DropdownMenuItem(
                                value: date,
                                child: Text(date),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          _selectLogicDate(value);
                        },
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '已完成 $completedCount / ${_tasks.length}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '完成积分 $totalPoints',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _tasks.isEmpty
                            ? const Center(
                                child: Text('这一天没有任务'),
                              )
                            : ListView.separated(
                                itemCount: _tasks.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
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
                                      trailing: Icon(
                                        task.isCompleted
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
