import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/settings_repository.dart';
import '../models/app_settings.dart';
import '../models/daily_rollover_result.dart';
import '../services/daily_rollover_service.dart';
import '../services/data_backup_service.dart';
import '../services/logic_day_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const List<String> _timeOptions = [
    '00:00',
    '04:00',
    '05:00',
    '06:00',
  ];

  AppSettings _settings = const AppSettings(
    dayStartTime: '00:00',
    shortTaskBaseCapacity: 3,
    fixedTaskBaseCapacity: 5,
    shortTaskCurrentCapacity: 3,
    fixedTaskCurrentCapacity: 5,
  );

  DailyRolloverResult? _rolloverResult;
  bool _isLoading = true;
  bool _isBackupProcessing = false;
  String _selectedTime = '00:00';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsRepository.getSettings();
    final rolloverResult = await DailyRolloverService.ensureDailyRollover(
      dayStartTime: settings.dayStartTime,
    );

    if (!mounted) return;

    setState(() {
      _settings = settings;
      _selectedTime = settings.dayStartTime;
      _rolloverResult = rolloverResult;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final updatedSettings = _settings.copyWith(
      dayStartTime: _selectedTime,
    );

    await SettingsRepository.saveSettings(updatedSettings);

    final rolloverResult = await DailyRolloverService.ensureDailyRollover(
      dayStartTime: updatedSettings.dayStartTime,
    );

    if (!mounted) return;

    setState(() {
      _settings = updatedSettings;
      _rolloverResult = rolloverResult;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('设置已保存')));
  }

  Future<void> _exportBackup() async {
    if (_isBackupProcessing) return;

    setState(() {
      _isBackupProcessing = true;
    });

    try {
      final backupFile = await DataBackupService.exportBackup();

      if (!mounted) return;

      await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: '计划本数据备份',
        text: '计划本 SQLite 备份文件',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出成功：${backupFile.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败：$e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isBackupProcessing = false;
      });
    }
  }

  Future<void> _importBackup() async {
    if (_isBackupProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('导入备份'),
          content: const Text('导入会覆盖当前本地数据，是否继续？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('继续导入'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: const ['db', 'sqlite', 'sqlite3'],
    );

    final selectedPath = picked?.files.single.path;
    if (selectedPath == null || selectedPath.isEmpty) return;

    setState(() {
      _isBackupProcessing = true;
    });

    try {
      final result = await DataBackupService.importBackup(selectedPath);
      await _loadSettings();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '导入成功（备份版本 v${result.sourceSchemaVersion}，当前版本 v${result.appSchemaVersion}）',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败：$e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isBackupProcessing = false;
      });
    }
  }

  Future<void> _clearAllData() async {
    if (_isBackupProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('清空本地数据'),
          content: const Text('该操作会删除当前设备上的全部应用数据，且不可恢复。是否继续？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认删除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isBackupProcessing = true;
    });

    try {
      await DataBackupService.clearAllData();
      await _loadSettings();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已清空本地数据')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('清空失败：$e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isBackupProcessing = false;
      });
    }
  }

  Widget _buildSettingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.schedule),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '每日起始时间',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedTime,
              decoration: const InputDecoration(
                labelText: '选择一天开始的时间',
                border: OutlineInputBorder(),
              ),
              items: _timeOptions
                  .map(
                    (time) => DropdownMenuItem(
                      value: time,
                      child: Text(time),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedTime = value;
                });
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '当前设置：$_selectedTime',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('保存设置'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogicDayPreviewCard() {
    final info = LogicDayService.calculate(
      now: DateTime.now(),
      dayStartTime: _selectedTime,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '逻辑日预览',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text('当前时间：${LogicDayService.formatDateTime(info.now)}'),
            const SizedBox(height: 6),
            Text('当前逻辑日：${LogicDayService.formatDate(info.logicDay)}'),
            const SizedBox(height: 6),
            Text('上一逻辑日：${LogicDayService.formatDate(info.previousLogicDay)}'),
            const SizedBox(height: 6),
            Text('下一逻辑日：${LogicDayService.formatDate(info.nextLogicDay)}'),
            const SizedBox(height: 6),
            Text(
              '下一次翻篇时间：${LogicDayService.formatDateTime(info.nextRollOverTime)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRolloverStatusCard() {
    if (_rolloverResult == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '翻篇状态',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text('当前逻辑日：${_rolloverResult!.currentLogicDay}'),
            const SizedBox(height: 6),
            Text(
              '下一次翻篇：${LogicDayService.formatDateTime(_rolloverResult!.nextRollOverTime)}',
            ),
            const SizedBox(height: 6),
            Text('状态说明：${_rolloverResult!.message}'),
            const SizedBox(height: 6),
            Text(
              '上次处理逻辑日：${_rolloverResult!.previousProcessedLogicDay ?? '无'}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '容量机制',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text('短期任务保底：${_settings.shortTaskBaseCapacity}'),
            const SizedBox(height: 6),
            Text('固定任务保底：${_settings.fixedTaskBaseCapacity}'),
            const SizedBox(height: 6),
            Text('当前短期容量：${_settings.shortTaskCurrentCapacity}'),
            const SizedBox(height: 6),
            Text('当前固定容量：${_settings.fixedTaskCurrentCapacity}'),
            const SizedBox(height: 10),
            const Text('完成率 >= 80%：次日 +1'),
            const SizedBox(height: 6),
            const Text('完成率 < 80%：次日 -1'),
            const SizedBox(height: 6),
            const Text('容量不会低于保底值。'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataBackupCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '数据备份',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            const Text(
              '导出会生成完整 SQLite 备份；导入时会进行版本兼容校验并恢复数据。',
            ),
            if (_isBackupProcessing) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isBackupProcessing ? null : _exportBackup,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('导出备份'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isBackupProcessing ? null : _importBackup,
                    icon: const Icon(Icons.download_for_offline),
                    label: const Text('导入备份'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '危险操作',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            const Text('清空会删除当前设备中的全部应用数据，且不可恢复。'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isBackupProcessing ? null : _clearAllData,
                icon: const Icon(Icons.delete_forever),
                label: const Text('清空本地数据'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplainCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '说明',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            const Text('系统会按这个时间判断新的一天是否开始。'),
            const SizedBox(height: 6),
            const Text('例如设置为 05:00，则每天 05:00 视为进入新的一天。'),
            const SizedBox(height: 6),
            const Text('如果当前时间早于起始时间，系统仍会视为上一逻辑日。'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  _buildSettingCard(),
                  const SizedBox(height: 12),
                  _buildLogicDayPreviewCard(),
                  const SizedBox(height: 12),
                  _buildRolloverStatusCard(),
                  const SizedBox(height: 12),
                  _buildCapacityCard(),
                  const SizedBox(height: 12),
                  _buildDataBackupCard(),
                  const SizedBox(height: 12),
                  _buildExplainCard(),
                  const SizedBox(height: 12),
                  _buildDangerZoneCard(),
                ],
              ),
            ),
    );
  }
}
