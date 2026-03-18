import 'package:flutter/material.dart';

import '../models/task.dart';

class WheelSequencePage extends StatelessWidget {
  final String logicDate;
  final List<String> dailySequence;
  final List<Task> dailyTasks;

  const WheelSequencePage({
    super.key,
    required this.logicDate,
    required this.dailySequence,
    required this.dailyTasks,
  });

  String _taskTypeLabel(TaskType type) {
    switch (type) {
      case TaskType.daily:
        return '短期任务';
      case TaskType.fixed:
        return '固定任务';
      case TaskType.longTerm:
        return '长期任务';
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title, int count) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: 8),
        Text('($count)', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskMap = <String, Task>{for (final t in dailyTasks) t.id: t};

    return Scaffold(
      appBar: AppBar(title: const Text('轮盘次序')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('逻辑日', style: Theme.of(context).textTheme.titleMedium),
                    Text(logicDate, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildSectionTitle(context, '日常/固定次序', dailySequence.length),
            const SizedBox(height: 8),
            if (dailySequence.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('暂无日常/固定次序记录'),
                ),
              )
            else
              ...dailySequence.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final id = entry.value;
                final task = taskMap[id];

                if (task == null) {
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text('$index')),
                      title: const Text('任务不存在'),
                      subtitle: Text('编号: $id'),
                    ),
                  );
                }

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('$index')),
                    title: Text(task.title),
                    subtitle: Text(
                      '${_taskTypeLabel(task.type)} · ${task.description}',
                    ),
                    trailing: Chip(
                      label: Text(task.isCompleted ? '已完成' : '待完成'),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
