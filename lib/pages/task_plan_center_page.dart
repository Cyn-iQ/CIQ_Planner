import 'package:flutter/material.dart';

import 'daily_page.dart';
import 'fixed_plan_page.dart';
import 'long_term_page.dart';

class TaskPlanCenterPage extends StatelessWidget {
  const TaskPlanCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: _TaskPlanTabBar(),
        body: TabBarView(
          children: [
            DailyPage(),
            FixedPlanPage(),
            LongTermPage(),
          ],
        ),
      ),
    );
  }
}

class _TaskPlanTabBar extends StatelessWidget implements PreferredSizeWidget {
  const _TaskPlanTabBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('任务&计划'),
      bottom: const TabBar(
        tabs: [
          Tab(
            icon: Icon(Icons.today),
            text: '今日任务',
          ),
          Tab(
            icon: Icon(Icons.repeat),
            text: '固定计划模板',
          ),
          Tab(
            icon: Icon(Icons.flag),
            text: '长期计划',
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 48);
}
