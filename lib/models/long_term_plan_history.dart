import 'long_term_plan.dart';

class LongTermPlanHistory {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final int progressCount;
  final DateTime createdAt;
  final DateTime finishedAt;
  final LongTermPlanStatus status;

  const LongTermPlanHistory({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.progressCount,
    required this.createdAt,
    required this.finishedAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'progress_count': progressCount,
      'created_at': createdAt.toIso8601String(),
      'finished_at': finishedAt.toIso8601String(),
      'status': status.name,
    };
  }

  factory LongTermPlanHistory.fromMap(Map<String, dynamic> map) {
    return LongTermPlanHistory(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      deadline: DateTime.parse(map['deadline'] as String),
      progressCount: map['progress_count'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      finishedAt: DateTime.parse(map['finished_at'] as String),
      status: LongTermPlanStatus.values.firstWhere(
        (e) => e.name == map['status'],
      ),
    );
  }

  factory LongTermPlanHistory.fromPlan(
    LongTermPlan plan,
    DateTime finishedAt,
    LongTermPlanStatus status,
  ) {
    return LongTermPlanHistory(
      id: plan.id,
      title: plan.title,
      description: plan.description,
      deadline: plan.deadline,
      progressCount: plan.progressCount,
      createdAt: plan.createdAt,
      finishedAt: finishedAt,
      status: status,
    );
  }
}