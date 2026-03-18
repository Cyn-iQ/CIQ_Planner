import 'package:flutter/material.dart';

import 'daily_settlement_history_page.dart';
import 'long_term_history_page.dart';
import 'task_history_page.dart';

class HistoryStatsCenterPage extends StatelessWidget {
  const HistoryStatsCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: _HistoryStatsTabBar(),
        body: TabBarView(
          children: [
            DailySettlementHistoryPage(),
            TaskHistoryPage(),
            LongTermHistoryPage(),
          ],
        ),
      ),
    );
  }
}

class _HistoryStatsTabBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _HistoryStatsTabBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('历史统计'),
      bottom: const TabBar(
        tabs: [
          Tab(
            icon: Icon(Icons.receipt_long),
            text: '每日结算',
          ),
          Tab(
            icon: Icon(Icons.history_toggle_off),
            text: '历史任务',
          ),
          Tab(
            icon: Icon(Icons.flag_circle_outlined),
            text: '长期计划历史',
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 48);
}
