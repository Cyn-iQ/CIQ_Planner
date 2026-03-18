import 'package:flutter/material.dart';

import '../data/daily_settlement_repository.dart';
import '../models/daily_settlement.dart';

class DailySettlementHistoryPage extends StatefulWidget {
  const DailySettlementHistoryPage({super.key});

  @override
  State<DailySettlementHistoryPage> createState() =>
      _DailySettlementHistoryPageState();
}

class _DailySettlementHistoryPageState
    extends State<DailySettlementHistoryPage> {
  List<DailySettlement> _settlements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettlements();
  }

  Future<void> _loadSettlements() async {
    final settlements = await DailySettlementRepository.getSettlements();

    if (!mounted) return;

    setState(() {
      _settlements = settlements;
      _isLoading = false;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day $hour:$minute';
  }

  String _buildCompletionRateText(int completed, int total) {
    if (total == 0) {
      return '100%';
    }
    final rate = (completed / total * 100).toStringAsFixed(0);
    return '$rate%';
  }

  @override
  Widget build(BuildContext context) {
    final perfectCount =
        _settlements.where((item) => item.isPerfectAttendance).length;

    final totalBonus = _settlements.fold<int>(
      0,
      (sum, item) => sum + item.bonusPoints,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('每日结算历史'),
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
                            '结算 ${_settlements.length} 天',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('全勤 $perfectCount 天'),
                              Text('奖励累计 $totalBonus 分'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _settlements.isEmpty
                        ? const Center(
                            child: Text('还没有每日结算记录'),
                          )
                        : ListView.separated(
                            itemCount: _settlements.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final settlement = _settlements[index];

                              return Card(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(14),
                                  leading: Icon(
                                    settlement.isPerfectAttendance
                                        ? Icons.emoji_events_outlined
                                        : Icons.event_note_outlined,
                                  ),
                                  title: Text(
                                    settlement.logicDate,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '短期任务：${settlement.dailyCompletedCount}/${settlement.dailyTotalCount}'
                                          '（${_buildCompletionRateText(settlement.dailyCompletedCount, settlement.dailyTotalCount)}）',
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '固定任务：${settlement.fixedCompletedCount}/${settlement.fixedTotalCount}'
                                          '（${_buildCompletionRateText(settlement.fixedCompletedCount, settlement.fixedTotalCount)}）',
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '全勤状态：${settlement.isPerfectAttendance ? '是' : '否'}',
                                        ),
                                        const SizedBox(height: 4),
                                        Text('奖励积分：${settlement.bonusPoints}'),
                                        const SizedBox(height: 4),
                                        Text(
                                          '结算时间：${_formatDateTime(settlement.settledAt)}',
                                        ),
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
