import 'package:flutter/material.dart';
import '../data/long_term_plan_repository.dart';
import '../models/long_term_stats.dart';

class LongTermStatsPage extends StatefulWidget {
  const LongTermStatsPage({super.key});

  @override
  State<LongTermStatsPage> createState() => _LongTermStatsPageState();
}

class _LongTermStatsPageState extends State<LongTermStatsPage> {
  LongTermStats _stats = const LongTermStats(
    activeCount: 0,
    historyCount: 0,
    completedCount: 0,
    pressLineDoneCount: 0,
    expiredCount: 0,
    totalProgressCount: 0,
    averageProgressCount: 0,
    completionRate: 0,
  );

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await LongTermPlanRepository.getStats();

    if (!mounted) return;

    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  String _formatRate(double value) {
    return '${(value * 100).toStringAsFixed(0)}%';
  }

  String _formatAverage(double value) {
    return value.toStringAsFixed(1);
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    IconData? icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('长期计划统计'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  _buildSectionTitle('总览'),
                  _buildStatCard(
                    title: '当前进行中',
                    value: '${_stats.activeCount}',
                    icon: Icons.flag,
                  ),
                  _buildStatCard(
                    title: '历史记录总数',
                    value: '${_stats.historyCount}',
                    icon: Icons.history,
                  ),
                  _buildStatCard(
                    title: '总推进次数',
                    value: '${_stats.totalProgressCount}',
                    icon: Icons.trending_up,
                  ),
                  _buildStatCard(
                    title: '平均推进次数',
                    value: _formatAverage(_stats.averageProgressCount),
                    icon: Icons.bar_chart,
                  ),
                  const SizedBox(height: 12),
                  _buildSectionTitle('完成情况'),
                  _buildStatCard(
                    title: '主动完成',
                    value: '${_stats.completedCount}',
                    icon: Icons.check_circle_outline,
                  ),
                  _buildStatCard(
                    title: '压线完成',
                    value: '${_stats.pressLineDoneCount}',
                    icon: Icons.schedule,
                  ),
                  _buildStatCard(
                    title: '已过期',
                    value: '${_stats.expiredCount}',
                    icon: Icons.error_outline,
                  ),
                  _buildStatCard(
                    title: '整体完成率',
                    value: _formatRate(_stats.completionRate),
                    icon: Icons.percent,
                  ),
                ],
              ),
            ),
    );
  }
}