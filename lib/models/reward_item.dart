class RewardItem {
  final String id;
  final String title;
  final int cost;
  final DateTime createdAt;

  const RewardItem({
    required this.id,
    required this.title,
    required this.cost,
    required this.createdAt,
  });

  RewardItem copyWith({
    String? id,
    String? title,
    int? cost,
    DateTime? createdAt,
  }) {
    return RewardItem(
      id: id ?? this.id,
      title: title ?? this.title,
      cost: cost ?? this.cost,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'cost': cost,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory RewardItem.fromMap(Map<String, dynamic> map) {
    return RewardItem(
      id: map['id'] as String,
      title: map['title'] as String,
      cost: map['cost'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}