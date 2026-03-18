import 'package:flutter/material.dart';

import '../data/score_repository.dart';
import '../models/point_record.dart';
import '../models/score_summary.dart';

class ScorePage extends StatefulWidget {
  const ScorePage({super.key});

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  ScoreSummary _summary = const ScoreSummary(
    currentScore: 0,
    totalEarned: 0,
    totalSpent: 0,
  );
  List<PointRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScoreData();
  }

  Future<void> _loadScoreData() async {
    final summary = await ScoreRepository.getSummary();
    final records = await ScoreRepository.getRecords();

    if (!mounted) return;

    setState(() {
      _summary = summary;
      _records = records;
      _isLoading = false;
    });
  }

  Future<void> _showSpendDialog() async {
    final scoreController = TextEditingController();
    final remarkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('手动扣除积分'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: scoreController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '扣除分值',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: remarkController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '用途备注',
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
                final score = int.tryParse(scoreController.text.trim()) ?? 0;
                final remark = remarkController.text.trim();

                if (score <= 0) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('请输入大于 0 的分值')),
                  );
                  return;
                }

                await ScoreRepository.addSpendRecord(
                  score: score,
                  source: 'manual_spend',
                  remark: remark.isEmpty ? '手动扣除积分' : remark,
                );

                await _loadScoreData();

                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text('确认扣除'),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day $hour:$minute';
  }

  String _typeLabel(PointRecord record) {
    return record.delta >= 0 ? '+${record.delta}' : '${record.delta}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('积分系统'),
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
                      child: Column(
                        children: [
                          Text(
                            '当前总积分',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_summary.currentScore}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('累计获得：${_summary.totalEarned}'),
                              Text('累计消耗：${_summary.totalSpent}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _records.isEmpty
                        ? const Center(
                            child: Text('还没有积分流水'),
                          )
                        : ListView.separated(
                            itemCount: _records.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final record = _records[index];
                              return Card(
                                child: ListTile(
                                  leading: Icon(
                                    record.delta >= 0
                                        ? Icons.add_circle_outline
                                        : Icons.remove_circle_outline,
                                  ),
                                  title: Text(record.remark),
                                  subtitle: Text(
                                    '${record.source} · ${_formatDateTime(record.createdAt)}',
                                  ),
                                  trailing: Text(
                                    _typeLabel(record),
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSpendDialog,
        child: const Icon(Icons.remove),
      ),
    );
  }
}
