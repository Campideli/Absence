// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'absence_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AbsenceModel _$AbsenceModelFromJson(Map<String, dynamic> json) => AbsenceModel(
  id: json['id'] as String,
  userId: json['userId'] as String,
  subjectId: json['subjectId'] as String,
  date: DateTime.parse(json['date'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  quantity: (json['quantity'] as num?)?.toInt() ?? 1,
  reason: json['reason'] as String?,
);

Map<String, dynamic> _$AbsenceModelToJson(AbsenceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'subjectId': instance.subjectId,
      'date': instance.date.toIso8601String(),
      'quantity': instance.quantity,
      'reason': instance.reason,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
