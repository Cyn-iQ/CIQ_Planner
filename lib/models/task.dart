enum TaskType {
  daily,
  longTerm,
  fixed,
}

enum TaskStatus {
  pending,
  completed,
}

class Task {
  final String id;
  final String title;
  final String description;
  final TaskType type;
  final TaskStatus status;
  final int points;
  final int progress;
  final int targetCount;
  final DateTime createdAt;
  final DateTime? deadline;
  final String logicDate;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.points,
    required this.progress,
    required this.targetCount,
    required this.createdAt,
    required this.logicDate,
    this.deadline,
  });

  bool get isCompleted => status == TaskStatus.completed;

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskType? type,
    TaskStatus? status,
    int? points,
    int? progress,
    int? targetCount,
    DateTime? createdAt,
    DateTime? deadline,
    String? logicDate,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      points: points ?? this.points,
      progress: progress ?? this.progress,
      targetCount: targetCount ?? this.targetCount,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      logicDate: logicDate ?? this.logicDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'status': status.name,
      'points': points,
      'progress': progress,
      'target_count': targetCount,
      'created_at': createdAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'logic_date': logicDate,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      type: TaskType.values.firstWhere((e) => e.name == map['type']),
      status: TaskStatus.values.firstWhere((e) => e.name == map['status']),
      points: map['points'] as int,
      progress: map['progress'] as int,
      targetCount: map['target_count'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      deadline: map['deadline'] == null
          ? null
          : DateTime.parse(map['deadline'] as String),
      logicDate: map['logic_date'] as String,
    );
  }
}