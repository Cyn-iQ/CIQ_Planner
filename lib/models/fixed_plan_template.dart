class FixedPlanTemplate {
  final String id;
  final String title;
  final String description;
  final int points;
  final DateTime createdAt;

  const FixedPlanTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.createdAt,
  });

  FixedPlanTemplate copyWith({
    String? id,
    String? title,
    String? description,
    int? points,
    DateTime? createdAt,
  }) {
    return FixedPlanTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'points': points,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FixedPlanTemplate.fromMap(Map<String, dynamic> map) {
    return FixedPlanTemplate(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      points: map['points'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}