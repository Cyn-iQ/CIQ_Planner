import 'package:flutter/material.dart';

import '../data/reward_repository.dart';
import '../data/score_repository.dart';
import '../models/reward_item.dart';
import '../models/score_summary.dart';

class RewardShopPage extends StatefulWidget {
  const RewardShopPage({super.key});

  @override
  State<RewardShopPage> createState() => _RewardShopPageState();
}

class _RewardShopPageState extends State<RewardShopPage> {
  List<RewardItem> _items = [];
  ScoreSummary _summary = const ScoreSummary(
    currentScore: 0,
    totalEarned: 0,
    totalSpent: 0,
  );
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await RewardRepository.getItems();
    final summary = await ScoreRepository.getSummary();

    if (!mounted) return;

    setState(() {
      _items = items;
      _summary = summary;
      _isLoading = false;
    });
  }

  Future<void> _redeem(RewardItem item) async {
    final ok = await ScoreRepository.redeemReward(
      cost: item.cost,
      rewardTitle: item.title,
    );

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('积分不足，无法兑换')),
      );
      return;
    }

    await _load();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('兑换成功：${item.title}')),
    );
  }

  void _showRedeemDialog(RewardItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认兑换'),
          content: Text('确定要花费 ${item.cost} 积分兑换“${item.title}”吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _redeem(item);
              },
              child: const Text('兑换'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('积分商店'),
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
                            '当前可用积分',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_summary.currentScore}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _items.isEmpty
                        ? const Center(
                            child: Text('还没有可兑换商品，请先去商店管理添加'),
                          )
                        : ListView.separated(
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final canRedeem = _summary.currentScore >= item.cost;

                              return Card(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(14),
                                  leading: const Icon(Icons.redeem),
                                  title: Text(item.title),
                                  subtitle: Text('消耗 ${item.cost} 分'),
                                  trailing: ElevatedButton(
                                    onPressed:
                                        canRedeem ? () => _showRedeemDialog(item) : null,
                                    child: const Text('兑换'),
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
