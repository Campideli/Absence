import 'package:api_server/src/utils/date_validator.dart';
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
    // SECURITY: Normalizar todas as datas para UTC (consistência e segurança)
    final now = DateTime.now().toUtc();
    final normalizedDate = DateValidator.normalizeToUtc(date);
    
    return AbsenceModel(
      id: id,
      userId: userId,
      subjectId: subjectId,
      date: normalizedDate,
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
      date: date != null ? DateValidator.normalizeToUtc(date) : this.date,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      createdAt: createdAt != null ? createdAt.toUtc() : this.createdAt,
      updatedAt: updatedAt != null ? updatedAt.toUtc() : this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AbsenceModel(id: $id, subjectId: $subjectId, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AbsenceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
