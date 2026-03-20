# CIQ Planner

一个基于 Flutter 的个人效率管理应用，围绕「计划 -> 执行 -> 激励 -> 复盘」构建闭环。

## 功能概览

### 1) 任务与计划
- 今日任务：支持短期任务、固定任务，支持新增、编辑、删除、完成勾选。
- 固定计划模板：支持新增、编辑、删除；每日按容量自动带入今日任务。
- 长期计划：支持截止日期、推进计数、编辑与删除（最多 3 个）。

### 2) 任务上限规则（已更新）
- 短期任务（今日任务）系统最高上限：`10`
- 固定任务系统最高上限：`15`
- 固定计划模板总数最高上限：`15`

### 3) 轮盘与完成联动
- 日常轮盘：从未完成的短期/固定任务中抽取。
- 长期轮盘：仅在日常任务全部完成后解锁。
- 智能降级规则：
  - 剩余任务为 0：显示“今日无任务”
  - 剩余任务为 1：直接显示唯一任务并支持完成
  - 剩余任务 > 1：正常抽取

### 4) 积分系统
- 完成任务 / 推进长期计划可加分。
- 取消完成或手动扣分会减分。
- 支持奖励商城兑换。
- 积分不会低于 `0`。

### 5) 逻辑日与动态容量（已更新）
- 支持配置每日起始时间（如 `00:00` / `04:00` / `05:00` / `06:00`）。
- 翻篇后按上一逻辑日完成率调整次日容量：
  - 完成率 `>= 80%`：次日 `+1`
  - 完成率 `< 80%`：次日 `-1`
- 当日任务数为 `0`：次日容量保持不变（不增不减）
- 容量不会低于保底值，也不会超过系统上限（短期 `10`、固定 `15`）。

### 6) 历史统计与备份
- 每日结算历史、历史任务、长期计划历史。
- SQLite 本地存储，支持导出/导入备份。

## 技术栈

- Flutter / Dart
- sqflite
- path / path_provider
- file_picker
- share_plus

## 目录结构

```text
lib/
  app.dart
  main.dart
  database/
    app_database.dart
  data/
    *_repository.dart
  models/
    *.dart
  services/
    daily_rollover_service.dart
    data_backup_service.dart
    logic_day_service.dart
  pages/
    home_page.dart
    daily_page.dart
    fixed_plan_page.dart
    long_term_page.dart
    wheel_page.dart
    score_page.dart
    settings_page.dart
    ...others
```

## 快速开始

### 环境要求
- Flutter SDK
- Dart SDK（约束：`^3.11.1`）

### 安装与运行

```bash
flutter pub get
flutter run
```

### 打包

```bash
# Android APK
flutter build apk --release

# iOS (on macOS)
flutter build ios
```
