enum PointRecordType {
  earn,
  spend,
}

class PointRecord {
  final String id;
  final int delta;
  final PointRecordType type;
  final String source;
  final String remark;
  final DateTime createdAt;

  const PointRecord({
    required this.id,
    required this.delta,
    required this.type,
    required this.source,
    required this.remark,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'delta': delta,
      'type': type.name,
      'source': source,
      'remark': remark,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PointRecord.fromMap(Map<String, dynamic> map) {
    return PointRecord(
      id: map['id'] as String,
      delta: map['delta'] as int,
      type: PointRecordType.values.firstWhere(
        (e) => e.name == map['type'],
      ),
      source: map['source'] as String,
      remark: map['remark'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}