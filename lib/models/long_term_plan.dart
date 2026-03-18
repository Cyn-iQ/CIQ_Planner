enum LongTermPlanStatus {
  active,
  completed,
  expired,
  pressLineDone,
}

class LongTermPlan {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final int progressCount;
  final DateTime createdAt;
  final LongTermPlanStatus status;

  const LongTermPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.progressCount,
    required this.createdAt,
    required this.status,
  });

  bool get isCompleted => status == LongTermPlanStatus.completed;

  LongTermPlan copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    int? progressCount,
    DateTime? createdAt,
    LongTermPlanStatus? status,
  }) {
    return LongTermPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      progressCount: progressCount ?? this.progressCount,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'progress_count': progressCount,
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
    };
  }

  factory LongTermPlan.fromMap(Map<String, dynamic> map) {
    return LongTermPlan(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      deadline: DateTime.parse(map['deadline'] as String),
      progressCount: map['progress_count'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      status: LongTermPlanStatus.values.firstWhere(
        (e) => e.name == map['status'],
      ),
    );
  }
}