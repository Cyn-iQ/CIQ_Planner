import 'package:flutter/material.dart';

import '../data/fixed_plan_template_repository.dart';
import '../data/settings_repository.dart';
import '../models/app_settings.dart';
import '../models/fixed_plan_template.dart';

class FixedPlanPage extends StatefulWidget {
  const FixedPlanPage({super.key});

  @override
  State<FixedPlanPage> createState() => _FixedPlanPageState();
}

class _FixedPlanPageState extends State<FixedPlanPage> {
  List<FixedPlanTemplate> _templates = [];
  bool _isLoading = true;

  AppSettings _settings = const AppSettings(
    dayStartTime: '00:00',
    shortTaskBaseCapacity: 3,
    fixedTaskBaseCapacity: 5,
    shortTaskCurrentCapacity: 3,
    fixedTaskCurrentCapacity: 5,
  );

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final templates = await FixedPlanTemplateRepository.getTemplates();
    final settings = await SettingsRepository.getSettings();

    if (!mounted) return;

    setState(() {
      _templates = templates;
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _reloadTemplates() async {
    final templates = await FixedPlanTemplateRepository.getTemplates();
    final settings = await SettingsRepository.getSettings();

    if (!mounted) return;

    setState(() {
      _templates = templates;
      _settings = settings;
    });
  }

  Future<void> _showAddTemplateDialog() async {
    if (_templates.length >= AppSettings.maxFixedTaskCapacity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '固定任务模板最多 ${AppSettings.maxFixedTaskCapacity} 个',
          ),
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final pointsController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加固定计划模板'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '模板名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '模板描述',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pointsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '积分',
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
                final description = descriptionController.text.trim();
                final points = int.tryParse(pointsController.text.trim()) ?? 0;

                if (title.isEmpty) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('模板名称不能为空')),
                  );
                  return;
                }

                if (points <= 0) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('积分必须大于 0')),
                  );
                  return;
                }

                await FixedPlanTemplateRepository.addTemplate(
                  FixedPlanTemplate(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    description: description.isEmpty ? '无描述' : description,
                    points: points,
                    createdAt: DateTime.now(),
                  ),
                );

                await _reloadTemplates();

                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditTemplateDialog(FixedPlanTemplate template) async {
    final titleController = TextEditingController(text: template.title);
    final descriptionController =
        TextEditingController(text: template.description);
    final pointsController =
        TextEditingController(text: template.points.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑固定计划模板'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '模板名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '模板描述',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pointsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '积分',
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
                final description = descriptionController.text.trim();
                final points = int.tryParse(pointsController.text.trim()) ?? 0;

                if (title.isEmpty) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('模板名称不能为空')),
                  );
                  return;
                }

                if (points <= 0) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('积分必须大于 0')),
                  );
                  return;
                }

                await FixedPlanTemplateRepository.updateTemplate(
                  template.copyWith(
                    title: title,
                    description: description.isEmpty ? '无描述' : description,
                    points: points,
                  ),
                );

                await _reloadTemplates();

                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteTemplateDialog(FixedPlanTemplate template) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除固定计划模板'),
          content: Text('确定要删除“${template.title}”吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FixedPlanTemplateRepository.removeTemplate(template.id);
                await _reloadTemplates();

                if (!mounted) return;
                Navigator.pop(context);
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
    final autoImportCount = _templates.length > _settings.fixedTaskCurrentCapacity
        ? _settings.fixedTaskCurrentCapacity
        : _templates.length;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('固定计划模板'),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '模板 ${_templates.length} / ${AppSettings.maxFixedTaskCapacity}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '当前容量 ${_settings.fixedTaskCurrentCapacity}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('保底容量 ${_settings.fixedTaskBaseCapacity}'),
                              Text('今日自动带入 $autoImportCount 个'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _templates.isEmpty
                        ? const Center(
                            child: Text('还没有固定计划模板，点击右下角开始添加'),
                          )
                        : ListView.separated(
                            itemCount: _templates.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final template = _templates[index];
                              final willAutoImport =
                                  index < _settings.fixedTaskCurrentCapacity;

                              return Card(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(14),
                                  leading: const Icon(Icons.repeat),
                                  title: Text(template.title),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(template.description),
                                        const SizedBox(height: 4),
                                        Text('积分：${template.points}'),
                                        const SizedBox(height: 4),
                                        Text(
                                          willAutoImport
                                              ? '状态：会自动带入今日页'
                                              : '状态：超出当前容量，暂不自动带入',
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () =>
                                            _showEditTemplateDialog(template),
                                        icon: const Icon(Icons.edit_outlined),
                                        tooltip: '编辑模板',
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            _showDeleteTemplateDialog(template),
                                        icon: const Icon(Icons.delete_outline),
                                        tooltip: '删除模板',
                                      ),
                                    ],
                                  ),
                                  onTap: () => _showEditTemplateDialog(template),
                                  onLongPress: () =>
                                      _showDeleteTemplateDialog(template),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTemplateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
