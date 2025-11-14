import 'package:json_annotation/json_annotation.dart';

part 'absence_model.g.dart';

@JsonSerializable()
class AbsenceModel {
  const AbsenceModel({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.quantity = 1,
    this.reason,
  });

  factory AbsenceModel.fromJson(Map<String, dynamic> json) => _$AbsenceModelFromJson(json);

  factory AbsenceModel.create({
    required String id,
    required String userId,
    required String subjectId,
    required DateTime date,
    int quantity = 1,
    String? reason,
  }) {
    final now = DateTime.now();
    return AbsenceModel(
      id: id,
      userId: userId,
      subjectId: subjectId,
      date: date,
      quantity: quantity,
      reason: reason,
      createdAt: now,
      updatedAt: now,
    );
  }

  final String id;
  final String userId;
  final String subjectId;
  final DateTime date;
  final int quantity;
  final String? reason;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$AbsenceModelToJson(this);

  AbsenceModel copyWith({
    String? id,
    String? userId,
    String? subjectId,
    DateTime? date,
    int? quantity,
    String? reason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AbsenceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AbsenceModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          subjectId == other.subjectId &&
          date == other.date &&
          reason == other.reason &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      subjectId.hashCode ^
      date.hashCode ^
      reason.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'AbsenceModel(id: $id, userId: $userId, subjectId: $subjectId, '
        'date: $date, reason: $reason, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
