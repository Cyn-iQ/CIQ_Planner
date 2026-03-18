import 'package:flutter/material.dart';

import '../data/long_term_plan_repository.dart';
import '../data/score_repository.dart';
import '../models/long_term_plan.dart';

class LongTermPage extends StatefulWidget {
  const LongTermPage({super.key});

  @override
  State<LongTermPage> createState() => _LongTermPageState();
}

class _LongTermPageState extends State<LongTermPage> {
  List<LongTermPlan> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    await LongTermPlanRepository.checkAndExpirePlans();

    final plans = await LongTermPlanRepository.getPlans();
    if (!mounted) return;

    setState(() {
      _plans = plans;
      _isLoading = false;
    });
  }

  Future<void> _reloadPlans() async {
    final plans = await LongTermPlanRepository.getPlans();
    if (!mounted) return;

    setState(() {
      _plans = plans;
    });
  }

  Future<void> _increaseProgress(LongTermPlan plan) async {
    final updatedPlan = plan.copyWith(
      progressCount: plan.progressCount + 1,
    );

    await LongTermPlanRepository.updatePlan(updatedPlan);

    await ScoreRepository.addEarnRecord(
      score: 1,
      source: 'long_term_plan',
      remark: '推进长期计划：${plan.title}',
    );

    await _reloadPlans();

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('“${plan.title}”已推进 +1'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () async {
            final revertedPlan = updatedPlan.copyWith(
              progressCount: plan.progressCount,
            );
            await LongTermPlanRepository.updatePlan(revertedPlan);

            await ScoreRepository.addSpendRecord(
              score: 1,
              source: 'long_term_plan_undo',
              remark: '撤销推进长期计划：${plan.title}',
            );

            await _reloadPlans();
          },
        ),
      ),
    );
  }

  Future<void> _completePlan(LongTermPlan plan) async {
    await LongTermPlanRepository.moveToHistory(
      plan,
      LongTermPlanStatus.completed,
    );

    await _reloadPlans();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已完成长期计划：${plan.title}')),
    );
  }

  void _showPlanActions(LongTermPlan plan) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('编辑长期计划'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditPlanDialog(plan);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('删除长期计划'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeletePlanDialog(plan);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeletePlanDialog(LongTermPlan plan) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除长期计划'),
          content: Text('确定要删除“${plan.title}”吗？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                await LongTermPlanRepository.removePlan(plan.id);
                await _reloadPlans();

                if (!mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已删除长期计划：${plan.title}')),
                );
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddPlanDialog() async {
    if (_plans.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('长期计划最多只能添加 3 个')),
      );
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDeadline;

    Future<void> pickDeadline(StateSetter setDialogState) async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: DateTime(now.year + 10),
      );

      if (picked != null) {
        setDialogState(() {
          selectedDeadline = picked;
        });
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('添加长期计划'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: '计划名称',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: '计划描述',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => pickDeadline(setDialogState),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '截止日期',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          selectedDeadline == null
                              ? '请选择截止日期'
                              : _formatDate(selectedDeadline!),
                        ),
                      ),
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

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('计划名称不能为空')),
                      );
                      return;
                    }

                    if (selectedDeadline == null) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('请选择截止日期')),
                      );
                      return;
                    }

                    await LongTermPlanRepository.addPlan(
                      LongTermPlan(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: title,
                        description: description.isEmpty ? '无描述' : description,
                        deadline: selectedDeadline!,
                        progressCount: 0,
                        createdAt: DateTime.now(),
                        status: LongTermPlanStatus.active,
                      ),
                    );

                    await _reloadPlans();

                    if (!mounted) return;
                    Navigator.pop(context);

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('已添加长期计划：$title')),
                    );
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

  Future<void> _showEditPlanDialog(LongTermPlan plan) async {
    final titleController = TextEditingController(text: plan.title);
    final descriptionController = TextEditingController(text: plan.description);
    final progressController =
        TextEditingController(text: plan.progressCount.toString());
    DateTime selectedDeadline = plan.deadline;

    Future<void> pickDeadline(StateSetter setDialogState) async {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDeadline,
        firstDate: DateTime(2020),
        lastDate: DateTime(DateTime.now().year + 10),
      );

      if (picked != null) {
        setDialogState(() {
          selectedDeadline = picked;
        });
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('编辑长期计划'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: '计划名称',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: '计划描述',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: progressController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '推进次数',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => pickDeadline(setDialogState),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '截止日期',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_formatDate(selectedDeadline)),
                      ),
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
                    final progress =
                        int.tryParse(progressController.text.trim()) ?? 0;

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('计划名称不能为空')),
                      );
                      return;
                    }

                    if (progress < 0) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('推进次数不能小于 0')),
                      );
                      return;
                    }

                    final updatedPlan = plan.copyWith(
                      title: title,
                      description: description.isEmpty ? '无描述' : description,
                      deadline: selectedDeadline,
                      progressCount: progress,
                    );

                    await LongTermPlanRepository.updatePlan(updatedPlan);
                    await _reloadPlans();

                    if (!mounted) return;
                    Navigator.pop(context);

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('已更新长期计划：$title')),
                    );
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _buildStatusText(LongTermPlan plan) {
    final today = DateTime.now();
    final pureToday = DateTime(today.year, today.month, today.day);
    final pureDeadline =
        DateTime(plan.deadline.year, plan.deadline.month, plan.deadline.day);

    if (plan.status == LongTermPlanStatus.completed) {
      return '已完成';
    }

    if (plan.status == LongTermPlanStatus.pressLineDone) {
      return '压线完成';
    }

    if (pureDeadline.isBefore(pureToday)) {
      return '已过期';
    }

    return '进行中';
  }

  @override
  Widget build(BuildContext context) {
    final totalProgress = _plans.fold<int>(
      0,
      (sum, plan) => sum + plan.progressCount,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('长期计划'),
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
                            '长期计划 ${_plans.length} / 3',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '累计推进 $totalProgress 次',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _plans.isEmpty
                        ? const Center(
                            child: Text('还没有长期计划，点击右下角开始添加'),
                          )
                        : ListView.separated(
                            itemCount: _plans.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final plan = _plans[index];

                              return Card(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(14),
                                  leading: const Icon(Icons.flag),
                                  title: Text(
                                    plan.title,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(plan.description),
                                        const SizedBox(height: 6),
                                        Text('截止日期：${_formatDate(plan.deadline)}'),
                                        const SizedBox(height: 4),
                                        Text('已推进：${plan.progressCount} 次'),
                                        const SizedBox(height: 4),
                                        Text('状态：${_buildStatusText(plan)}'),
                                      ],
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: '完成',
                                        onPressed: () => _completePlan(plan),
                                        icon: const Icon(
                                          Icons.check_circle_outline,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: '推进 +1',
                                        onPressed: () => _increaseProgress(plan),
                                        icon: const Icon(Icons.add_circle_outline),
                                      ),
                                    ],
                                  ),
                                  onLongPress: () => _showPlanActions(plan),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPlanDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
