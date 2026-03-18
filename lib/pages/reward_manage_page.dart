import 'package:flutter/material.dart';

import '../data/reward_repository.dart';
import '../models/reward_item.dart';

class RewardManagePage extends StatefulWidget {
  const RewardManagePage({super.key});

  @override
  State<RewardManagePage> createState() => _RewardManagePageState();
}

class _RewardManagePageState extends State<RewardManagePage> {
  List<RewardItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await RewardRepository.getItems();

    if (!mounted) return;

    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  void _showItemDialog({RewardItem? item}) {
    final titleController = TextEditingController(text: item?.title ?? '');
    final costController = TextEditingController(
      text: item == null ? '' : item.cost.toString(),
    );

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(item == null ? '新增商品' : '编辑商品'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '商品名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '所需积分',
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
                final title = titleController.text.trim();
                final cost = int.tryParse(costController.text.trim()) ?? 0;

                if (title.isEmpty) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('商品名称不能为空')),
                  );
                  return;
                }

                if (cost <= 0) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('所需积分必须大于 0')),
                  );
                  return;
                }

                final newItem = RewardItem(
                  id: item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title,
                  cost: cost,
                  createdAt: item?.createdAt ?? DateTime.now(),
                );

                if (item == null) {
                  await RewardRepository.addItem(newItem);
                } else {
                  await RewardRepository.updateItem(newItem);
                }

                if (!mounted) return;
                Navigator.pop(context);
                await _load();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(RewardItem item) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('删除商品'),
          content: Text('确定要删除“${item.title}”吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                await RewardRepository.deleteItem(item.id);

                if (!mounted) return;
                Navigator.pop(context);
                await _load();
              },
              child: const Text('删除'),
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
        title: const Text('商店管理'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('还没有商品，点击右下角新增'))
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final item = _items[i];

                    return ListTile(
                      title: Text(item.title),
                      subtitle: Text('${item.cost} 分'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showItemDialog(item: item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _showDeleteDialog(item),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
