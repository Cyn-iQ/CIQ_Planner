# CIQ Planner (planbook_app)

一个基于 Flutter 的个人效率管理应用，围绕「计划 -> 执行 -> 激励 -> 复盘」构建完整闭环。

项目当前已实现：任务管理、固定计划模板、长期计划、随机轮盘、积分系统、积分商店、每日结算、历史统计、逻辑日翻篇、数据备份与恢复。

## Features

### 1) 任务与计划中心
- 今日任务：支持短期任务 / 固定任务，任务可勾选完成，支持快速新增和删除。
- 固定计划模板：一次配置，每日自动带入（受固定任务容量限制）。
- 长期计划：支持截止日期、推进计数、手动完成、编辑与删除，最多 3 个。

### 2) 随机轮盘（智能降级）
- 日常轮盘：从未完成的短期/固定任务中抽取执行项。
- 长期轮盘：仅在日常任务全部完成后解锁。
- 智能降级逻辑：
  - 剩余任务为 0：展示“今日无任务”状态。
  - 剩余任务为 1：直接展示唯一任务并支持一键完成。
  - 剩余任务 > 1：正常抽取。

### 3) 积分系统与奖励商城
- 积分流水：记录每笔加减分。
- 完成任务/推进长期计划可加分。
- 取消任务完成或手动扣分会减分。
- 兑换奖励：支持自定义商品、积分兑换。
- 安全规则：积分不会低于 0。

### 4) 历史统计与复盘
- 每日结算历史：展示每日完成情况、全勤天数、奖励积分。
- 历史任务：按逻辑日回看任务完成明细。
- 长期计划历史：区分主动完成、压线完成等状态。

### 5) 逻辑日与动态容量机制
- 可配置“每日起始时间”（如 00:00 / 04:00 / 05:00 / 06:00）。
- 翻篇结算后，根据上一逻辑日完成率调整次日容量：
  - 完成率 >= 80%：次日容量 +1
  - 完成率 < 80%：次日容量 -1
  - 容量不低于保底值（短期 3，固定 5）

### 6) 数据备份与恢复
- 本地 SQLite 存储。
- 支持导出完整 SQLite 备份。
- 支持导入备份并做版本兼容校验。

## Tech Stack

- Flutter / Dart
- sqflite
- path / path_provider
- file_picker
- share_plus

## Project Structure

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

## Quick Start

### Prerequisites
- Flutter SDK
- Dart SDK (project constraint: `^3.11.1`)

### Install & Run

```bash
flutter pub get
flutter run
```

### Build

```bash
# Android APK
flutter build apk

# iOS (on macOS)
flutter build ios
```

## Current Behavior Notes

- 容量自动调整逻辑已实现，并在逻辑日翻篇时生效。
- 当前翻篇流程主要由设置页触发（进入设置页会执行一次翻篇检查）。
- 若需要“应用启动即自动翻篇”或“后台定时翻篇”，可在后续版本补充统一入口。

## Roadmap (Suggestion)

- App 启动入口统一触发翻篇检查
- 成就系统（徽章）
- 趋势图表（7/30 日完成率、积分波动）
- 云同步（可选）

## License

暂未添加 License。开源前建议补充 `LICENSE` 文件并明确使用协议。
