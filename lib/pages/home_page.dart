import 'package:flutter/material.dart';

import 'history_stats_center_page.dart';
import 'points_center_page.dart';
import 'settings_page.dart';
import 'task_plan_center_page.dart';
import 'wheel_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, size: 28),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CIQ Planner'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              '欢迎来到你的计划本',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Success is the sum of small efforts, repeated day in and day out.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              icon: Icons.checklist_rtl,
              title: '任务&计划',
              subtitle: '今日任务、固定计划模板、长期计划',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TaskPlanCenterPage(),
                  ),
                );
              },
            ),
            _buildMenuCard(
              icon: Icons.casino_outlined,
              title: '随机轮盘',
              subtitle: '从当日任务和长期计划中随机抽取执行项',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WheelPage(),
                  ),
                );
              },
            ),
            _buildMenuCard(
              icon: Icons.query_stats,
              title: '历史统计',
              subtitle: '每日结算、历史任务、长期计划历史',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryStatsCenterPage(),
                  ),
                );
              },
            ),
            _buildMenuCard(
              icon: Icons.account_balance_wallet_outlined,
              title: '积分中心',
              subtitle: '查看积分、兑换奖励、管理商店',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PointsCenterPage(),
                  ),
                );
              },
            ),
            _buildMenuCard(
              icon: Icons.settings,
              title: '设置',
              subtitle: '配置每日起始时间、翻篇状态和数据备份',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
