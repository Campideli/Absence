// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_schedule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClassScheduleModel _$ClassScheduleModelFromJson(Map<String, dynamic> json) =>
    ClassScheduleModel(
      weekday: (json['weekday'] as num).toInt(),
      startTime: json['startTime'] as String,
    );

Map<String, dynamic> _$ClassScheduleModelToJson(ClassScheduleModel instance) =>
    <String, dynamic>{
      'weekday': instance.weekday,
      'startTime': instance.startTime,
    };
