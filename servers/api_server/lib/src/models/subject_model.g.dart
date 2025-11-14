// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubjectModel _$SubjectModelFromJson(Map<String, dynamic> json) => SubjectModel(
  id: json['id'] as String,
  userId: json['userId'] as String,
  name: json['name'] as String,
  maxAbsences: (json['maxAbsences'] as num).toInt(),
  currentAbsences: (json['currentAbsences'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  classSchedules:
      (json['classSchedules'] as List<dynamic>?)
          ?.map((e) => ClassScheduleModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$SubjectModelToJson(SubjectModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'name': instance.name,
      'maxAbsences': instance.maxAbsences,
      'currentAbsences': instance.currentAbsences,
      'classSchedules': instance.classSchedules.map((e) => e.toJson()).toList(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
