import 'package:flutter/material.dart';

import '../data/long_term_plan_repository.dart';
import '../models/long_term_plan.dart';
import '../models/long_term_plan_history.dart';

class LongTermHistoryPage extends StatefulWidget {
  const LongTermHistoryPage({super.key});

  @override
  State<LongTermHistoryPage> createState() => _LongTermHistoryPageState();
}

class _LongTermHistoryPageState extends State<LongTermHistoryPage> {
  List<LongTermPlanHistory> _historyPlans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistoryPlans();
  }

  Future<void> _loadHistoryPlans() async {
    final historyPlans = await LongTermPlanRepository.getHistoryPlans();

    if (!mounted) return;

    setState(() {
      _historyPlans = historyPlans;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _statusLabel(LongTermPlanStatus status) {
    switch (status) {
      case LongTermPlanStatus.completed:
        return '主动完成';
      case LongTermPlanStatus.pressLineDone:
        return '压线完成';
      case LongTermPlanStatus.expired:
        return '已过期';
      case LongTermPlanStatus.active:
        return '进行中';
    }
  }

  IconData _statusIcon(LongTermPlanStatus status) {
    switch (status) {
      case LongTermPlanStatus.completed:
        return Icons.check_circle_outline;
      case LongTermPlanStatus.pressLineDone:
        return Icons.schedule;
      case LongTermPlanStatus.expired:
        return Icons.error_outline;
      case LongTermPlanStatus.active:
        return Icons.flag_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _historyPlans
        .where((plan) => plan.status == LongTermPlanStatus.completed)
        .length;

    final pressLineDoneCount = _historyPlans
        .where((plan) => plan.status == LongTermPlanStatus.pressLineDone)
        .length;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('长期计划历史'),
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
                            '历史记录 ${_historyPlans.length} 条',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('主动完成 $completedCount'),
                              Text('压线完成 $pressLineDoneCount'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _historyPlans.isEmpty
                        ? const Center(
                            child: Text('还没有历史记录'),
                          )
                        : ListView.separated(
                            itemCount: _historyPlans.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final plan = _historyPlans[index];

                              return Card(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(14),
                                  leading: Icon(_statusIcon(plan.status)),
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
                                        Text('结束日期：${_formatDate(plan.finishedAt)}'),
                                        const SizedBox(height: 4),
                                        Text('累计推进：${plan.progressCount} 次'),
                                        const SizedBox(height: 4),
                                        Text('状态：${_statusLabel(plan.status)}'),
                                      ],
                                    ),
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
